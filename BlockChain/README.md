# Xác thực văn bằng trên Blockchain

3 node trường (PoA luân phiên) + 1 node backup. Không cần `npm install`, chỉ cần Node.js 22 trở lên.

## Chạy trên laptop (PowerShell, tại thư mục dự án)

    node tools/setup.js          # sinh khóa, genesis, data/, web/config.js (chạy lại là xóa dữ liệu cũ)
    node tools/make-pdf.js       # tạo PDF mẫu trong web/samples/
    node tools/start-local.js    # chạy 4 node, để nguyên cửa sổ này (Ctrl+C để tắt)

Mở http://localhost:3001 rồi chọn vai trò: Bộ GD&ĐT, Trường, Sinh viên, Nhà tuyển dụng, Block Explorer.

Kiểm tra tự động (cửa sổ PowerShell thứ hai, khi mạng đang chạy):

    node tools/check.js          # 6 kịch bản demo qua API, phải ra 7/7 đạt
    node --test server/          # 24 bài kiểm thử lõi blockchain

## Đặt node backup trên VPS thật (Ubuntu)

Trên máy có code, thay `IP_VPS` bằng IP của VPS:

    node tools/setup.js --backup http://IP_VPS:3100
    node tools/make-pdf.js

Trên VPS:

    sudo adduser --system --group vbbackup
    sudo apt-get install -y nodejs           # cần Node.js 22 (dùng NodeSource nếu bản mặc định cũ hơn)
    sudo mkdir -p /opt/vb-backup/data/node
    # chép server/, web/ vào /opt/vb-backup/ và data/backup/config.json vào /opt/vb-backup/data/node/config.json
    sudo chown -R vbbackup /opt/vb-backup
    sudo ufw allow 3100/tcp
    sudo cp deploy/vb-backup.service /etc/systemd/system/
    sudo systemctl enable --now vb-backup
    journalctl -u vb-backup -f

Chưa chạy thử trên VPS thật. `data/` chứa khóa riêng: không đưa lên GitHub (đã có trong `.gitignore`).
