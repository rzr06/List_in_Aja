import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/shopping_note.dart';
import '../screens/edit_note_screen.dart';
import '../screens/view_note_screen.dart';

class NoteItem extends StatelessWidget {
  final ShoppingNote note;
  final VoidCallback onDelete;
  final bool canEdit;

  const NoteItem({
    super.key,
    required this.note,
    required this.onDelete,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ViewNoteScreen(note: note)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.note_text,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (note.reminder != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(Iconsax.clock, size: 14, color: Colors.orange.shade700),
                              const SizedBox(width: 6),
                              Text(
                                '${note.reminder!.day}/${note.reminder!.month} - ${note.reminder!.hour.toString().padLeft(2, '0')}:${note.reminder!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 13, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (canEdit) _buildPopupMenu(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Iconsax.more, color: Colors.grey),
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditNoteScreen(note: note)),
          );
        } else if (value == 'delete') {
          _showDeleteDialog(context);
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Iconsax.edit),
            title: Text('Edit'),
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Iconsax.trash, color: Colors.red),
            title: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
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
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}