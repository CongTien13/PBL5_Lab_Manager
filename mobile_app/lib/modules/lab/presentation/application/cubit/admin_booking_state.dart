part of 'admin_booking_cubit.dart';

sealed class AdminBookingState extends Equatable {
  const AdminBookingState();
  @override
  List<Object> get props => [];
}

final class AdminBookingInitial extends AdminBookingState {}

final class AdminBookingLoading extends AdminBookingState {}

final class AdminBookingLoaded extends AdminBookingState {
  final List<BookingModel> pendingBookings;
  final List<BookingModel> allBookings;
  const AdminBookingLoaded(this.pendingBookings, this.allBookings);
  @override
  List<Object> get props => [pendingBookings, allBookings];
}

final class AdminBookingError extends AdminBookingState {
  final String message;
  const AdminBookingError(this.message);
}
