#!/bin/bash
# TEST CẤP QUYỀN ADMIN, CẤP BẰNG, THU HỒI QUA API (chạy khi mạng đang chạy)
#   bash tools/test-quyen.sh            (chạy tại thư mục dự án)
A=http://localhost:3001; B=http://localhost:3002; C=http://localhost:3003
H='Content-Type: application/json'
ID="VB-T$(date +%s)"
J() { python3 -c "import sys,json;d=json.load(sys.stdin);print($1)"; }
wait_for() { for i in $(seq 1 40); do v=$(eval "$1"); [ "$v" = "$2" ] && return 0; sleep 1; done; return 1; }

echo "== 1. Node 2 (không có khóa Admin) cấp quyền → phải bị từ chối"
KB=$(curl -s $B/issuers | J "d['schools'][1]['publicKey']")
curl -s -X POST $B/issuers -H "$H" -d "{\"publicKey\":\"$KB\",\"name\":\"Dai hoc B\"}"; echo

echo "== 2. Admin (node 1) cấp quyền cho Đại học A"
KA=$(curl -s $A/issuers | J "d['schools'][0]['publicKey']")
HAS=$(curl -s $A/issuers | J "'$KA' in d['issuers']")
[ "$HAS" = "True" ] && echo "(Đại học A đã có quyền từ trước)" || curl -s -X POST $A/issuers -H "$H" -d "{\"publicKey\":\"$KA\",\"name\":\"Dai hoc A\"}"
echo
wait_for "curl -s $A/issuers | python3 -c \"import sys,json;print('$KA' in json.load(sys.stdin)['issuers'])\"" True && echo "→ OK: Đại học A đã có quyền cấp bằng" || echo "→ LỖI: chưa thấy quyền sau 40 giây"

echo "== 3. Đại học A cấp văn bằng $ID"
PDF=$(base64 -w0 web/samples/VB2026-001.pdf)
printf '{"certId":"%s","studentId":"SV001","pdfBase64":"%s"}' "$ID" "$PDF" > /tmp/cap.json
curl -s -X POST $A/certificates -H "$H" -d @/tmp/cap.json; echo
wait_for "curl -s $C/certificates/$ID | python3 -c \"import sys,json;print(json.load(sys.stdin)['status'])\"" valid && echo "→ OK: node C thấy văn bằng 'valid'" || echo "→ LỖI: node C chưa thấy văn bằng"

echo "== 4. Đại học A gửi yêu cầu thu hồi (kèm bằng chứng)"
EV=$(base64 -w0 web/samples/VB2026-002.pdf)
printf '{"reason":"Gian lan thi cu","evidenceBase64":"%s","evidenceName":"bien-ban.pdf"}' "$EV" > /tmp/thuhoi.json
curl -s -X POST $A/certificates/$ID/revoke -H "$H" -d @/tmp/thuhoi.json; echo
wait_for "curl -s $B/revoke-requests | python3 -c \"import sys,json;print(any(r['certId']=='$ID' for r in json.load(sys.stdin)))\"" True && echo "→ OK: node B thấy yêu cầu thu hồi đang chờ" || echo "→ LỖI"

echo "== 5. Đại học B chấp nhận thu hồi"
curl -s -X POST $B/certificates/$ID/approve-revoke -H "$H" -d '{}'; echo
wait_for "curl -s $C/certificates/$ID | python3 -c \"import sys,json;print(json.load(sys.stdin)['status'])\"" revoked && echo "→ OK: văn bằng đã bị thu hồi (revoked) trên node C" || echo "→ LỖI: chưa revoked"

echo "== 6. Xác minh PDF sau khi thu hồi (node backup)"
printf '{"pdfBase64":"%s"}' "$PDF" > /tmp/verify.json
curl -s -X POST http://localhost:3100/verify -H "$H" -d @/tmp/verify.json | python3 -c "import sys,json;d=json.load(sys.stdin);print('status =',d['status'])"
