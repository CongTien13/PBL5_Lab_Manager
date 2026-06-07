# Kiến trúc Hệ thống

## Tổng quan

Hệ thống PBL5 Lab Manager bao gồm ba thành phần chính giao tiếp qua Firebase như kho dữ liệu trung tâm:

1. **Ứng dụng Di động** - Ứng dụng Flutter cho xác thực người dùng, đặt thiết bị và giám sát thiết bị
2. **Máy chủ AI Model** - Mô hình nhận dạng khuôn mặt PyTorch để tạo embedding
3. **Trạm Raspberry Pi** - Bộ điều khiển phần cứng với khả năng quét khuôn mặt

## Kiến trúc Cấp cao

```mermaid
flowchart TB
    subgraph Mobile["Ứng dụng Di động (Flutter)"]
        Auth[Xác thực]
        Booking[Giao diện Đặt]
        Device[Trạng thái Thiết bị]
    end

    subgraph Firebase["Phụ trợ Firebase"]
        AuthService[Xác thực Firebase]
        Firestore[Cơ sở dữ liệu Firestore]
        Storage[Lưu trữ Đám mây]
    end

    subgraph AIBackend["Máy chủ AI Model"]
        Main[main.py]
        UpdateDB[update_db.py]
        Sync[sync_firestore_face_db.py]
    end

    subgraph Raspberry["Trạm Raspberry Pi"]
        Listener[scan_listener.py]
        Hardware[hardware_gpio.py]
        Camera[Camera OpenCV]
    end

    Mobile -->|Email/Mật khẩu| AuthService
    Mobile -->|Đọc/Ghi| Firestore
    Mobile -->|Tải ảnh lên| Storage
    Storage -->|Ảnh khuôn mặt| Firestore

    Firestore -->|Người dùng mới| Main
    Main -->|CSDL Khuôn mặt| Sync
    Sync -->|Tải lên SSH| Raspberry
    Raspberry -->|Yêu cầu quét| Firestore
    Raspberry -->|Điều khiển Relay| Hardware
```

## Sơ đồ Dữ liệu

### Luồng Đăng ký Người dùng

```mermaid
sequenceDiagram
    participant User
    participant Mobile as Ứng dụng Di động
    participant Firebase as Firebase
    participant AI as Máy chủ AI Model
    participant Raspberry as Raspberry Pi

    User->>Mobile: Đăng ký với 5 ảnh khuôn mặt
    Mobile->>Firebase: Tải ảnh lên Storage
    Firebase-->>Mobile: Trả về URL ảnh
    Mobile->>Firebase: Tạo người dùng với faceImageUrls
    Firebase->>AI: Kiểm tra người dùng chờ xử lý
    AI->>Firebase: Tải ảnh khuôn mặt
    AI->>AI: Tạo embedding 128 chiều
    AI->>AI: Xây dựng face_db.npy
    AI->>Raspberry: Tải lên SSH face_db.npy
```

### Luồng Truy cập Thiết bị

```mermaid
sequenceDiagram
    participant User
    participant Mobile as Ứng dụng Di động
    participant Firebase as Firebase
    participant Raspberry as Raspberry Pi

    User->>Mobile: Đặt thiết bị (dev01)
    Mobile->>Firebase: Tạo đặt chỗ
    Firebase-->>Mobile: Đặt chỗ được chấp thuận

    User->>Raspberry: Nhấn nút quét
    Raspberry->>Raspberry: Quét khuôn mặt (8 giây)
    Raspberry->>Raspberry: Đối chiếu với face_db
    Raspberry->>Firebase: Kiểm tra đặt chỗ hợp lệ

    alt Đặt chỗ hợp lệ
        Raspberry->>Raspberry: Bật relay + LED
        Raspberry->>Firebase: Cập nhật trạng thái thiết bị = in_use
    else Không có đặt chỗ
        Raspberry->>Raspberry: Nhấp nháy LED (từ chối)
    end
```

## Kiến trúc Thành phần

### Kiến trúc Ứng dụng Di động

```mermaid
flowchart TB
    subgraph Presentation
        Login[Đăng nhập]
        Register[Đăng ký]
        Home[Trang chủ]
        Lab[Lab/Đặt thiết bị]
        Info[Thông tin/Cài đặt]
    end

    subgraph State["Quản lý Trạng thái (flutter_bloc)"]
        AuthCubit[AuthCubit]
        DeviceCubit[DeviceCubit]
        BookingCubit[BookingCubit]
        AdminBookingCubit[AdminBookingCubit]
    end

    subgraph Data["Lớp Dữ liệu"]
        AuthRepo[Kho lưu trữ Auth]
        HomeRepo[Kho lưu trữ Home]
        LabRepo[Kho lưu trữ Lab]
    end

    subgraph Services
        AuthService[Dịch vụ Xác thực]
        FirestoreService[Dịch vụ Firestore]
    end

    Presentation --> State
    State --> Data
    Data --> Services
    Services --> Firebase
```

### Pipeline Mô hình AI

```mermaid
flowchart LR
    subgraph Input
        Image[URL Ảnh Khuôn mặt]
    end

    subgraph Detection["Phát hiện khuôn mặt MTCNN"]
        Detect[Phát hiện khuôn mặt]
        Crop[Cắt 112x112]
    end

    subgraph Embedding["MobileFaceNet"]
        Forward[Lan truyền xuôi]
        Extract[Trích xuất 128 chiều]
    end

    subgraph Output
        Embed[Embedding Khuôn mặt]
    end

    Image --> Detect
    Detect --> Crop
    Crop --> Forward
    Forward --> Extract
    Extract --> Embed
```

### Máy trạng Thái Raspberry Pi

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Pending: Nhận yêu cầu quét
    Pending --> Scanning: Bắt đầu quét 8 giây
    Scanning --> Success: Nhận dạng + đặt chỗ hợp lệ
    Scanning --> Denied: Không nhận dạng được
    Scanning --> Failed: Không phát hiện khuôn mặt
    Success --> DeviceOn: Relay BẬT
    DeviceOn --> Idle: Kết thúc đặt chỗ
    Denied --> Idle: Nhấp nháy LED
    Failed --> Idle: Nhấp nháy LED
```

## Cấu hình Pin Phần cứng

| Pin GPIO | Chức năng | Thiết bị |
|---------|----------|--------|
| 17 | Đầu vào | Nút Quét |
| 22 | Đầu ra | LED (dev01) |
| 23 | Đầu ra | LED (dev02) |
| 24 | Đầu ra | LED (dev03) |
| 27 | Đầu ra | Relay (dev01) |
| 5 | Đầu ra | Relay (dev02) |
| 6 | Đầu ra | Relay (dev03) |

## Giao tiếp Thành phần

| Từ | Đến | Giao thức | Dữ liệu |
|------|-------|---------|------|
| Ứng dụng Di động | Firebase | REST API | Dữ liệu Người dùng, Đặt chỗ, Thiết bị |
| AI Model | Firebase | REST API | Embedding người dùng |
| AI Model | Raspberry | SFTP (SSH) | face_db.npy |
| Raspberry | Firebase | Firestore SDK | Yêu cầu quét, trạng thái thiết bị |
| Raspberry | Phần cứng | GPIO | Điều khiển Relay, LED |

## Cân nhắc Bảo mật

1. **Dữ liệu Khuôn mặt**: Lưu trữ dưới dạng embedding 128 chiều, không phải ảnh thô
2. **Truy cập SSH**: Raspberry Pi chỉ truy cập được trong mạng cục bộ
3. **Quy tắc Firebase**: Kiểm soát truy cập dựa trên vai trò trong quy tắc bảo mật Firestore
4. **Xác thực Đặt chỗ**: Xác thực dựa trên thời gian ngăn chặn truy cập trái phép