import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/models/device_model.dart';
import '../../../repository/home_repository.dart';

part 'device_state.dart';

class DeviceCubit extends Cubit<DeviceState> {
  final HomeRepository _repository; // Gọi qua Repository
  StreamSubscription? _subscription;

  List<DeviceModel> _cachedDevices = []; // Lưu lại danh sách hiện tại

  DeviceCubit(this._repository) : super(DeviceInitial());

  void watchDevices() {
    _subscription?.cancel();
    _subscription = _repository.watchDevices().listen((devices) {
      _cachedDevices = devices; // Cập nhật bộ nhớ tạm
      emit(DeviceLoaded(devices));
    }, onError: (error) => emit(DeviceError(error.toString())));
  }

  // Admin: Thêm thiết bị
  Future<void> addDevice(DeviceModel device) async {
    // KHÔNG emit(DeviceLoading()) ở đây
    try {
      await _repository.addDevice(device);
      // Chỉ thông báo thành công, UI sẽ tự nhảy do Stream watchDevices đang chạy
      emit(const DeviceActionSuccess("Thêm thiết bị thành công"));
      // Sau khi báo thành công, trả lại ngay trạng thái Loaded với danh sách cũ
      emit(DeviceLoaded(_cachedDevices));
    } catch (e) {
      emit(DeviceError(e.toString()));
      emit(DeviceLoaded(_cachedDevices)); // Trả lại danh sách để hết xoay
    }
  }

  // Admin: Sửa thiết bị
  Future<void> updateDevice(DeviceModel device) async {
    try {
      await _repository.updateDevice(device);
      emit(const DeviceActionSuccess("Cập nhật thành công"));
    } catch (e) {
      emit(DeviceError(e.toString()));
    }
  }

  // Admin: Xóa thiết bị
  Future<void> deleteDevice(String id) async {
    try {
      await _repository.deleteDevice(id);
      emit(const DeviceActionSuccess("Đã xóa thiết bị"));
    } catch (e) {
      emit(DeviceError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
