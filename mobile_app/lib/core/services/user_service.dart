import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Lấy tên người dùng từ Firestore
  Future<String> getUserName(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['name'] as String? ?? 'Người dùng';
    } catch (e) {
      return 'Người dùng';
    }
  }
}