import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/models/booking_model.dart';
import '../../../repository/lab_repository.dart';

part 'admin_booking_state.dart';

class AdminBookingCubit extends Cubit<AdminBookingState> {
  final LabRepository _repository;
  StreamSubscription? _subscription;

  AdminBookingCubit(this._repository) : super(AdminBookingLoaded([], []));

  void watchPendingBookings() {
    emit(AdminBookingLoaded([], []));
    _subscription?.cancel();
    _subscription = _repository.watchAllPendingBookings().listen(
      (bookings) async {
        final all = await _repository.getAllBookings();
        emit(AdminBookingLoaded(bookings, all));
      },
      onError: (error) => emit(AdminBookingError(error.toString())),
    );
  }

  void watchAllBookings() {
    emit(AdminBookingLoaded([], []));
    _subscription?.cancel();
    _subscription = _repository.watchAllBookings().listen(
      (bookings) async {
        final pending = await _repository.getPendingBookings();
        emit(AdminBookingLoaded(pending, bookings));
      },
      onError: (error) => emit(AdminBookingError(error.toString())),
    );
  }

  Future<void> processBooking(String id, String status) async {
    try {
      await _repository.updateBookingStatus(id, status);
    } catch (e) {
      emit(AdminBookingError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
