import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends Equatable {
  final String uid; // ID duy nhất từ Firebase Auth
  final String name;
  final String email;
  final String role; // 'admin' hoặc 'user'
  final String status; // 'pending' (chờ duyệt) hoặc 'approved' (đã duyệt)
  final String faceImageUrl; // Link ảnh trên Firebase Storage
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.faceImageUrl,
    this.createdAt,
  });

  // Chuyển đổi dữ liệu từ Firestore (Map) sang Model
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      status: map['status'] ?? 'pending',
      faceImageUrl: map['faceImageUrl'] ?? '',
      // Xử lý kiểu dữ liệu Timestamp của Firestore
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Chuyển đổi từ Model sang Map để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'faceImageUrl': faceImageUrl,
      'createdAt':
          createdAt ??
          FieldValue.serverTimestamp(), // Tự động lấy thời gian server
    };
  }

  // Phương thức sao chép model với các thay đổi (hữu ích cho Cubit)
  UserModel copyWith({
    String? name,
    String? role,
    String? status,
    String? faceImageUrl,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      faceImageUrl: faceImageUrl ?? this.faceImageUrl,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    name,
    email,
    role,
    status,
    faceImageUrl,
    createdAt,
  ];
}
