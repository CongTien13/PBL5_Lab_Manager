import '../../../core/services/firestore_service.dart';
import '../../../core/models/device_model.dart';

class HomeRepository {
  final FirestoreService _service;
  HomeRepository(this._service);

  // Xem realtime (đã có)
  Stream<List<DeviceModel>> watchDevices() {
    return _service
        .getStream('devices')
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DeviceModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // Admin: Thêm thiết bị mới
  // lib/modules/home/repository/home_repository.dart

  Future<void> addDevice(DeviceModel device) async {
    // Chuyển model thành Map
    final Map<String, dynamic> data = device.toJson();

    // XÓA TRƯỜNG ID trước khi gửi lên Firestore
    // Vì chúng ta muốn dùng ID tự động của Document chứ không lưu field id bên trong
    data.remove('id');

    await _service.add('devices', data);
  }

  // Admin: Cập nhật thông tin thiết bị
  Future<void> updateDevice(DeviceModel device) {
    return _service.update('devices', device.id, device.toJson());
  }

  // Admin: Xóa thiết bị
  Future<void> deleteDevice(String id) {
    return _service.delete('devices', id);
  }
}
