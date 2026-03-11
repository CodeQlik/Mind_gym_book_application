import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../models/note_model.dart';
import '../models/login_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'add_note_screen.dart';
import 'note_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  final LoginModel user;
  const NotesScreen({super.key, required this.user});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<NoteModel> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getUser();
      if (user != null) {
        final notes = await ApiService.getAllNotes(user.token);
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notes: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNote(int id, int index) async {
    final user = await AuthService.getUser();
    if (user != null) {
      final success = await ApiService.deleteNote(id, user.token);
      if (success) {
        setState(() {
          _notes.removeAt(index);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Note deleted successfully")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete note")),
          );
        }
        // Refresh to restore if needed, or user will see it's still there
        _fetchNotes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Gradient/Glass effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                      : [Colors.white, Colors.blueGrey.shade50],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildIconButton(
                        Icons.arrow_back_ios_new_rounded,
                        () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "My Notes",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _buildIconButton(
                        Icons.add_rounded,
                        () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddNoteScreen(user: widget.user),
                            ),
                          );
                          if (result == true) {
                            _fetchNotes();
                          }
                        },
                        isPrimary: true,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _notes.isEmpty
                          ? _buildEmptyState(theme)
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _notes.length,
                              itemBuilder: (context, index) {
                                final note = _notes[index];
                                return _buildNoteItem(note, index, theme);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap,
      {bool isPrimary = false}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isPrimary ? theme.primaryColor : theme.cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : theme.iconTheme.color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 80, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text(
            "No notes yet",
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.disabledColor),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the + button to create your first note!",
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.disabledColor),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildNoteItem(NoteModel note, int index, ThemeData theme) {
    return Dismissible(
      key: Key(note.id.toString()),
      direction: DismissDirection.horizontal,
      background: _buildSwipeAction(
          Alignment.centerLeft, Colors.redAccent, Icons.delete_outline),
      secondaryBackground: _buildSwipeAction(
          Alignment.centerRight, Colors.redAccent, Icons.delete_outline),
      onDismissed: (direction) => _deleteNote(note.id, index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteDetailScreen(
                      user: widget.user,
                      note: note,
                    ),
                  ),
                );
                if (result == true) {
                  _fetchNotes();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isNotEmpty
                                ? note.title
                                : "Untitled Book",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            note.chapterName ?? "General",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (note.content.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        note.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(note.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: theme.disabledColor, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildSwipeAction(Alignment alignment, Color color, IconData icon) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return isoString;
    }
  }
}
