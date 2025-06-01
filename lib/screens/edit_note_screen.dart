import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/shopping_note.dart';

class EditNoteScreen extends StatefulWidget {
  final ShoppingNote note;
  
  const EditNoteScreen({
    super.key,
    required this.note,
  });

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late DateTime? _selectedDate;
  late List<String> _sharedWith;
  late List<bool> _checkedItems;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _descController = TextEditingController(text: widget.note.description);
    _selectedDate = widget.note.reminder;
    _sharedWith = List.from(widget.note.sharedWith);
    _checkedItems = List.from(widget.note.checkedItems);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
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

    if (pickedTime != null) {
      setState(() => _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ));
    }
  }

  Future<void> _submitNote() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Sesuaikan checklist dengan deskripsi terbaru
      final lines = _descController.text.trim().split('\n');
      List<bool> newCheckedItems = List.from(_checkedItems);
      
      // Update panjang checklist
      if (newCheckedItems.length > lines.length) {
        newCheckedItems = newCheckedItems.sublist(0, lines.length);
      } else if (newCheckedItems.length < lines.length) {
        newCheckedItems.addAll(
          List.filled(lines.length - newCheckedItems.length, false),
        );
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
        const SnackBar(
          content: Text('Catatan berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Catatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _submitNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Catatan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) => 
                  value!.isEmpty ? 'Harus diisi' : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Daftar Barang (Tekan Enter untuk item baru)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.list),
                  hintText: 'Contoh:\nSusu Ultra\nTelur 1kg\nTepung Terigu',
                ),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Pengingat'),
                subtitle: Text(_selectedDate != null 
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}' 
                  : 'Tidak ada pengingat'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _selectedDate = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Bagikan ke:'),
              ..._sharedWith.map((email) => ListTile(
                title: Text(email),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _sharedWith.remove(email)),
                ),
              )),
              TextButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Tambah Orang'),
                onPressed: () => _showShareDialog(context),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const LinearProgressIndicator()
              else
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan Perubahan'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitNote,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bagikan Catatan'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email Penerima',
            hintText: 'user@example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (emailController.text.contains('@')) {
                setState(() => _sharedWith.add(emailController.text.trim()));
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