// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  uid: json['uid'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  role: json['role'] as String,
  faceImageUrls: (json['faceImageUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  num: json['num'] as String,
  birthday: json['birthday'] as String,
  job: json['job'] as String,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'uid': instance.uid,
  'name': instance.name,
  'email': instance.email,
  'role': instance.role,
  'faceImageUrls': instance.faceImageUrls,
  'num': instance.num,
  'birthday': instance.birthday,
  'job': instance.job,
};
