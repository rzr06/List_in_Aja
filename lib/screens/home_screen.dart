import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/shopping_note.dart';
import '../widgets/note_item.dart';
import 'add_note_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dbService = Provider.of<DatabaseService>(context);
    final userId = authService.currentUser?.uid;
    final userEmail = authService.currentUser?.email;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/LogoOnly.png',
                height: 40,
                width: 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Image.asset(
                'assets/images/TextOnly.png',
                height: 100,
                width: 100,
                fit: BoxFit.contain,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authService.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Milik Saya'),
              Tab(icon: Icon(Icons.group), text: 'Dibagikan'), 
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddNoteScreen()),
          ),
        ),
        body: userId == null || userEmail == null
            ? _buildNotLoggedIn(context)
            : TabBarView(
                children: [
                  _buildNotesList(
                    context,
                    stream: dbService.getNotes(userId),
                    userId: userId,
                    userEmail: userEmail,
                    isOwner: true,
                  ),
                  _buildNotesList(
                    context,
                    stream: dbService.getSharedNotes(userEmail),
                    userId: userId,
                    userEmail: userEmail,
                    isOwner: false,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNotesList(
    BuildContext context, {
    required Stream<List<ShoppingNote>> stream,
    required String? userId,
    required bool isOwner,
    required String? userEmail, 
  }) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return StreamBuilder<List<ShoppingNote>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final notes = snapshot.data ?? [];
        
        return notes.isEmpty
            ? _buildEmptyState(isOwner)
            : RefreshIndicator(
              onRefresh: () async {
                try {
                  if (isOwner) {
                    await dbService.refreshNotes(userId!);
                  } else {
                    if (userEmail != null) {
                      await dbService.refreshSharedNotes(userEmail);
                    }
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal refresh: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: NoteItem(
                      note: notes[i],
                      canEdit: isOwner,
                      onDelete: () => dbService.deleteNote(notes[i].id),
                    ),
                  ),
                ),
              );
      },
    );
  }

  Widget _buildEmptyState(bool isOwner) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOwner ? Icons.shopping_cart_outlined : Icons.group_outlined,
            size: 80,
            color: Colors.teal.shade200,
          ),
          const SizedBox(height: 24),
          Text(
            isOwner 
              ? 'Belum ada catatan belanja ' 
              : 'Tidak ada catatan yang dibagikan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isOwner
              ? 'Tekan tombol + di bawah untuk membuat baru'
              : 'Catatan yang dibagikan dengan Anda akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Anda belum login'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            ),
            child: const Text('Login Sekarang'),
          ),
        ],
      ),
    );
  }
}