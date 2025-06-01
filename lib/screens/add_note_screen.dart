import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AddNoteScreen extends StatefulWidget {
  final DateTime? initialDate;
  final List<String>? initialSharedWith;
  
  const AddNoteScreen({
    super.key,
    this.initialDate,
    this.initialSharedWith,
  });

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
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _sharedWith = widget.initialSharedWith ?? [];
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
    final userId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    
    if (userId != null) {
      // Split deskripsi menjadi list barang
      final items = _descController.text.trim().split('\n');
      // Inisialisasi checklist false untuk semua item
      final checkedItems = List<bool>.filled(items.length, false);

      await Provider.of<DatabaseService>(context, listen: false).addNote(
        userId: userId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        reminder: _selectedDate,
        sharedWith: _sharedWith,
        checkedItems: checkedItems, 
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Catatan'),
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
                autofocus: true,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: '(Tekan Enter Untuk Item Baru)',
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
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
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
                  label: const Text('Simpan Catatan'),
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