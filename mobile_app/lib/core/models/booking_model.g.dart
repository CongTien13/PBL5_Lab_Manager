// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingModel _$BookingModelFromJson(Map<String, dynamic> json) => BookingModel(
  id: json['id'] as String?,
  userId: json['userId'] as String,
  deviceId: json['deviceId'] as String,
  deviceName: json['deviceName'] as String,
  startTime: BookingModel._fromTimestamp(json['startTime']),
  endTime: BookingModel._fromTimestamp(json['endTime']),
  status: json['status'] as String,
);

Map<String, dynamic> _$BookingModelToJson(BookingModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'startTime': BookingModel._toTimestamp(instance.startTime),
      'endTime': BookingModel._toTimestamp(instance.endTime),
      'status': instance.status,
    };
