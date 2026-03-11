import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/login_model.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import 'book_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final LoginModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = "All";
  final Map<String, List<BookModel>> _categoryBooks = {};
  final Map<String, bool> _categoryLoading = {};
  List<String> _categories = ["All"];
  List<BookModel> _trendingBooks = [];
  List<BookModel> _bestsellingBooks = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Fetch MindGym books (All) which will also populate categories
    await _fetchBooksForCategory("All");
  }

  Future<void> _fetchBooksForCategory(String category) async {
    if (_categoryBooks.containsKey(category) &&
        _categoryBooks[category]!.isNotEmpty) {
      return;
    }

    if (mounted) setState(() => _categoryLoading[category] = true);

    try {
      List<BookModel> books = [];

      if (category == "All") {
        // Main source: MindGym API
        books = await ApiService.fetchMindGymBooks(token: widget.user.token);

        // Extract Categories dynamically and clean them
        final Set<String> dynamicCategories = {};
        for (var book in books) {
          for (var c in book.categories) {
            if (c.trim().isNotEmpty) {
              dynamicCategories.add(c.trim());
            }
          }
        }

        // Populate specific category lists from the "All" data
        for (var cat in dynamicCategories) {
          final categoryBooks = books
              .where((b) => b.categories
                  .any((c) => c.trim().toLowerCase() == cat.toLowerCase()))
              .toList();

          _categoryBooks[cat] = categoryBooks;
          _categoryLoading[cat] = false;
        }

        // Extract Trending and Bestselling
        _trendingBooks = books.where((b) => b.isTrending).toList();
        _bestsellingBooks = books.where((b) => b.isBestselling).toList();

        // Sort categories alphabetically
        final sortedCategories = dynamicCategories.toList()..sort();

        if (mounted) {
          setState(() {
            _categories = ["All", ...sortedCategories];
          });
        }
      } else {
        // Filter from "All" if available
        if (_categoryBooks.containsKey("All") &&
            _categoryBooks["All"]!.isNotEmpty) {
          books = _categoryBooks["All"]!
              .where((b) => b.categories
                  .any((c) => c.trim().toLowerCase() == category.toLowerCase()))
              .toList();
        } else {
          // Fallback if "All" isn't loaded yet, try loading "All" first
          await _fetchBooksForCategory("All");
          if (_categoryBooks.containsKey("All")) {
            books = _categoryBooks["All"]!
                .where((b) => b.categories.any(
                    (c) => c.trim().toLowerCase() == category.toLowerCase()))
                .toList();
          }
        }
      }

      if (mounted) {
        setState(() {
          _categoryBooks[category] = books;
          _categoryLoading[category] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _categoryLoading[category] = false);
        debugPrint("Error loading $category: $e");
      }
    }
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedCategory = category);
    if (category != "All") _fetchBooksForCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 25),
            _buildCategoryFilter(theme)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideX(begin: 0.2, end: 0),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _selectedCategory == "All"
                  ? Column(
                      children: [
                        if (_trendingBooks.isNotEmpty)
                          _buildHorizontalSection(
                              "Trending Now", _trendingBooks, theme),
                        if (_bestsellingBooks.isNotEmpty)
                          _buildHorizontalSection(
                              "Bestsellers", _bestsellingBooks, theme),
                        _buildAllCategoriesView(theme),
                      ],
                    )
                  : _buildSingleCategoryGridView(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: MediaQuery.of(context).padding.top + 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Good Morning,",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${widget.user.name.split(' ')[0]} 👋",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildCategoryFilter(ThemeData theme) {
    return SizedBox(
      height: 35,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () => _onCategorySelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: isSelected ? theme.primaryColor : theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : theme.dividerColor,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: theme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllCategoriesView(ThemeData theme) {
    // Show all valid categories (excluding 'All')
    final categoriesToShow = _categories.where((c) => c != "All").toList();

    if (categoriesToShow.isEmpty) {
      // If no categories yet (loading or empty), shows loading or empty state
      // We can return a loading indicator or just empty
      return const SizedBox();
    }

    return Column(
      key: const ValueKey("AllView"),
      children: categoriesToShow.asMap().entries.map((entry) {
        return _buildCategorySection(entry.value, theme)
            .animate(delay: (100 * entry.key).ms)
            .fadeIn()
            .slideX(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  Widget _buildSingleCategoryGridView(ThemeData theme) {
    final books = _categoryBooks[_selectedCategory] ?? [];
    final isLoading = _categoryLoading[_selectedCategory] ?? true;

    if (isLoading && books.isEmpty) {
      return Container(
        height: 400,
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: theme.primaryColor),
      );
    }

    if (books.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: Text("No books found.", style: theme.textTheme.bodyMedium),
      );
    }

    return Padding(
      key: ValueKey("Grid_$_selectedCategory"),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 20,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          return BookCard(book: books[index], isGrid: true)
              .animate(delay: (50 * index).ms)
              .fadeIn()
              .scale();
        },
      ),
    );
  }

  Widget _buildCategorySection(String category, ThemeData theme) {
    final books = _categoryBooks[category] ?? [];
    return _buildHorizontalSection(category, books, theme);
  }

  Widget _buildHorizontalSection(
      String title, List<BookModel> books, ThemeData theme) {
    final isLoading =
        _categoryLoading[_selectedCategory] ?? _categoryLoading["All"] ?? true;

    if (!isLoading && books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (title != "Trending Now" && title != "Bestsellers")
                GestureDetector(
                  onTap: () => _onCategorySelected(title),
                  child: Text(
                    "See All",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220, // Increased height for price/badge
          child: isLoading
              ? _buildLoadingList(theme)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: BookCard(book: books[index]),
                    );
                  },
                ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildLoadingList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          width: 110,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: theme.dividerColor, strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}

class BookCard extends StatelessWidget {
  final BookModel book;
  final bool isGrid;

  const BookCard({super.key, required this.book, this.isGrid = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        );
      },
      child: Container(
        width: isGrid ? null : 110,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      book.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              book.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: theme.cardTheme.color),
                            )
                          : Container(color: theme.cardTheme.color),
                      if (book.isPremium)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    book.authors.isNotEmpty ? book.authors.first : "Unknown",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
