import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/cubit/device_cubit.dart';
import '../../../../core/models/device_model.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF007AFF);

    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý thiết bị Lab")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => _showDeviceDialog(context), // Mở form thêm mới
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocListener<DeviceCubit, DeviceState>(
        listener: (context, state) {
          if (state is DeviceActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<DeviceCubit, DeviceState>(
          builder: (context, state) {
            if (state is DeviceLoaded) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.devices.length,
                itemBuilder: (context, index) {
                  final device = state.devices[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.devices,
                        color: device.status == 'ready'
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Text(
                        device.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(device.description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showDeviceDialog(context, device: device),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, device.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  // Dialog dùng chung cho cả Thêm và Sửa
  void _showDeviceDialog(BuildContext context, {DeviceModel? device}) {
    final nameController = TextEditingController(text: device?.name);
    final descController = TextEditingController(text: device?.description);
    String status = device?.status ?? 'ready';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(device == null ? "Thêm thiết bị" : "Sửa thiết bị"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Tên thiết bị"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Mô tả"),
            ),
            DropdownButtonFormField<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: 'ready', child: Text("Sẵn sàng")),
                DropdownMenuItem(value: 'off', child: Text("Bảo trì")),
              ],
              onChanged: (val) => status = val!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              final newDevice = DeviceModel(
                id:
                    device?.id ??
                    "", // ID sẽ do Firestore add tự động nếu là thêm mới
                name: nameController.text,
                description: descController.text,
                status: status,
              );
              if (device == null) {
                context.read<DeviceCubit>().addDevice(newDevice);
              } else {
                context.read<DeviceCubit>().updateDevice(newDevice);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa thiết bị này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              context.read<DeviceCubit>().deleteDevice(id);
              Navigator.pop(dialogContext);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
