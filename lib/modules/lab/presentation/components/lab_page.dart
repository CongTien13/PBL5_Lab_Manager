import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/application/cubit/auth_cubit.dart';
import '../../../home/presentation/application/cubit/device_cubit.dart';
import '../../../../core/models/device_model.dart';
import '../../../../core/models/booking_model.dart';
import '../application/cubit/booking_cubit.dart';
import 'date_time_picker.dart';

class LabPage extends StatefulWidget {
  const LabPage({super.key});

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> {
  @override
  void initState() {
    super.initState();
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryGradientStart,
                                  AppTheme.primaryGradientEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Quản lý phòng Lab",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF6366F1),
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryGradientStart,
                          AppTheme.primaryGradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(4),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text("Đăng ký mới"),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 20),
                            SizedBox(width: 8),
                            Text("Lịch của tôi"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Content
                Expanded(
                  child: BlocListener<BookingCubit, BookingState>(
                    listener: (context, state) {
                      if (state is BookingSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Yêu cầu thành công!"),
                            backgroundColor: AppTheme.successGreen,
                          ),
                        );
                      }
                      if (state is BookingError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: AppTheme.errorRed,
                          ),
                        );
                      }
                    },
                    child: const TabBarView(
                      children: [
                        _RegisterTab(),
                        _MyBookingsTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
          if (state.devices.isEmpty) {
            return const Center(
              child: Text("Không có thiết bị nào"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.devices.length,
            itemBuilder: (context, index) {
              final device = state.devices[index];
              final bool isReady = device.status == 'ready';

              return _DeviceBookingCard(
                device: device,
                isReady: isReady,
                onTap: isReady ? () => _showBookingForm(context, device) : null,
              );
            },
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGradientStart),
        );
      },
    );
  }

  void _showBookingForm(BuildContext context, DeviceModel device) async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.now();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingDateTimeSheet(
        deviceName: device.name,
        initialDate: selectedDate,
        initialStartTime: startTime,
        initialEndTime: endTime,
        onConfirm: (date, start, end) {
          selectedDate = date;
          startTime = start;
          endTime = end;
        },
      ),
    );

    if (result != true) return;

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

class _DeviceBookingCard extends StatelessWidget {
  final DeviceModel device;
  final bool isReady;
  final VoidCallback? onTap;

  const _DeviceBookingCard({
    required this.device,
    required this.isReady,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isReady ? AppTheme.successGreen : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.devices,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isReady ? "Sẵn sàng" : "Đang bận",
                        style: TextStyle(
                          fontSize: 13,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isReady
                        ? const Color(0xFF6366F1).withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_calendar_outlined,
                    color: isReady ? const Color(0xFF6366F1) : Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

        if (state is BookingLoaded) {
          bookingsToShow = state.myBookings;
        } else if (state is BookingSubmitting) {
          bookingsToShow = state.cachedBookings;
        }

        if (bookingsToShow.isNotEmpty) {
          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: bookingsToShow.length,
                itemBuilder: (context, index) =>
                    _BookingCard(booking: bookingsToShow[index]),
              ),
              if (state is BookingSubmitting)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    color: AppTheme.primaryGradientStart,
                    backgroundColor: Colors.transparent,
                  ),
                ),
            ],
          );
        }

        if (state is BookingSubmitting || state is BookingInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGradientStart),
          );
        }

        if (state is BookingError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                "Bạn chưa có lịch đặt nào",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm - dd/MM');
    final statusColor = AppTheme.getStatusColor(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event_available,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.deviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${timeFormat.format(booking.startTime)} đến ${timeFormat.format(booking.endTime)}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: booking.status, isCompact: true),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (booking.status == 'pending' || booking.status == 'approved')
                  TextButton.icon(
                    onPressed: () =>
                        context.read<BookingCubit>().cancelBooking(booking.id!),
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                    label: const Text(
                      "Hủy",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                if (booking.status == 'using')
                  ElevatedButton.icon(
                    onPressed: () => context
                        .read<BookingCubit>()
                        .stopUsingDevice(booking.deviceId, booking.id!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    icon: const Icon(Icons.stop, size: 18),
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