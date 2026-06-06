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
  const AdminBookingLoaded(this.pendingBookings);
  @override
  List<Object> get props => [pendingBookings];
}

final class AdminBookingError extends AdminBookingState {
  final String message;
  const AdminBookingError(this.message);
}
