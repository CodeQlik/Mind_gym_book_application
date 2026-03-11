import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'book_detail_screen.dart'; // Import for navigation

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Bookmarks
  List<BookModel> _bookmarkedBooks = [];
  bool _isLoadingBookmarks = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookmarks();

    // Refresh bookmarks when switching to that tab
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        _loadBookmarks();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Bookmarks Logic
  Future<void> _loadBookmarks() async {
    setState(() => _isLoadingBookmarks = true);
    try {
      final user = await AuthService.getUser();
      if (user != null && user.token.isNotEmpty) {
        final bookmarks = await ApiService.getBookmarks(user.token);
        if (mounted) {
          setState(() {
            _bookmarkedBooks = bookmarks;
            _isLoadingBookmarks = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingBookmarks = false);
      }
    } catch (e) {
      debugPrint("Error loading bookmarks: $e");
      if (mounted) setState(() => _isLoadingBookmarks = false);
    }
  }

  Future<void> _removeBookmark(String bookId) async {
    try {
      final user = await AuthService.getUser();
      if (user != null) {
        // Toggle off
        await ApiService.toggleBookmark(bookId, user.token);
        // Refresh list
        _loadBookmarks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Removed from bookmarks")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error removing bookmark: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Calculate top padding to avoid overlap with MainScreen's floating top bar
    // Standard status bar + roughly 60-80px for the floating bar
    final topPadding = MediaQuery.of(context).padding.top + 80;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          SizedBox(height: topPadding),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              dividerColor: Colors.transparent,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: "Subscribed"),
                Tab(text: "Bookmarked"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Subscribed (Placeholder)
                _buildPlaceholderTab(theme, "No subscriptions yet",
                    Icons.subscriptions_outlined),

                // 2. Bookmarked
                _buildBookmarksTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 3: BOOKMARKS =================
  Widget _buildBookmarksTab(ThemeData theme) {
    if (_isLoadingBookmarks) {
      return Center(
          child: CircularProgressIndicator(color: theme.primaryColor));
    }

    if (_bookmarkedBooks.isEmpty) {
      return _buildEmptyState(
          theme, "No bookmarks yet", "Save books to read them later.");
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          16, 16, 16, 100), // Added bottom padding for nav bar
      itemCount: _bookmarkedBooks.length,
      itemBuilder: (context, index) {
        final book = _bookmarkedBooks[index];
        return _buildBookmarkItem(theme, book, index);
      },
    );
  }

  Widget _buildBookmarkItem(ThemeData theme, BookModel book, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Reduced from 16
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
                builder: (context) => BookDetailScreen(book: book),
              ),
            ).then((_) {
              // Refresh on return in case bookmark status changed
              _loadBookmarks();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8), // Reduced from 12
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover
                Hero(
                  tag: 'bookmark_cover_${book.id}',
                  child: Container(
                    width: 60, // Reduced from 70
                    height: 85, // Reduced from 100
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2)),
                      ],
                      image: book.thumbnailUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(book.thumbnailUrl),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: book.thumbnailUrl.isEmpty
                        ? const Center(
                            child: Icon(Icons.book, color: Colors.grey))
                        : null,
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
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2), // Reduced from 4
                      Text(
                        book.authors.join(", "),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8), // Reduced from 12
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "View Details",
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: theme.primaryColor),
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark_remove,
                                color: Colors.redAccent),
                            onPressed: () => _removeBookmark(book.id),
                            tooltip: "Remove Bookmark",
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  // ================= HELPERS =================
  Widget _buildPlaceholderTab(ThemeData theme, String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text(title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: theme.disabledColor)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String title, String subtitle) {
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
              child: Icon(Icons.menu_book_rounded,
                  size: 60, color: theme.disabledColor),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).scale(),
      ),
    );
  }
}
