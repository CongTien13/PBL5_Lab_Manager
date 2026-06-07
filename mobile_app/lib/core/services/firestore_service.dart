import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy Stream dữ liệu từ một Collection
  Stream<QuerySnapshot<Map<String, dynamic>>> getStream(
    String path, {
    Query Function(Query query)? query,
  }) {
    Query collection = _db.collection(path);
    if (query != null) collection = query(collection);
    return collection.snapshots()
        as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }

  // Thêm mới Document
  Future<DocumentReference> add(String path, Map<String, dynamic> data) {
    return _db.collection(path).add(data);
  }

  // Cập nhật Document
  Future<void> update(String path, String docId, Map<String, dynamic> data) {
    return _db.collection(path).doc(docId).update(data);
  }

  // Xóa Document
  Future<void> delete(String path, String docId) {
    return _db.collection(path).doc(docId).delete();
  }
}
