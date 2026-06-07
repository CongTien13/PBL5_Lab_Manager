# Hướng dẫn Triển khai

## Tổng quan

Hướng dẫn này bao gồm thiết lập phát triển cục bộ và triển khai sản xuất cho tất cả thành phần của PBL5 Lab Manager.

## Yêu cầu

| Thành phần | Yêu cầu |
|-----------|------------|
| Python | 3.8+ |
| Flutter | 3.0+ |
| Node.js | 16+ |
| Firebase CLI | Mới nhất |
| Raspberry Pi OS | Mới nhất (Raspberry Pi 4) |

## Thiết lập Dự án Firebase

### 1. Tạo Dự án Firebase

1. Truy cập [Firebase Console](https://console.firebase.google.com)
2. Nhấn "Add project"
3. Nhập tên dự án: `pbl5-lab`
4. Bật Google Analytics (tùy chọn)
5. Nhấn "Create project"

### 2. Bật Dịch vụ

Trong Firebase Console:

1. **Authentication**: Build -> Authentication -> Get started -> Enable Email/Password
2. **Firestore**: Build -> Firestore Database -> Create database -> Start in production mode
3. **Storage**: Build -> Storage -> Get started -> Start in production mode

### 3. Tạo Tài khoản Service

1. Project Settings -> Service accounts
2. Nhấn "Generate new private key"
3. Tải xuống `serviceAccountKey.json`
4. Đặt trong:
   - `ai_model/serviceAccountKey.json`
   - `raspberry-sync/serviceAccountKey.json`

### 4. Cấu hình Ứng dụng Firebase

1. Project Overview -> Add app -> Web (</>)
2. Đăng ký ứng dụng
3. Sao chép đối tượng cấu hình Firebase

## Thiết lập AI Model Server

### Phát triển Cục bộ

```bash
# Di chuyển đến thư mục AI model
cd ai_model

# Tạo môi trường ảo
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate  # Windows

# Cài đặt phụ thuộc
pip install -r requirements.txt

# Tải xuống trọng lượng mô hình
# Đặt last_checkpoint.pth trong ai_model/weights/
```

### Phụ thuộc

```
torch
torchvision
facenet-pytorch
mtcnn
opencv-python
numpy
firebase-admin
requests
paramiko
```

### Cấu hình

Chỉnh sửa `ai_model/main.py`:

```python
RASPBERRY_HOST = "172.20.10.2"  # IP Raspberry Pi
RASPBERRY_USER = "pi"
RASPBERRY_PASSWORD = "12345678"
RASPBERRY_DB_PATH = "/home/pi/Desktop/PBL5_HARDWARE/weights/face_db.npy"
```

### Chạy

```bash
# Bắt đầu dịch vụ đồng bộ
python sync_firestore_face_db.py
```

## Thiết lập Ứng dụng Di động

### Yêu cầu

1. Cài đặt Flutter SDK
2. Cài đặt Android Studio / Xcode

### Cấu hình

Cập nhật `mobile_app/lib/firebase_options.dart`:

```dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "YOUR_API_KEY",
      appId: "YOUR_APP_ID",
      messagingSenderId: "YOUR_SENDER_ID",
      projectId: "pbl5-lab",
      storageBucket: "pbl5-lab.appspot.com",
    );
  }
}
```

### Build cho Android

```bash
cd mobile_app

# Lấy phụ thuộc
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

### Build cho iOS

```bash
# Mở iOS simulator
open -a Simulator

# Chạy trên simulator
flutter run
```

### Build cho Web

```bash
flutter build web
```

## Thiết lập Raspberry Pi

### Cài đặt OS

1. Tải Raspberry Pi Imager
2. Chọn Raspberry Pi OS (64-bit)
3. Ghi vào thẻ SD
4. Cấu hình Wi-Fi và SSH

### Thiết lập Ban đầu

```bash
# Cập nhật hệ thống
sudo apt update
sudo apt upgrade

# Bật camera
sudo raspi-config
# Interface Options -> Camera -> Yes
```

### Cài đặt Phụ thuộc

```bash
# Cài đặt phụ thuộc Python
pip3 install -r requirements.txt

# Cài đặt OpenCV
sudo apt install libopencv-dev

# Cài đặt thư viện GPIO
sudo apt install python3-rpi.gpioi
```

### Phụ thuộc

```
torch
opencv-python
numpy
firebase-admin
RPi.GPIO
```

### Cấu hình Tài khoản Service

Đặt `serviceAccountKey.json` trong thư mục dự án.

### Thiết lập Phần cứng

Kết nối các thành phần:
- GPIO 17 -> Nút Quét (với điện trở pull-up)
- GPIO 22 -> LED (dev01) + điện trở 330 ohm
- GPIO 27 -> Relay (dev01) -> Nguồn thiết bị

### Chạy

```bash
# Bắt đầu trình nghe quét
python3 scan_listener.py

# Hoặc như systemd service
sudo systemctl enable pbl5.service
sudo systemctl start pbl5.service
```

## Cấu hình Mạng

### Mạng Lab

Cấu hình router:

| Cài đặt | Giá trị |
|---------|-------|
| Subnet | 172.20.10.0/24 |
| Gateway | 172.20.10.1 |
| DHCP Range | 172.20.10.100 - 172.20.10.200 |

### IP Tĩnh (Raspberry Pi)

Chỉnh sửa `/etc/dhcpcd.conf`:

```conf
interface eth0
static ip_address=172.20.10.2/24
static routers=172.20.10.1
static domain_name_servers=172.20.10.1
```

## Biến Môi trường

### AI Model

```bash
export RASPBERRY_HOST="172.20.10.2"
export RASPBERRY_USER="pi"
export RASPBERRY_PASSWORD="12345678"
```

### Ứng dụng Di động

Cấu hình trong `firebase_options.dart` hoặc file `.env`.

## Bảo mật

### Quy tắc Firestore

Xem [Tài liệu Cơ sở dữ liệu](database.md#security-rules)

### Quy tắc Storage

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /faces/{uid}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

### Bảo mật Mạng

1. Tắt xác thực SSH mật khẩu
2. Chỉ dùng SSH dựa trên key
3. Cấu hình firewall:

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw enable
```

## Giám sát

### Logs

#### Raspberry Pi

```bash
# Xem logs
journalctl -u pbl5 -f

# Hoặc
tail -f /var/log/pbl5.log
```

#### Firebase

Xem trong Firebase Console:
- Firestore -> Logs
- Storage -> Logs
- Authentication -> Logs

### Kiểm tra Sức khỏe

Tạo endpoint kiểm tra sức khỏe:

```python
from flask import Flask

app = Flask(__name__)

@app.route('/health')
def health():
    return {'status': 'ok'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

## Sao lưu

### Export Firestore

```bash
gcloud firestore export gs://pbl5-lab-backup/$(date +%Y%m%d)
```

### Sao lưu Cơ sở dữ liệu Khuôn mặt

```bash
# Trên AI server
cp ai_model/weights/face_db.npy face_db_backup_$(date +%Y%m%d).npy

# Tải lên cloud storage
gsutil cp face_db_backup_*.npy gs://pbl5-lab-backup/
```

## Danh sách Triển khai Sản xuất

- [ ] Tạo dự án Firebase
- [ ] Bật xác thực
- [ ] Tạo cơ sở dữ liệu Firestore
- [ ] Tạo bucket Storage
- [ ] Cấu hình tài khoản service
- [ ] Tải xuống trọng lượng mô hình AI
- [ ] Build ứng dụng di động
- [ ] Cấu hình Raspberry Pi
- [ ] Kết nối phần cứng
- [ ] Cấu hình mạng
- [ ] Áp dụng quy tắc bảo mật
- [ ] Bật giám sát
- [ ] Lên lịch sao lưu

## Xử lý sự cố

Xem [Hướng dẫn Xử lý sự cố](troubleshooting.md)