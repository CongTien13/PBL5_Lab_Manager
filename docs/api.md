# API Reference

## Overview

The PBL5 Lab Manager system uses Firebase SDKs for client-server communication. This document covers the Firebase API endpoints and their request/response formats.

## Firebase REST API Endpoints

Base URL: `https://firestore.googleapis.com/v1`

### Authentication Endpoints

#### POST /accounts:signInWithPassword

Sign in with email and password.

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

Create a new user account.

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

List documents in a collection.

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

Update a document.

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

## Mobile App API

### Firestore Collections

The mobile app interacts with Firestore through the Flutter SDK. Below are the data operations.

### User Operations

#### Create User

```dart
// Via Firebase Auth + Firestore
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

#### Get User

```dart
final doc = await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .get();

final user = UserModel.fromJson(doc.data());
```

### Device Operations

#### Get All Devices

```dart
final snapshot = await FirebaseFirestore.instance
  .collection('devices')
  .get();

final devices = snapshot.docs
  .map((doc) => DeviceModel.fromJson(doc.data()))
  .toList();
```

#### Watch Devices (Real-time)

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

### Booking Operations

#### Create Booking

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

#### Get User Bookings

```dart
final snapshot = await FirebaseFirestore.instance
  .collection('bookings')
  .where('userId', isEqualTo: user.uid)
  .get();

final bookings = snapshot.docs
  .map((doc) => BookingModel.fromJson(doc.data()))
  .toList();
```

#### Approve Booking (Admin)

```dart
await FirebaseFirestore.instance
  .collection('bookings')
  .doc(bookingId)
  .update({
    'status': 'approved',
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

### Scan Request Operations

#### Create Scan Request

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

#### Update Scan Request

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

## Raspberry Pi API

### Firestore Listener

The Raspberry Pi uses Firestore SDK for real-time updates.

```python
# Listen for scan requests
query = db.collection("scanRequests")\
    .where("deviceId", "==", "dev01")\
    .where("status", "==", "pending")

query.on_snapshot(callback)
```

### Update Device Status

```python
db.collection("devices").document("dev01").update({
    "status": "in_use",
    "currentUserId": user_id,
    "updatedAt": firestore.SERVER_TIMESTAMP
})
```

## Storage API

### Upload Face Image

```dart
// Upload to Firebase Storage
final ref = FirebaseStorage.instance
    .ref()
    .child('faces')
    .child(uid)
    .child('face_$index.jpg');

final uploadTask = ref.putFile(file);
final url = await uploadTask.ref.getDownloadURL();
```

### Storage Rules

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

## Firebase Auth API

### Sign In

```dart
final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

final user = credential.user;
final idToken = await user.getIdToken();
```

### Sign Out

```dart
await FirebaseAuth.instance.signOut();
```

### Get Current User

```dart
final user = FirebaseAuth.instance.currentUser;

if (user != null) {
  final uid = user.uid;
  final email = user.email;
  final idToken = await user.getIdToken();
}
```

## Request/Response Formats

### Standard Response Wrapper

All Firestore responses follow this format:

```json
{
  "success": true,
  "data": { ... },
  "error": null
}
```

### Error Response

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

## Error Codes

| Code | Description |
|------|-------------|
| INVALID_EMAIL | Invalid email format |
| INVALID_PASSWORD | Invalid password |
| USER_NOT_FOUND | User does not exist |
| WRONG_PASSWORD | Incorrect password |
| EMAIL_IN_USE | Email already registered |
| PERMISSION_DENIED | Insufficient permissions |
| NOT_FOUND | Document does not exist |

## Rate Limits

| Operation | Limit |
|-----------|-------|
| Firestore writes | 10,000/minute |
| Firestore reads | 50,000/minute |
| Storage uploads | 1GB/file |
| Auth sign-ups | 100/hour |

## API Keys

Obtain API keys from Firebase Console:
- Firebase Console -> Project Settings -> General
- Firebase Console -> Project Settings -> APIs

### Required APIs

- Firebase Auth API
- Cloud Firestore API
- Cloud Storage API
- Identity Toolkit API