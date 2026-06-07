part of 'device_cubit.dart';

sealed class DeviceState extends Equatable {
  const DeviceState();

  @override
  List<Object> get props => [];
}

final class DeviceInitial extends DeviceState {}

final class DeviceLoading extends DeviceState {}

final class DeviceLoaded extends DeviceState {
  final List<DeviceModel> devices;
  const DeviceLoaded(this.devices);

  @override
  List<Object> get props => [devices];
}

final class DeviceError extends DeviceState {
  final String message;
  const DeviceError(this.message);

  @override
  List<Object> get props => [message];
}

// Thêm vào file hiện tại của bạn
final class DeviceActionSuccess extends DeviceState {
  final String message;
  const DeviceActionSuccess(this.message);
}
