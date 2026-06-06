import 'package:json_annotation/json_annotation.dart';
part 'device_model.g.dart';

@JsonSerializable()
class DeviceModel {
  @JsonKey(includeToJson: false)
  final String id;
  final String name;
  final String description;
  final String status; // 'ready' (sẵn sàng), 'busy' (đang dùng), 'off' (tắt)
  final String? currentUserName; // Tên người đang dùng (nếu có)

  DeviceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.currentUserName,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) =>
      _$DeviceModelFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceModelToJson(this);
}
