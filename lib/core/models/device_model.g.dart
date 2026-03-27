// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceModel _$DeviceModelFromJson(Map<String, dynamic> json) => DeviceModel(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  status: json['status'] as String,
  currentUserName: json['currentUserName'] as String?,
);

Map<String, dynamic> _$DeviceModelToJson(DeviceModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'status': instance.status,
      'currentUserName': instance.currentUserName,
    };
