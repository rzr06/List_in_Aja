import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  List<String> _sharedWith = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitNote() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);
    final userId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;

    if (userId != null) {
      try {
        final items = _descController.text.trim().split('\n');
        final checkedItems = List<bool>.filled(items.length, false);

        await Provider.of<DatabaseService>(context, listen: false).addNote(
          userId: userId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          reminder: _selectedDate,
          sharedWith: _sharedWith,
          checkedItems: checkedItems,
        );

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan berhasil ditambahkan'), backgroundColor: Colors.green),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Catatan Baru')),
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
                      validator: (v) => v!.isEmpty ? 'Daftar barang tidak boleh kosong' : null,
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
                icon: const Icon(Iconsax.save_add),
                label: const Text('Simpan Catatan'),
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