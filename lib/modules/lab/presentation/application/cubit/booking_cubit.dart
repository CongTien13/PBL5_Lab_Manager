import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/models/booking_model.dart';
import '../../../repository/lab_repository.dart';

part 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final LabRepository _repository; // Gọi qua Repository
  StreamSubscription? _subscription;
  List<BookingModel> _lastBookings = [];

  BookingCubit(this._repository) : super(BookingInitial());

  Future<void> submitBooking(BookingModel booking) async {
    emit(BookingSubmitting(cachedBookings: _lastBookings));
    try {
      await _repository.createBooking(booking);
      emit(BookingSuccess());
      emit(BookingLoaded(_lastBookings));
    } catch (e) {
      emit(BookingError(e.toString()));
      emit(BookingLoaded(_lastBookings));
    }
  }

  void watchMyBookings(String userId) {
    _subscription?.cancel();
    _subscription = _repository.watchMyBookings(userId).listen((bookings) {
      _lastBookings = bookings;
      emit(BookingLoaded(bookings));
    }, onError: (error) => emit(BookingError(error.toString())));
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _repository.cancelBooking(bookingId);
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> stopUsingDevice(String deviceId, String bookingId) async {
    try {
      await _repository.updateDeviceStatus(deviceId, 'ready', null);
      await _repository.updateBookingStatus(bookingId, 'finished');
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
