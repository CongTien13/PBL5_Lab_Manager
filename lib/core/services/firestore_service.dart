// import 'package:cloud_firestore/cloud_firestore.dart';

// class FirestoreService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   // Lấy dữ liệu Stream (Realtime)
//   Stream<List<Map<String, dynamic>>> getStreamCollection(String path) {
//     return _db.collection(path).snapshots().map((snapshot) =>
//         snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
//   }

//   // Thêm mới dữ liệu
//   Future<void> addDocument(String path, Map<String, dynamic> data) {
//     return _db.collection(path).add(data);
//   }

//   // Cập nhật dữ liệu (Dùng cho việc Duyệt)
//   Future<void> updateDocument(String path, String docId, Map<String, dynamic> data) {
//     return _db.collection(path).doc(docId).update(data);
//   }
// }
