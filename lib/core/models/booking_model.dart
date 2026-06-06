import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
part 'booking_model.g.dart';

@JsonSerializable()
class BookingModel {
  @JsonKey(includeToJson: false)
  final String? id;
  final String userId;
  final String deviceId;
  final String deviceName;
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  final DateTime startTime;
  @JsonKey(fromJson: _fromTimestamp, toJson: _toTimestamp)
  final DateTime endTime;
  final String status; // 'pending', 'approved', 'rejected'

  BookingModel({
    this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  static DateTime _fromTimestamp(dynamic t) => (t as Timestamp).toDate();
  static dynamic _toTimestamp(DateTime d) => Timestamp.fromDate(d);

  factory BookingModel.fromJson(Map<String, dynamic> json) =>
      _$BookingModelFromJson(json);
  Map<String, dynamic> toJson() => _$BookingModelToJson(this);
}
