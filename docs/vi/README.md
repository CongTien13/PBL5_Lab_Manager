# PBL5 Lab Manager

Hệ thống quản lý thiết bị phòng thực hành với xác thực nhận dạng khuôn mặt cho môi trường phòng lab đại học.

## Tổng quan

Hệ thống PBL5 Lab Manager cung cấp kiểm soát truy cập tự động cho thiết bị phòng thực hành bằng xác thực nhận dạng khuôn mặt. Người dùng có thể đặt thiết bị phòng lab thông qua ứng dụng di động, và khuôn mặt được xác minh tại trạm phần cứng do Raspberry Pi điều khiển trước khi kích hoạt thiết bị.

## Tính năng chính

- **Xác thực nhận dạng khuôn mặt**: Nhúng 128 chiều dựa trên MobileFaceNet để xác minh người dùng
- **Hệ thống đặt thiết bị**: Ứng dụng di động để đặt trước thiết bị phòng lab (máy in 3D, kính hiển vi, trạm hàn)
- **Điều khiển phần cứng thời gian thực**: Raspberry Pi điều khiển relay và LED dựa trên trạng thái đặt
- **Truy cập dựa trên vai trò**: Giao diện riêng cho quản trị viên và người dùng
- **Phụ trợ Firebase**: Xác thực, Cơ sở dữ liệu Firestore và Cloud Storage

## Công nghệ sử dụng

| Thành phần | Công nghệ |
|-----------|-----------|
| Ứng dụng di động | Flutter với flutter_bloc |
| Mô hình AI | PyTorch, MobileFaceNet, MTCNN |
| Phần cứng | Raspberry Pi 4, Python, OpenCV |
| Phụ trợ | Firebase (Auth, Firestore, Storage) |
| Cơ sở dữ liệu | Cloud Firestore |

## Cấu trúc dự án

```
PBL5_Lab_Manager/
├── ai_model/           # Mô hình nhận dạng khuôn mặt & huấn luyện
│   ├── models/        # MobileFaceNet, FaceModel
│   ├── services/      # FaceDetector, FaceRecognition
│   ├── main.py       # Script suy luận
│   ├── update_db.py   # Trình tạo cơ sở dữ liệu khuôn mặt
│   └── sync_firestore_face_db.py  # Đồng bộ Firebase
├── mobile_app/         # Ứng dụng di động Flutter
│   └── lib/
│       ├── core/     # Models, services, theme
│       └── modules/  # Auth, home, lab, info
├── raspberry-sync/   # Điều khiển phần cứng Raspberry Pi
│   ├── main.py       # Quét khuôn mặt
│   ├── scan_listener.py  # Trình nghe Firestore
│   ├── hardware_gpio.py # Điều khiển GPIO
│   └── firebase_service.py # Hoạt động Firebase
└── docs/            # Tài liệu
```

## Thiết bị được hỗ trợ

| ID thiết bị | Tên | Vị trí |
|------------|------|---------|
| dev01 | Máy in 3D Ender 3 | Bàn lab 1 |
| dev02 | Kính hiển vi | Bàn lab 2 |
| dev03 | Trạm hàn | Bàn lab 3 |

## Bắt đầu nhanh

### Yêu cầu

- Python 3.8+
- Flutter 3.0+
- Dự án Firebase
- Raspberry Pi 4 có camera

### Thiết lập AI Model

```bash
cd ai_model
pip install -r requirements.txt
```

### Thiết lập Ứng dụng Di động

```bash
cd mobile_app
flutter pub get
flutter run
```

### Thiết lập Raspberry Pi

```bash
cd raspberry-sync
pip install -r requirements.txt
python main.py
```

## Tài liệu

- [Kiến trúc hệ thống](system-architecture.md)
- [Tài liệu AI Model](ai-model.md)
- [Tài liệu Ứng dụng Di động](mobile-app.md)
- [Tài liệu Raspberry Sync](raspberry-sync.md)
- [Lược đồ Cơ sở dữ liệu](database.md)
- [Tham chiếu API](api.md)
- [Hướng dẫn Triển khai](deployment.md)
- [Xử lý sự cố](troubleshooting.md)

## Giấy phép

Dự án này cho mục đích giáo dục như một phần của khóa học PBL5.