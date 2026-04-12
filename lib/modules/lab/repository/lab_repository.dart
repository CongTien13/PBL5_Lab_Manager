import '../../../core/services/firestore_service.dart';
import '../../../core/models/booking_model.dart';

class LabRepository {
  final FirestoreService _service;
  LabRepository(this._service);

  // Gửi đăng ký
  Future<void> createBooking(BookingModel booking) {
    return _service.add('bookings', booking.toJson());
  }

  // Theo dõi lịch của User
  Stream<List<BookingModel>> watchMyBookings(String userId) {
    return _service
        .getStream(
          'bookings',
          query: (q) => q
              .where('userId', isEqualTo: userId)
              .orderBy('startTime', descending: true),
        )
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  // Hủy lịch
  Future<void> cancelBooking(String id) => _service.delete('bookings', id);

  

  Future<void> updateDeviceStatus(String devId, String status, String? user) =>
      _service.update('devices', devId, {
        'status': status,
        'currentUserName': user,
      });

  // Admin: Theo dõi TẤT CẢ yêu cầu đang chờ duyệt (Real-time)
  Stream<List<BookingModel>> watchAllPendingBookings() {
    return _service
        .getStream(
          'bookings',
          query: (q) => q
              .where('status', isEqualTo: 'pending')
              .orderBy('startTime', descending: false),
        )
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  // Admin: Duyệt hoặc Từ chối yêu cầu
  Future<void> updateBookingStatus(String bookingId, String newStatus) {
    return _service.update('bookings', bookingId, {'status': newStatus});
  }

  // Lấy lịch sử đặt lịch theo thiết bị
  Stream<List<BookingModel>> watchBookingsByDevice(String deviceId) {
    return _service
        .getStream(
          'bookings',
          query: (q) => q.where('deviceId', isEqualTo: deviceId),
        )
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }
}
