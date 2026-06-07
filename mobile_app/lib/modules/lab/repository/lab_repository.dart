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

  // Admin: Lấy TẤT CẢ yêu cầu đang chờ (one-time)
  Future<List<BookingModel>> getPendingBookings() async {
    final snap = await _service.getCollection('bookings').get();
    return snap.docs
        .map((doc) {
          final data = doc.data();
          final map = Map<String, dynamic>.from(data as Map);
          map['id'] = doc.id;
          return BookingModel.fromJson(map);
        })
        .where((b) => b.status == 'pending')
        .toList();
  }

  // Admin: Theo dõi TẤT CẢ bookings (all statuses)
  Stream<List<BookingModel>> watchAllBookings() {
    return _service
        .getStream(
          'bookings',
          query: (q) => q.orderBy('startTime', descending: true),
        )
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  // Admin: Lấy TẤT CẢ bookings (one-time)
  Future<List<BookingModel>> getAllBookings() async {
    final snap = await _service.getCollection('bookings').get();
    return snap.docs
        .map((doc) {
          final data = doc.data();
          final map = Map<String, dynamic>.from(data as Map);
          map['id'] = doc.id;
          return BookingModel.fromJson(map);
        })
        .toList();
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

  // Kiểm tra xem user đã có booking trùng thời gian cho cùng thiết bị chưa
  Future<bool> hasConflictingBooking({
    required String userId,
    required String deviceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final snap = await _service.getCollection('bookings').get();
    final bookings = snap.docs
        .map((doc) {
          final data = doc.data();
          final map = Map<String, dynamic>.from(data as Map);
          map['id'] = doc.id;
          return BookingModel.fromJson(map);
        })
        .where((b) =>
            b.userId == userId &&
            b.deviceId == deviceId &&
            (b.status == 'pending' || b.status == 'approved'))
        .toList();

    // Kiểm tra xem có thời gian overlap không
    for (final booking in bookings) {
      if (_timesOverlap(
        startTime,
        endTime,
        booking.startTime,
        booking.endTime,
      )) {
        return true;
      }
    }
    return false;
  }

  // Kiểm tra xem có booking nào (của bất kỳ user nào) đã được duyệt trùng thời gian cho thiết bị chưa
  Future<bool> hasApprovedConflict({
    required String deviceId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeBookingId,
  }) async {
    final snap = await _service.getCollection('bookings').get();
    final bookings = snap.docs
        .map((doc) {
          final data = doc.data();
          final map = Map<String, dynamic>.from(data as Map);
          map['id'] = doc.id;
          return BookingModel.fromJson(map);
        })
        .where((b) =>
            b.deviceId == deviceId &&
            b.status == 'approved' &&
            (excludeBookingId == null || b.id != excludeBookingId))
        .toList();

    for (final booking in bookings) {
      if (_timesOverlap(
        startTime,
        endTime,
        booking.startTime,
        booking.endTime,
      )) {
        return true;
      }
    }
    return false;
  }

  bool _timesOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }
}
