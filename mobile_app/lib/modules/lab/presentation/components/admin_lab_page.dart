import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';
import '../application/cubit/admin_booking_cubit.dart';

class AdminLabPage extends StatefulWidget {
  const AdminLabPage({super.key});

  @override
  State<AdminLabPage> createState() => _AdminLabPageState();
}

class _AdminLabPageState extends State<AdminLabPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Load pending by default
    context.read<AdminBookingCubit>().watchPendingBookings();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      context.read<AdminBookingCubit>().watchPendingBookings();
    } else {
      context.read<AdminBookingCubit>().watchAllBookings();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            Icons.approval_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Duyệt yêu cầu Lab",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Quản lý yêu cầu đặt thiết bị",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryGradientStart,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryGradientStart,
                  tabs: const [
                    Tab(text: "Chờ duyệt"),
                    Tab(text: "Lịch sử"),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 0: Pending
                    BlocBuilder<AdminBookingCubit, AdminBookingState>(
                      builder: (context, state) => _buildBookingList(state, 0),
                    ),
                    // Tab 1: All History
                    BlocBuilder<AdminBookingCubit, AdminBookingState>(
                      builder: (context, state) => _buildBookingList(state, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingList(AdminBookingState state, int tabIndex) {
    if (state is AdminBookingLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryGradientStart,
        ),
      );
    }

    if (state is AdminBookingLoaded) {
      final pending = state.pendingBookings ?? [];
      final all = state.allBookings ?? [];
      final bookings = tabIndex == 0 ? pending : all;
      if (bookings.isEmpty) {
        final emptyMsg = tabIndex == 0
            ? "Không có yêu cầu nào đang chờ"
            : "Không có lịch sử đặt lịch";
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: 16),
              Text(
                emptyMsg,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];
                          final timeFmt = DateFormat('HH:mm - dd/MM');

                          final status = booking.status;
                          final isPending = status == 'pending';
                          final iconColor = isPending
                              ? AppTheme.warningOrange
                              : status == 'approved' || status == 'finished'
                                  ? AppTheme.successGreen
                                  : AppTheme.errorRed;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
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
                                  // Header row
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: iconColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isPending
                                              ? Icons.pending_actions
                                              : status == 'approved' || status == 'finished'
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                          color: iconColor,
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
                                            StatusBadge(status: status),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(height: 1),
                                  const SizedBox(height: 16),

                                  // Info rows
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        FutureBuilder<String>(
                                          future: UserService().getUserName(booking.userId),
                                          builder: (ctx, snapshot) => _InfoRow(
                                            icon: Icons.person_outline,
                                            label: "Người đặt",
                                            value: snapshot.data ?? '...',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _InfoRow(
                                          icon: Icons.access_time,
                                          label: "Thời gian",
                                          value: "${timeFmt.format(booking.startTime)} - ${timeFmt.format(booking.endTime)}",
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action buttons (only show for pending tab)
                                  if (tabIndex == 0) ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => context
                                                .read<AdminBookingCubit>()
                                                .processBooking(booking.id!, 'rejected'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppTheme.errorRed,
                                              side: const BorderSide(color: AppTheme.errorRed),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            icon: const Icon(Icons.close, size: 18),
                                            label: const Text("TỪ CHỐI"),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.successGreen,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            onPressed: () => context
                                                .read<AdminBookingCubit>()
                                                .processBooking(booking.id!, 'approved'),
                                            icon: const Icon(Icons.check, size: 18),
                                            label: const Text("DUYỆT"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
    

    return const SizedBox();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}