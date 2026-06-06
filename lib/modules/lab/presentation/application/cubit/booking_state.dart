part of 'booking_cubit.dart';

sealed class BookingState extends Equatable {
  const BookingState();
  @override
  List<Object> get props => [];
}

final class BookingInitial extends BookingState {}

final class BookingSubmitting extends BookingState {
  final List<BookingModel> cachedBookings;
  const BookingSubmitting({this.cachedBookings = const []});
  @override
  List<Object> get props => [cachedBookings];
}

final class BookingLoaded extends BookingState {
  final List<BookingModel> myBookings;
  const BookingLoaded(this.myBookings);
  @override
  List<Object> get props => [myBookings];
}

final class BookingSuccess extends BookingState {}

final class BookingError extends BookingState {
  final String message;
  const BookingError(this.message);
  @override
  List<Object> get props => [message];
}
