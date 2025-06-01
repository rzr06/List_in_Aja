import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingNote {
  final String id;
  final String title;
  final String description;
  final DateTime? reminder;
  final String ownerId;
  final List<String> sharedWith;
  final List<bool> checkedItems;

  ShoppingNote({
    required this.id,
    required this.title,
    required this.description,
    this.reminder,
    required this.ownerId,
    this.sharedWith = const [],
    required this.checkedItems,
  });

    factory ShoppingNote.fromMap(Map<String, dynamic> data, String id) {
    final description = data['description'] ?? '';
    final lines = description.split('\n');

    return ShoppingNote(
      id: id,
      title: data['title'],
      description: data['description'],
      reminder: (data['reminder'] as Timestamp?)?.toDate(),
      ownerId: data['ownerId'],
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
      checkedItems: List<bool>.from(data['checkedItems'] ?? 
          List.filled(lines.length, false)), // Auto-generatr jika belum ada
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'reminder': reminder != null ? Timestamp.fromDate(reminder!) : null,
      'ownerId': ownerId,
      'sharedWith': sharedWith,
      'checkedItems': checkedItems,
    };
  }
}