import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import 'book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BookModel> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
    _initSpeech();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = [];
    });

    try {
      final results = await ApiService.searchBooks(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
          if (results.isEmpty) {
            _errorMessage = "No books found for '$query'";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to search books. Please try again.";
        });
      }
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(result) {
    setState(() {
      _searchController.text = result.recognizedWords;
      if (result.finalResult) {
        _isListening = false;
        _performSearch(result.recognizedWords);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _performSearch,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: "Search titles, authors, ISBN...",
                          hintStyle: TextStyle(color: theme.disabledColor),
                          prefixIcon: Icon(Icons.search_rounded, color: theme.disabledColor),
                          suffixIcon: _isListening
                              ? IconButton(
                                  icon: Icon(Icons.mic, color: theme.primaryColor),
                                  onPressed: _stopListening,
                                )
                              : _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: theme.disabledColor),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchResults = []);
                                      },
                                    )
                                  : _speechEnabled
                                      ? IconButton(
                                          icon: Icon(Icons.mic_none, color: theme.disabledColor),
                                          onPressed: _startListening,
                                        )
                                      : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (text) {
                          setState(() {}); // Rebuild to show/hide clear button
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _performSearch(_searchController.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 60, color: theme.disabledColor),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
                              ),
                            ],
                          ).animate().fadeIn(),
                        )
                      : _searchResults.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.menu_book_rounded, size: 60, color: theme.disabledColor),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Search for your favorite books",
                                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
                                  ),
                                ],
                              ).animate().fadeIn(),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final book = _searchResults[index];
                                return _buildSearchResultItem(context, book, theme)
                                    .animate(delay: (50 * index).ms)
                                    .fadeIn()
                                    .slideY(begin: 0.1, end: 0);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(BuildContext context, BookModel book, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 70,
                height: 100,
                child: book.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        book.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: theme.scaffoldBackgroundColor),
                      )
                    : Container(color: theme.scaffoldBackgroundColor),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.authors.join(", "),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (book.rating > 0)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB800)),
                        const SizedBox(width: 4),
                        Text(
                          book.rating.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    book.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
