import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../application/cubit/admin_booking_cubit.dart';

class AdminLabPage extends StatefulWidget {
  const AdminLabPage({super.key});

  @override
  State<AdminLabPage> createState() => _AdminLabPageState();
}

class _AdminLabPageState extends State<AdminLabPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBookingCubit>().watchPendingBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Duyệt yêu cầu Lab")),
      body: BlocBuilder<AdminBookingCubit, AdminBookingState>(
        builder: (context, state) {
          if (state is AdminBookingLoading)
            return const Center(child: CircularProgressIndicator());

          if (state is AdminBookingLoaded) {
            final bookings = state.pendingBookings;
            if (bookings.isEmpty) {
              return const Center(child: Text("Không có yêu cầu nào đang chờ"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final timeFmt = DateFormat('HH:mm - dd/MM');

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              booking.deviceName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                            const Icon(
                              Icons.pending_actions,
                              color: Colors.orange,
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          "Người đặt ID: ${booking.userId}",
                        ), // Bạn có thể map thêm userName nếu muốn
                        Text(
                          "Thời gian: ${timeFmt.format(booking.startTime)} - ${timeFmt.format(booking.endTime)}",
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context
                                    .read<AdminBookingCubit>()
                                    .processBooking(booking.id!, 'rejected'),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  "TỪ CHỐI",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () => context
                                    .read<AdminBookingCubit>()
                                    .processBooking(booking.id!, 'approved'),
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "DUYỆT",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
