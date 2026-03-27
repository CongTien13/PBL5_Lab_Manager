import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/cubit/device_cubit.dart';
import '../../../../core/models/device_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text("Trạng thái phòng Lab")),
      body: BlocBuilder<DeviceCubit, DeviceState>(
        builder: (context, state) {
          if (state is DeviceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DeviceLoaded) {
            if (state.devices.isEmpty) {
              return const Center(
                child: Text("Không có thiết bị nào trong hệ thống"),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.devices.length,
              itemBuilder: (context, index) {
                final device = state.devices[index];
                bool isReady = device.status == 'ready';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    leading: Icon(
                      Icons.settings_remote_rounded,
                      color: isReady ? Colors.green : Colors.red,
                      size: 40,
                    ),
                    title: Text(
                      device.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      isReady
                          ? "Sẵn sàng"
                          : "Đang bận: ${device.currentUserName ?? 'N/A'}",
                      style: TextStyle(
                        color: isReady ? Colors.green : Colors.red,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.info_outline,
                      color: Colors.grey,
                    ),
                    onTap: () => _showDeviceDetails(context, device),
                  ),
                );
              },
            );
          }

          if (state is DeviceError) {
            return Center(child: Text("Lỗi: ${state.message}"));
          }

          return const SizedBox();
        },
      ),
    );
  }

  void _showDeviceDetails(BuildContext context, DeviceModel device) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              device.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF007AFF),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "📍 Vị trí: Phòng thực hành tầng 2",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              "📝 Mô tả: ${device.description}",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              "⚡ Trạng thái: ${device.status.toUpperCase()}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: device.status == 'ready' ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("ĐÓNG"),
            ),
          ],
        ),
      ),
    );
  }
}
