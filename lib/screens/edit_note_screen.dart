import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../services/database_service.dart';
import '../models/shopping_note.dart';

class EditNoteScreen extends StatefulWidget {
  final ShoppingNote note;

  const EditNoteScreen({super.key, required this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime? _selectedDate;
  late List<String> _sharedWith;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _descController = TextEditingController(text: widget.note.description);
    _selectedDate = widget.note.reminder;
    _sharedWith = List.from(widget.note.sharedWith);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitNote() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final lines = _descController.text.trim().split('\n');
      List<bool> newCheckedItems = List.from(widget.note.checkedItems);

      if (newCheckedItems.length > lines.length) {
        newCheckedItems = newCheckedItems.sublist(0, lines.length);
      } else if (newCheckedItems.length < lines.length) {
        newCheckedItems.addAll(List.filled(lines.length - newCheckedItems.length, false));
      }

      await Provider.of<DatabaseService>(context, listen: false).updateNote(
        noteId: widget.note.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        reminder: _selectedDate,
        sharedWith: _sharedWith,
        checkedItems: newCheckedItems,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan berhasil diperbarui'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Catatan')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionCard(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Judul Catatan', prefixIcon: Icon(Iconsax.note)),
                      validator: (v) => v!.isEmpty ? 'Judul tidak boleh kosong' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    child: TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Daftar Barang',
                        hintText: 'Susu\nRoti\nTelur (Enter untuk item baru)',
                        prefixIcon: Icon(Iconsax.task_square),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(child: _buildReminderTile()),
                  const SizedBox(height: 16),
                  _buildSectionCard(child: _buildShareSection()),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
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

  Widget _buildReminderTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Iconsax.clock, size: 28),
      title: const Text('Pengingat', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        _selectedDate != null
            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} - ${_selectedDate!.hour}:${_selectedDate!.minute.toString().padLeft(2, '0')}'
            : 'Tidak ada pengingat',
        style: TextStyle(color: _selectedDate != null ? Theme.of(context).primaryColor : Colors.grey),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedDate != null)
            IconButton(icon: const Icon(Iconsax.trash, color: Colors.red), onPressed: () => setState(() => _selectedDate = null)),
          IconButton(icon: const Icon(Iconsax.calendar_add), onPressed: () => _selectDateTime(context)),
        ],
      ),
    );
  }

  Widget _buildShareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Iconsax.user_add, size: 28),
          title: Text('Bagikan Dengan', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._sharedWith.map((email) => Chip(
                  label: Text(email),
                  onDeleted: () => setState(() => _sharedWith.remove(email)),
                )),
            ActionChip(
              avatar: const Icon(Iconsax.add),
              label: const Text('Tambah'),
              onPressed: () => _showShareDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Iconsax.save_2),
                label: const Text('Simpan Perubahan'),
                onPressed: _submitNote,
              ),
            ),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
    );
    if (pickedTime == null) return;

    setState(() {
      _selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    });
  }

  void _showShareDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bagikan Catatan'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email Penerima'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (emailController.text.contains('@') && !_sharedWith.contains(emailController.text.trim())) {
                setState(() {
                  _sharedWith.add(emailController.text.trim());
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}