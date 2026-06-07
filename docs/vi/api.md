# Tham chiếu API

## Tổng quan

Hệ thống PBL5 Lab Manager sử dụng Firebase SDKs cho giao tiếp client-server. Tài liệu này bao gồm các endpoint API Firebase và định dạng request/response của chúng.

## Endpoint API REST Firebase

Base URL: `https://firestore.googleapis.com/v1`

### Các Endpoint Xác thực

#### POST /accounts:signInWithPassword

Đăng nhập bằng email và mật khẩu.

**Request:**

```http
POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "returnSecureToken": true
}
```

**Response:**

```json
{
  "localId": "VAwQ9sogfLTbE4fAUkiEbAQAUeh1",
  "email": "user@example.com",
  "displayName": "John Doe",
  "idToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "AIeSyBH...",
  "expiresIn": "3600"
}
```

#### POST /accounts:signUp

Tạo tài khoản người dùng mới.

**Request:**

```http
POST https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={API_KEY}
Content-Type: application/json

{
  "email": "newuser@example.com",
  "password": "password123",
  "returnSecureToken": true
}
```

**Response:**

```json
{
  "localId": "newUserId123",
  "email": "newuser@example.com",
  "idToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "AIeSyBH...",
  "expiresIn": "3600"
}
```

### Firestore REST API

#### GET /projects/{projectId}/databases/{database}/documents/{collection}

Liệt kê documents trong một collection.

**Request:**

```http
GET https://firestore.googleapis.com/v1/projects/{projectId}/databases/(default)/documents/devices
Authorization: Bearer {idToken}
```

**Response:**

```json
{
  "documents": [
    {
      "name": "projects/{projectId}/databases/(default)/documents/devices/dev01",
      "fields": {
        "name": { "stringValue": "Máy in 3D Ender 3" },
        "status": { "stringValue": "ready" }
      },
      "createTime": "2024-01-10T08:00:00Z",
      "updateTime": "2024-01-15T10:00:00Z"
    }
  ]
}
```

#### PATCH /projects/{projectId}/databases/{database}/documents/{collection}/{documentId}

Cập nhật một document.

**Request:**

```http
PATCH https://firestore.googleapis.com/v1/projects/{projectId}/databases/(default)/documents/devices/dev01
Authorization: Bearer {idToken}
Content-Type: application/json

{
  "fields": {
    "status": { "stringValue": "in_use" },
    "currentUserId": { "stringValue": "VAwQ9sogfLTbE4fAUkiEbAQAUeh1" }
  }
}
```

## API Ứng dụng Di động

### Firestore Collections

Ứng dụng di động tương tác với Firestore thông qua Flutter SDK. Dưới đây là các hoạt động dữ liệu.

### Hoạt động Người dùng

#### Tạo Người dùng

```dart
// Qua Firebase Auth + Firestore
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

await FirebaseFirestore.instance
  .collection('users')
  .doc(user.uid)
  .set({
    'name': name,
    'email': email,
    'role': 'user',
    'faceImageUrls': [],
    'embeddingStatus': 'pending',
  });
```

#### Lấy Người dùng

```dart
final doc = await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .get();

final user = UserModel.fromJson(doc.data());
```

### Hoạt động Thiết bị

#### Lấy Tất cả Thiết bị

```dart
final snapshot = await FirebaseFirestore.instance
  .collection('devices')
  .get();

final devices = snapshot.docs
  .map((doc) => DeviceModel.fromJson(doc.data()))
  .toList();
```

#### Theo dõi Thiết bị (Thời gian thực)

```dart
FirebaseFirestore.instance
  .collection('devices')
  .snapshots()
  .listen((snapshot) {
    final devices = snapshot.docs
      .map((doc) => DeviceModel.fromJson(doc.data()))
      .toList();
  });
```

### Hoạt động Đặt chỗ

#### Tạo Đặt chỗ

```dart
final booking = await FirebaseFirestore.instance
  .collection('bookings')
  .add({
    'userId': user.uid,
    'userName': user.name,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'startTime': startTime,
    'endTime': endTime,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

#### Lấy Đặt chỗ Người dùng

```dart
final snapshot = await FirebaseFirestore.instance
  .collection('bookings')
  .where('userId', isEqualTo: user.uid)
  .get();

final bookings = snapshot.docs
  .map((doc) => BookingModel.fromJson(doc.data()))
  .toList();
```

#### Phê duyệt Đặt chỗ (Quản trị)

```dart
await FirebaseFirestore.instance
  .collection('bookings')
  .doc(bookingId)
  .update({
    'status': 'approved',
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

### Hoạt động Yêu cầu Quét

#### Tạo Yêu cầu Quét

```dart
await FirebaseFirestore.instance
  .collection('scanRequests')
  .add({
    'userId': user.uid,
    'deviceId': deviceId,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

#### Cập nhật Yêu cầu Quét

```dart
await FirebaseFirestore.instance
  .collection('scanRequests')
  .doc(requestId)
  .update({
    'status': 'success',
    'recognizedUserId': recognizedUserId,
    'score': score,
    'bookingId': bookingId,
    'message': 'Xác thực thành công',
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

## API Raspberry Pi

### Trình nghe Firestore

Raspberry Pi sử dụng Firestore SDK cho cập nhật thời gian thực.

```python
# Lắng nghe yêu cầu quét
query = db.collection("scanRequests")\
    .where("deviceId", "==", "dev01")\
    .where("status", "==", "pending")

query.on_snapshot(callback)
```

### Cập nhật Trạng thái Thiết bị

```python
db.collection("devices").document("dev01").update({
    "status": "in_use",
    "currentUserId": user_id,
    "updatedAt": firestore.SERVER_TIMESTAMP
})
```

## API Storage

### Tải lên Ảnh Khuôn mặt

```dart
// Tải lên Firebase Storage
final ref = FirebaseStorage.instance
    .ref()
    .child('faces')
    .child(uid)
    .child('face_$index.jpg');

final uploadTask = ref.putFile(file);
final url = await uploadTask.ref.getDownloadURL();
```

### Quy tắc Storage

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /faces/{uid}/{faceId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## API Firebase Auth

### Đăng nhập

```dart
final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

final user = credential.user;
final idToken = await user.getIdToken();
```

### Đăng xuất

```dart
await FirebaseAuth.instance.signOut();
```

### Lấy Người dùng Hiện tại

```dart
final user = FirebaseAuth.instance.currentUser;

if (user != null) {
  final uid = user.uid;
  final email = user.email;
  final idToken = await user.getIdToken();
}
```

## Định dạng Request/Response

### Wrapper Response Chuẩn

Tất cả response Firestore tuân theo định dạng này:

```json
{
  "success": true,
  "data": { ... },
  "error": null
}
```

### Response Lỗi

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "NOT_FOUND",
    "message": "Document not found"
  }
}
```

## Mã Lỗi

| Mã | Mô tả |
|------|-------------|
| INVALID_EMAIL | Định dạng email không hợp lệ |
| INVALID_PASSWORD | Mật khẩu không hợp lệ |
| USER_NOT_FOUND | Người dùng không tồn tại |
| WRONG_PASSWORD | Mật khẩu sai |
| EMAIL_IN_USE | Email đã được đăng ký |
| PERMISSION_DENIED | Quyền không đủ |
| NOT_FOUND | Document không tồn tại |

## Giới hạn Tốc độ

| Hoạt động | Giới hạn |
|-----------|-------|
| Ghi Firestore | 10,000/phút |
| Đọc Firestore | 50,000/phút |
| Tải lên Storage | 1GB/file |
| Đăng ký Auth | 100/giờ |

## Khóa API

Lấy khóa API từ Firebase Console:
- Firebase Console -> Project Settings -> General
- Firebase Console -> Project Settings -> APIs

### API Yêu cầu

- Firebase Auth API
- Cloud Firestore API
- Cloud Storage API
- Identity Toolkit API