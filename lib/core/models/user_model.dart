import 'package:json_annotation/json_annotation.dart';
part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final List<String> faceImageUrls;
  // Các thuộc tính mới
  final String num;
  final String birthday;
  final String job;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.faceImageUrls,
    required this.num,
    required this.birthday,
    required this.job,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      // Thêm ?? '' (giá trị mặc định là chuỗi rỗng) để không bị lỗi Null
      num: json['num'] ?? '',
      birthday: json['birthday'] ?? '',
      job: json['job'] ?? '',
      faceImageUrls: List<String>.from(json['faceImageUrls'] ?? []),
    );
  }
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
