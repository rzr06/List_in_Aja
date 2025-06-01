import 'package:flutter/material.dart';
import '../models/shopping_note.dart';
import '../screens/edit_note_screen.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

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
    final lines = note.description.split('\n');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.1),
              blurRadius: 8, 
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40, 
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_basket,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade800,
                            ),
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (note.reminder != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '⏰ ${note.reminder!.toString().substring(0, 16)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Colors.teal.shade300,
                        size: 22, 
                      ),
                      onPressed: () => _navigateToEditScreen(context),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade300,
                        size: 22, 
                      ),
                      onPressed: () => _showDeleteDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: lines.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: index < note.checkedItems.length 
                                  ? note.checkedItems[index] 
                                  : false,
                              onChanged: (value) {
                                final newChecked = List<bool>.from(note.checkedItems);
                                if (index >= newChecked.length) {
                                  newChecked.addAll(
                                    List.filled(index - newChecked.length + 1, false));
                                }
                                newChecked[index] = value!;
                                
                                Provider.of<DatabaseService>(context, listen: false)
                                  .updateChecklist(note.id, newChecked);
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.teal.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 2),
                // if (note.sharedWith.isNotEmpty)
                //   Padding(
                //     padding: const EdgeInsets.only(top: 8),
                //     child: Wrap(
                //       spacing: 4,
                //       runSpacing: 2,
                //       children: note.sharedWith.map((email) => Chip(
                //         label: Text(
                //           email,
                //           style: const TextStyle(fontSize: 10), // Diperkecil
                //         ),
                //         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                //         visualDensity: VisualDensity.compact,
                //       )).toList(),
                //     ),
                //   ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNoteScreen(note: note),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, 
          color: Colors.orange.shade400, 
          size: 40),
        title: const Text('Hapus Catatan?'),
        content: const Text('Catatan akan dihapus permanen dari perangkat'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.red.shade100),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: Text('Hapus', 
              style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }
}