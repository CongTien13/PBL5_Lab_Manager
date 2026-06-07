# Hướng dẫn Xử lý Sự cố

## Tổng quan

Hướng dẫn này bao gồm các sự cố phổ biến và giải pháp của chúng cho hệ thống PBL5 Lab Manager.

## Sự cố Ứng dụng Di động

### Lỗi Xác thực

#### "Không tìm thấy người dùng với email này"

**Nguyên nhân**: Tài khoản người dùng không được tạo trong Firestore.

**Giải pháp**:
1. Kiểm tra Firebase Authentication Console
2. Xác minh người dùng được tạo trong quá trình đăng ký
3. Kiểm tra collection `users` trong Firestore

#### "Sai mật khẩu"

**Nguyên nhân**: Thông tin xác thực không hợp lệ.

**Giải pháp**:
1. Đặt lại mật khẩu trong Firebase Auth
2. Đăng ký lại nếu tài khoản bị hỏng

### Lỗi Tải Thiết bị

#### "Không tải được thiết bị"

**Nguyên nhân**: Vấn đề kết nối Firestore hoặc lỗi mạng.

**Giải pháp**:
```dart
// Kiểm tra kết nối mạng
final connectivity = await FirebaseFirestore.instance.settings;
// Đảm bảo persistence được bật
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
);
```

#### "Trạng thái thiết bị không cập nhật"

**Nguyên nhân**: Trình nghe thời gian thực không hoạt động.

**Giải pháp**:
```dart
// Đăng ký lại luồng thiết bị
context.read<DeviceCubit>().watchDevices();
```

### Lỗi Đặt chỗ

#### "Xung đột thời gian đặt chỗ"

**Nguyên nhân**: Có đặt chỗ khác vào cùng thời gian.

**Giải pháp**: Chọn khung thời gian khác.

#### "Không thể tạo đặt chỗ"

**Nguyên nhân**: Thiết bị không có sẵn hoặc chưa được phê duyệt.

**Giải pháp**:
1. Kiểm tra trạng thái thiết bị trong Firestore
2. Liên hệ quản trị viên để phê duyệt đặt chỗ

## Sự cố AI Model

### Lỗi Phát hiện Khuôn mặt

#### "Không phát hiện khuôn mặt"

**Nguyên nhân**: Khuôn mặt không căn chỉnh hoặc ánh sáng kém.

**Giải pháp**:
1. Đảm bảo khuôn mặt ở giữa
2. Cải thiện ánh sáng
3. Bỏ phụ kiện (kính, mũ)
4. Kiểm tra độ phân giải camera

#### "Phát hiện nhiều khuôn mặt"

**Nguyên nhân**: Nhiều người trong khung hình.

**Giải pháp**: Đảm bảo chỉ có một người trong khung hình camera.

### Lỗi Embedding

#### "Embedding thất bại"

**Nguyên nhân**: Không phát hiện khuôn mặt hoặc lỗi mô hình.

**Giải pháp**:
```bash
# Kiểm tra face_db.npy
python -c "import numpy as np; db = np.load('weights/face_db.npy', allow_pickle=True).item(); print(list(db.keys()))"
```

#### "embeddingStatus: failed"

**Nguyên nhân**: Ảnh khuôn mặt không xử lý được.

**Giải pháp**:
1. Tải lên ảnh khuôn mặt mới
2. Đảm bảo ảnh rõ và ánh sáng tốt
3. Thử các góc khác nhau

### Lỗi Tải lên SSH

#### "Kết nối bị từ chối"

**Nguyên nhân**: Không thể truy cập Raspberry Pi.

**Giải pháp**:
```bash
# Kiểm tra kết nối SSH
ssh pi@172.20.10.2

# Xác minh IP
ping 172.20.10.2
```

#### "Xác thực thất bại"

**Nguyên nhân**: Thông tin SSH không đúng.

**Giải pháp**:
```python
# Cập nhật thông tin trong main.py
RASPBERRY_PASSWORD = "mật_khẩu_đúng"
```

## Sự cố Raspberry Pi

### Lỗi Phần cứng

#### "Không mở được camera"

**Nguyên nhân**: Camera không phát hiện hoặc đang được sử dụng.

**Giải pháp**:
```bash
# Kiểm tra camera
ls /dev/video0

# Giải phóng camera
sudo rmmod uvcvideo
sudo modprobe uvcvideo
```

#### "GPIO không hoạt động"

**Nguyên nhân**: Không chạy với quyền root hoặc lỗi GPIO.

**Giải pháp**:
```bash
# Chạy với sudo
sudo python3 scan_listener.py

# Kiểm tra quyền GPIO
sudo usermod -a -G gpio pi
```

### Lỗi Nhận dạng

#### "Luôn là người dùng Unknown"

**Nguyên nhân**:
1. Cơ sở dữ liệu khuôn mặt không tải
2. Ngưỡng sai
3. Chất lượng chụp khuôn mặt kém

**Giải pháp**:
```bash
# Kiểm tra face_db.npy tồn tại
ls -la weights/face_db.npy

# Tăng ngưỡng trong main.py
THRESHOLD = 0.1  # Tăng ngưỡng
```

#### "Điểm nhận dạng thấp"

**Nguyên nhân**: Chất lượng chụp khuôn mặt.

**Giải pháp**:
1. Cải thiện ánh sáng
2. Điều chỉnh vị trí camera
3. Tăng thời gian quét
4. Đăng ký lại người dùng với nhiều ảnh hơn

### Lỗi Kết nối

#### "Kết nối Firebase thất bại"

**Nguyên nhân**: Vấn đề mạng hoặc thông tin xác thực.

**Giải pháp**:
```bash
# Kiểm tra kết nối Firebase
python3 -c "import firebase_admin; print('OK')"

# Kiểm tra tài khoản service
cat serviceAccountKey.json | python3 -m json.tool
```

#### "Trình nghe Firestore không hoạt động"

**Nguyên nhân**: Lỗi query hoặc mạng.

**Giải pháp**:
```python
# Thêm xử lý lỗi
def on_snapshot(col_snapshot, changes, read_time):
    try:
        for change in changes:
            # xử lý change
    except Exception as e:
        print(f"Lỗi: {e}")
```

## Sự cố Cơ sở Dữ liệu

### Lỗi Firestore

#### "PERMISSION_DENIED"

**Nguyên nhân**: Quy tắc bảo mật chặn truy cập.

**Giải pháp**:
1. Kiểm tra quy tắc bảo mật Firestore
2. Xác minh xác thực người dùng
3. Kiểm tra quyền document

#### "NOT_FOUND"

**Nguyên nhân**: Document không tồn tại.

**Giải pháp**:
```dart
// Kiểm tra document tồn tại
final doc = await FirebaseFirestore.instance
    .collection('devices')
    .doc('dev01')
    .get();

if (!doc.exists) {
  // Tạo document
}
```

### Không nhất quán Dữ liệu

#### "Trạng thái thiết bị không khớp"

**Nguyên nhân**: Race condition hoặc dữ liệu cũ.

**Giải pháp**:
```dart
// Buộc làm mới
await FirebaseFirestore.instance
    .collection('devices')
    .doc(deviceId)
    .update({'updatedAt': FieldValue.serverTimestamp()});
```

## Sự cố Mạng

### Vấn đề Kết nối

#### "Hết thời gian kết nối"

**Nguyên nhân**: Mạng không thể truy cập.

**Giải pháp**:
```bash
# Kiểm tra mạng
ping 172.20.10.2
ping google.com

# Kiểm tra firewall
sudo ufw status
```

#### "Kết nối SSH chậm"

**Nguyên nhân**: Phân giải DNS.

**Giải pháp**:
```bash
# Chỉnh sửa /etc/ssh/sshd_config
UseDNS no

# Khởi động lại SSH
sudo systemctl restart ssh
```

## Sự cố Hiệu suất

### Phản hồi Chậm

#### "Ứng dụng di động chậm"

**Nguyên nhân**: Quá nhiều lần đọc Firestore.

**Giải pháp**:
1. Triển khai phân trang
2. Sử dụng bộ nhớ cache
3. Tối ưu hóa queries

#### "Nhận dạng khuôn mặt chậm"

**Nguyên nhân**: Suy luận dựa trên CPU.

**Giải pháp**:
1. Sử dụng GPU nếu có
2. Giảm thời gian quét
3. Tối ưu hóa mô hình

### Sử dụng Bộ nhớ Cao

#### "Hết bộ nhớ"

**Nguyên nh��n**: Cơ sở dữ liệu khuôn mặt lớn.

**Giải pháp**:
1. Giảm lưu trữ embedding
2. Dọn dẹp file tạm
3. Khởi động lại dịch vụ

## Logging

### Bật Logging Gỡ lỗi

#### Ứng dụng Di động

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

#### Raspberry Pi

Thêm vào `scan_listener.py`:

```python
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s %(levelname)s %(message)s',
    handlers=[
        logging.FileHandler('/var/log/pbl5.log'),
        logging.StreamHandler()
    ]
)
```

## Lệnh Chẩn đoán

### Kiểm tra Trạng thái Hệ thống

```bash
# Kiểm tra dịch vụ AI model
python3 -c "import torch; print('PyTorch:', torch.__version__)"

# Kiểm tra kết nối Firebase
python3 -c "import firebase_admin; print('Firebase OK')"

# Kiểm tra cơ sở dữ liệu khuôn mặt
python3 -c "import numpy as np; db = np.load('weights/face_db.npy', allow_pickle=True).item(); print('Users:', len(db))"
```

### Kiểm tra Mạng

```bash
# Kiểm tra kết nối
ping -c 4 google.com

# Kiểm tra Raspberry Pi
ping -c 4 172.20.10.2

# Kiểm tra cổng
nmap -p 22 172.20.10.2
```

### Kiểm tra Firebase

```bash
# Kiểm tra Firebase CLI
firebase projects:list

# Kiểm tra indexes Firestore
firebase firestore:indexes
```

## Thông báo Lỗi Phổ biến

| Lỗi | Nguyên nhân | Giải pháp |
|-------|-------|----------|
| Mạng không thể truy cập | Không có internet | Kiểm tra mạng |
| Quyền bị từ chối | Lỗi xác thực | Xác thực lại |
| Document không tìm thấy | Thiếu dữ liệu | Tạo document |
| Email không hợp lệ | Lỗi định dạng | Kiểm tra định dạng email |
| Mật khẩu yếu | Bảo mật | Sử dụng mật khẩu mạnh hơn |
| Thiết bị đang sử dụng | Xung đột | Chờ hoặc hủy đặt chỗ |

## Nhận Trợ giúp

### Logs Thu thập

1. Logs ứng dụng di động (adb logcat)
2. Logs Raspberry Pi (journalctl)
3. Logs Firebase console
4. Chẩn đoán mạng

### Báo cáo Sự cố

Bao gồm:
1. Thông báo lỗi/ID
2. Các bước tái tạo
3. Hành vi mong đợi
4. Hành vi thực tế
5. Logs
6. Chi tiết môi trường

## Phòng ngừa

### Thực hành Tốt

1. **Sao lưu Thường xuyên**: Lên lịch sao lưu tự động
2. **Theo dõi Logs**: Kiểm tra logs hàng ngày
3. **Cập nhật Phụ thuộc**: Giữ các gói cập nhật
4. **Kiểm tra Thường xuyên**: Chạy tích hợp tests
5. **Tài liệu Thay đổi**: Theo dõi thay đổi cấu hình

### Thiết lập Giám sát

Tạo script kiểm tra sức khỏe:

```python
#!/usr/bin/env python3
import firebase_admin
from firebase_admin import credentials, firestore

def health_check():
    try:
        db = firestore.client()
        doc = db.collection('devices').document('dev01').get()
        return doc.exists
    except Exception as e:
        print(f"Kiểm tra sức khỏe thất bại: {e}")
        return False

if __name__ == '__main__':
    print("OK" if health_check() else "FAIL")
```