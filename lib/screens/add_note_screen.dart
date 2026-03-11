import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/login_model.dart';
import '../models/note_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AddNoteScreen extends StatefulWidget {
  final LoginModel user;
  final NoteModel? note; // Optional note for editing

  const AddNoteScreen({super.key, required this.user, this.note});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bookNameController;
  late TextEditingController _chapterNameController;
  late TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing note details if editing
    _bookNameController = TextEditingController(text: widget.note?.title ?? '');
    _chapterNameController =
        TextEditingController(text: widget.note?.chapterName ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _bookNameController.dispose();
    _chapterNameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = await AuthService.getUser();
      if (user != null) {
        if (widget.note != null) {
          // Update existing note
          await ApiService.updateNote(
            id: widget.note!.id,
            token: user.token,
            title: _bookNameController.text,
            chapterName: _chapterNameController.text,
            content: _contentController.text,
          );
        } else {
          // Save new note
          await ApiService.saveNote(
            token: user.token,
            title: _bookNameController.text,
            chapterName: _chapterNameController.text,
            content: _contentController.text,
          );
        }

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(widget.note != null
                    ? "Note updated successfully"
                    : "Note saved successfully")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error saving note: $e");
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save note: $e")),
        );
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
          // Background
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
                        Icons.close_rounded,
                        () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        widget.note != null ? "Edit Note" : "Add New Note",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Book Name", theme),
                          _buildTextField(
                            controller: _bookNameController,
                            hint: "Enter book title...",
                            icon: Icons.menu_book_rounded,
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 24),
                          _buildLabel("Chapter Name", theme),
                          _buildTextField(
                            controller: _chapterNameController,
                            hint: "Enter chapter name...",
                            icon: Icons.bookmark_added_rounded,
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 24),
                          _buildLabel("Your Note content", theme),
                          _buildTextField(
                            controller: _contentController,
                            hint: "Start writing your notes here...",
                            icon: Icons.edit_note_rounded,
                            maxLines: 10,
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveNote,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 5,
                                shadowColor:
                                    theme.primaryColor.withOpacity(0.4),
                              ),
                              child: _isSaving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      widget.note != null
                                          ? "Update Note"
                                          : "Save Note",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: theme.disabledColor),
              prefixIcon: Icon(icon, color: theme.primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap,
      {bool isPrimary = false, bool isLoading = false}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isLoading ? null : onTap,
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
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                icon,
                color: isPrimary ? Colors.white : theme.iconTheme.color,
                size: 20,
              ),
      ),
    );
  }
}
