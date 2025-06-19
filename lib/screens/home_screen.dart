import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
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
          title: Image.asset(
            'assets/images/TextOnly.png',
            width: 120,
            color: Theme.of(context).primaryColor,
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.logout),
              onPressed: () async {
                await authService.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Catatan Saya'), Tab(text: 'Dibagikan')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Iconsax.add),
          label: const Text('Tambah'),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddNoteScreen()),
              ),
        ).animate().slideY(begin: 2, duration: 400.ms, curve: Curves.easeOut),
        body:
            userId == null || userEmail == null
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
          return Center(
            child: Text('Terjadi kesalahan: Silahkan coba kembali nanti'),
          );
        }

        final notes = snapshot.data ?? [];

        if (notes.isEmpty) {
          return _buildEmptyState(isOwner);
        }

        return RefreshIndicator(
          onRefresh: () async {
            isOwner
                ? await dbService.refreshNotes(userId!)
                : await dbService.refreshSharedNotes(userEmail!);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder:
                (_, i) => NoteItem(
                      note: notes[i],
                      canEdit: isOwner,
                      onDelete: () => dbService.deleteNote(notes[i].id),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: -0.1, delay: (100 * i).ms),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isOwner) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOwner ? Iconsax.note_add : Iconsax.people,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              isOwner
                  ? 'Buat Catatan Pertamamu'
                  : 'Belum Ada Catatan Dibagikan',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isOwner
                  ? 'Semua catatan belanjamu akan muncul di sini. Tekan tombol "+" untuk memulai.'
                  : 'Saat seseorang membagikan catatan denganmu, catatan itu akan muncul di sini.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Anda belum login.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed:
                () => Navigator.pushReplacement(
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
