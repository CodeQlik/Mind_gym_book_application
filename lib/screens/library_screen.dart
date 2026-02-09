import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:epub_view/epub_view.dart' hide Image;
import 'package:image/image.dart' as img;
import 'reading_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<FileSystemEntity> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = dir.listSync().where((file) {
        return file.path.toLowerCase().endsWith('.epub');
      }).toList();

      if (mounted) {
        setState(() {
          _books = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading books: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : _books.isEmpty
              ? _buildEmptyState(theme)
              : _buildBookList(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 60,
                color: theme.disabledColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Your library is empty.",
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "Find your great book to read in the Home tab.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).scale(),
      ),
    );
  }

  Widget _buildBookList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 140, bottom: 100, left: 16, right: 16),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final File file = File(_books[index].path);
        String filename = p.basename(file.path);
        String title = filename.replaceAll('.epub', '').replaceAll('_', ' ');

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReadingScreen(
                      url: file.path,
                      title: title,
                      isEpub: true,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Cover
                    Hero(
                      tag: 'book_cover_${file.path}',
                      child: Container(
                        width: 70,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: theme.colorScheme.surfaceVariant, // slightly different for placeholder
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FutureBuilder<List<int>?>(
                          future: _fetchCover(file),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Image.memory(
                                Uint8List.fromList(snapshot.data!),
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                              color: theme.primaryColor,
                              padding: const EdgeInsets.all(8),
                              child: Center(
                                child: Text(
                                  title.isNotEmpty ? title[0].toUpperCase() : 'B',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.offline_pin_rounded, size: 14, color: Colors.green.shade600),
                              const SizedBox(width: 4),
                              Text(
                                "Downloaded",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Tap to read",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.1, end: 0);
      },
    );
  }

  Future<List<int>?> _fetchCover(File file) async {
    try {
      final document = await EpubDocument.openFile(file);
      final img.Image? cover = document.CoverImage;
      if (cover != null) {
        return img.encodePng(cover);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
