import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_note.dart';
import 'notification_service.dart'; 

class DatabaseService {
  final _firestore = FirebaseFirestore.instance;
  final _notificationService = NotificationService();

  Future<void> addNote({
    required String userId,
    required String title,
    required String description,
    DateTime? reminder,
    List<String> sharedWith = const [],
    required List<bool> checkedItems,
  }) async {
    final noteRef = _firestore.collection('notes').doc();

    final note = ShoppingNote(
      id: noteRef.id,
      title: title,
      description: description,
      reminder: reminder,
      ownerId: userId,
      sharedWith: sharedWith,
      checkedItems: checkedItems
    );

    await noteRef.set(note.toMap());

    // Jadwalkan notifikasi jika ada reminder
    if (reminder != null) {
      await _notificationService.scheduleNotification(
        id: note.id.hashCode, 
        title: 'Pengingat Belanja: $title',
        body: description,
        scheduledTime: reminder,
      );
    }
  }

  Future<void> updateNote({
    required String noteId,
    required String title,
    required String description,
    DateTime? reminder,
    List<String> sharedWith = const [],
    required List<bool> checkedItems,
  }) async {
    final noteRef = _firestore.collection('notes').doc(noteId);
    
    // Ambil data lama untuk cek reminder sebelumnya
    final oldNoteSnapshot = await noteRef.get();
    if (!oldNoteSnapshot.exists) return;
    final oldNote = ShoppingNote.fromMap(oldNoteSnapshot.data()!, noteId);

    // Batalkan notifikasi lama jika ada
    if (oldNote.reminder != null) {
      await _notificationService.cancelNotification(noteId.hashCode);
    }

    await noteRef.update({
      'title': title,
      'description': description,
      'reminder': reminder,
      'sharedWith': sharedWith,
    });

    // Jadwalkan notifikasi baru jika ada reminder baru
    if (reminder != null) {
      await _notificationService.scheduleNotification(
        id: noteId.hashCode,
        title: 'Pengingat Belanja: $title',
        body: description,
        scheduledTime: reminder,
      );
    }
  }

  Future<void> deleteNote(String noteId) async {
    // Batalkan notifikasi saat hapus
    await _notificationService.cancelNotification(noteId.hashCode);
    await _firestore.collection('notes').doc(noteId).delete();
  }

  // Metode lainnya tetap sama...
  Stream<List<ShoppingNote>> getNotes(String userId) {
    return _firestore
        .collection('notes')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingNote.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ShoppingNote>> getSharedNotes(String userEmail) {
    return _firestore
        .collection('notes')
        .where('sharedWith', arrayContains: userEmail)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShoppingNote.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> shareNote({
    required String noteId,
    required List<String> emails,
  }) async {
    final noteRef = _firestore.collection('notes').doc(noteId);
    await noteRef.update({
      'sharedWith': FieldValue.arrayUnion(emails),
    });
  }

  Future<void> updateChecklist(String noteId, List<bool> checkedItems) async {
    await _firestore.collection('notes').doc(noteId).update({
      'checkedItems': checkedItems,
    });
  }

  Future<void> refreshNotes(String userId) async {
    await _firestore.collection('notes')
      .where('ownerId', isEqualTo: userId)
      .get(const GetOptions(source: Source.server));
  }

  Future<void> refreshSharedNotes(String userEmail) async {
    await _firestore.collection('notes')
      .where('sharedWith', arrayContains: userEmail)
      .get(const GetOptions(source: Source.server));
  }

}