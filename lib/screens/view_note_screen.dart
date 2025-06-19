import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../models/shopping_note.dart';
import '../services/database_service.dart';
import 'edit_note_screen.dart';

class ViewNoteScreen extends StatelessWidget {
  final ShoppingNote note;

  const ViewNoteScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('notes').doc(note.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final updatedNote = ShoppingNote.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);
        final lines = updatedNote.description.split('\n').where((s) => s.trim().isNotEmpty).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(updatedNote.title),
            actions: [
              IconButton(
                icon: const Icon(Iconsax.trash),
                onPressed: () => _showDeleteDialog(context, updatedNote.id),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Iconsax.edit),
            label: const Text('Edit Catatan'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditNoteScreen(note: updatedNote)),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Padding for FAB
            children: [
              const SizedBox(height: 16),
              // Reminder Section
              if (updatedNote.reminder != null) ...[
                _buildSectionCard(child: _buildReminderTile(context, updatedNote)),
                const SizedBox(height: 16),
              ],

              // Checklist Section
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Iconsax.task_square),
                      title: Text('Daftar Barang', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                    const Divider(),
                    if (lines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: Text('Tidak ada item dalam daftar.')),
                      )
                    else
                      for (var i = 0; i < lines.length; i++)
                        _ChecklistItem(
                          text: lines[i],
                          isChecked: i < updatedNote.checkedItems.length ? updatedNote.checkedItems[i] : false,
                          onChanged: (value) {
                            final dbService = Provider.of<DatabaseService>(context, listen: false);
                            final newCheckedItems = List<bool>.from(updatedNote.checkedItems);
                            newCheckedItems[i] = value!;
                            dbService.updateChecklist(updatedNote.id, newCheckedItems);
                          },
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Widget _buildReminderTile(BuildContext context, ShoppingNote currentNote) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Iconsax.clock, size: 28),
      title: const Text('Pengingat', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${currentNote.reminder!.day}/${currentNote.reminder!.month}/${currentNote.reminder!.year} - ${currentNote.reminder!.hour}:${currentNote.reminder!.minute.toString().padLeft(2, '0')}',
        style: TextStyle(color: Theme.of(context).primaryColor),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String noteId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Catatan?'),
        content: const Text('Catatan ini akan dihapus secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Go back from view screen
              Provider.of<DatabaseService>(context, listen: false).deleteNote(noteId);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String text;
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  const _ChecklistItem({required this.text, required this.isChecked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!isChecked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isChecked ? Theme.of(context).primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isChecked ? Theme.of(context).primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isChecked ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  decoration: isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                  color: isChecked ? Colors.grey : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}