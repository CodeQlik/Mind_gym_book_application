import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../models/note_model.dart';
import '../models/login_model.dart';
import 'add_note_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final LoginModel user;
  final NoteModel note;

  const NoteDetailScreen({super.key, required this.user, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late NoteModel _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: isDark
                      ? [const Color(0xFF1A1A1A), const Color(0xFF121212)]
                      : [Colors.white, Colors.blueGrey.shade50],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildIconButton(
                        Icons.arrow_back_ios_new_rounded,
                        () => Navigator.pop(context, _note),
                      ),
                      const Spacer(),
                      _buildIconButton(
                        Icons.edit_note_rounded,
                        () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddNoteScreen(
                                user: widget.user,
                                note: _note,
                              ),
                            ),
                          );
                          if (result == true) {
                            // In a real app, we'd fetch the updated note from API here
                            // For now, since we don't have a getNoteById, we'll return to list
                            // or ideally the AddNoteScreen would return the updated NoteModel.
                            // Let's assume we need to refresh the list anyway.
                            Navigator.pop(context, true);
                          }
                        },
                        isPrimary: true,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags / Metadata
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _note.chapterName ?? "General Note",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ).animate().fadeIn().slideX(),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          _note.title.isNotEmpty
                              ? _note.title
                              : "Untitled Note",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        )
                            .animate(delay: 100.ms)
                            .fadeIn()
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 8),

                        // Date
                        Text(
                          "Created on ${_formatDate(_note.createdAt)}",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ).animate(delay: 200.ms).fadeIn(),

                        const SizedBox(height: 32),

                        // Content Area
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.cardColor.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Text(
                                _note.content,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.6,
                                  fontSize: 17,
                                  color: theme.textTheme.bodyLarge?.color
                                      ?.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate(delay: 300.ms)
                            .fadeIn()
                            .scale(begin: const Offset(0.95, 0.95)),
                      ],
                    ),
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
          size: 24,
        ),
      ),
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
