import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Để định dạng ngày giờ
import '../../../auth/presentation/application/cubit/auth_cubit.dart';
import '../../../home/presentation/application/cubit/device_cubit.dart';
import '../../../../core/models/device_model.dart';
import '../../../../core/models/booking_model.dart';
import '../application/cubit/booking_cubit.dart';

class LabPage extends StatefulWidget {
  const LabPage({super.key});

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> {
  @override
  void initState() {
    super.initState();
    // Bắt đầu lắng nghe lịch cá nhân ngay khi vào trang
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      context.read<BookingCubit>().watchMyBookings(authState.user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Quản lý phòng Lab"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Đăng ký mới", icon: Icon(Icons.add_circle_outline)),
              Tab(text: "Lịch của tôi", icon: Icon(Icons.history)),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: BlocListener<BookingCubit, BookingState>(
          listener: (context, state) {
            if (state is BookingSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Yêu cầu thành công!")),
              );
            }
            if (state is BookingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const TabBarView(
            children: [
              _RegisterTab(), // Tab đăng ký thiết bị
              _MyBookingsTab(), // Tab quản lý lịch cá nhân
            ],
          ),
        ),
      ),
    );
  }
}

// --- TAB 1: ĐĂNG KÝ THIẾT BỊ ---
class _RegisterTab extends StatelessWidget {
  const _RegisterTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceCubit, DeviceState>(
      builder: (context, state) {
        if (state is DeviceLoaded) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.devices.length,
            itemBuilder: (context, index) {
              final device = state.devices[index];
              final bool isReady = device.status == 'ready';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    device.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(isReady ? "Sẵn sàng" : "Đang bận"),
                  trailing: Icon(
                    Icons.edit_calendar_outlined,
                    color: isReady ? const Color(0xFF007AFF) : Colors.grey,
                  ),
                  onTap: isReady
                      ? () => _showBookingForm(context, device)
                      : null,
                ),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  // Hàm chọn ngày giờ (giữ nguyên logic của bạn)
  void _showBookingForm(BuildContext context, DeviceModel device) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (selectedDate == null) return;

    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (startTime == null) return;

    TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: startTime,
    );
    if (endTime == null) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      final start = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime.hour,
        startTime.minute,
      );
      final end = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        endTime.hour,
        endTime.minute,
      );

      final newBooking = BookingModel(
        userId: authState.user.uid,
        deviceId: device.id,
        deviceName: device.name,
        startTime: start,
        endTime: end,
        status: 'pending',
      );
      context.read<BookingCubit>().submitBooking(newBooking);
    }
  }
}

// --- TAB 2: LỊCH CỦA TÔI ---
class _MyBookingsTab extends StatelessWidget {
  const _MyBookingsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        List<BookingModel> bookingsToShow = [];

        // Lấy danh sách để hiển thị tùy theo State
        if (state is BookingLoaded) {
          bookingsToShow = state.myBookings;
        } else if (state is BookingSubmitting) {
          bookingsToShow = state.cachedBookings;
        }

        // Nếu có dữ liệu thì hiện List, kể cả khi đang Submitting
        if (bookingsToShow.isNotEmpty) {
          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookingsToShow.length,
                itemBuilder: (context, index) =>
                    _buildBookingCard(context, bookingsToShow[index]),
              ),
              if (state is BookingSubmitting)
                const LinearProgressIndicator(), // Hiện thanh chạy nhỏ ở trên đầu khi đang gửi
            ],
          );
        }

        // Chỉ hiện xoay tròn khi thực sự không có gì trong tay
        if (state is BookingSubmitting || state is BookingInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BookingError) {
          return Center(child: Text(state.message));
        }

        return const Center(child: Text("Bạn chưa có lịch đặt nào"));
      },
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking) {
    final timeFormat = DateFormat('HH:mm - dd/MM');
    Color statusColor;
    switch (booking.status) {
      case 'approved':
        statusColor = Colors.blue;
        break;
      case 'using':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'finished':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                booking.deviceName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${timeFormat.format(booking.startTime)} đến ${timeFormat.format(booking.endTime)}",
              ),
              trailing: Text(
                booking.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 1. Nút Hủy (Chỉ hiện khi chưa dùng)
                if (booking.status == 'pending' || booking.status == 'approved')
                  TextButton.icon(
                    onPressed: () =>
                        context.read<BookingCubit>().cancelBooking(booking.id!),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text(
                      "Hủy",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                // 2. Nút Dừng (Chỉ hiện khi đang dùng - Pi sẽ chuyển status sang using sau khi quét mặt)
                if (booking.status == 'using')
                  ElevatedButton.icon(
                    onPressed: () => context
                        .read<BookingCubit>()
                        .stopUsingDevice(booking.deviceId, booking.id!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    icon: const Icon(Icons.stop),
                    label: const Text("Dừng dùng"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
