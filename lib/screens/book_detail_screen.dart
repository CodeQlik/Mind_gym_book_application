import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart'; // Import AuthService
import '../models/login_model.dart';
import 'reading_screen.dart';
import 'audio_player_screen.dart';
import 'subscription_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late BookModel _book;
  late bool _isBookmarked;
  bool _isLoadingBookmark = false;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _isBookmarked = widget.book.isBookmarked;

    _initBookDetails();
  }

  Future<void> _initBookDetails() async {
    final user = await AuthService.getUser();
    final token = user?.token;

    // If PDF is missing OR we just want to ensure we have the latest bookmark status from server
    // (Especially important if the previous screen didn't have the latest status)
    if (_book.pdfUrl.isEmpty || token != null) {
      _loadFullDetails(token);
    }
  }

  Future<void> _loadFullDetails(String? token) async {
    setState(() => _isLoadingDetails = true);
    try {
      final fullBook = await ApiService.getBookById(_book.id, token: token);
      if (fullBook != null && mounted) {
        setState(() {
          _book = fullBook;
          // Sync local bookmark state with the fresh data from server
          if (token != null) {
            _isBookmarked = fullBook.isBookmarked;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading full details: $e");
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _toggleBookmark() async {
    // Optimistic update
    setState(() {
      _isLoadingBookmark = true;
    });

    try {
      final user = await AuthService.getUser();
      if (user != null && user.token.isNotEmpty) {
        // Call API
        final newState = await ApiService.toggleBookmark(_book.id, user.token);
        debugPrint("BookDetailScreen: New bookmark state from API: $newState");

        if (mounted) {
          setState(() {
            _isBookmarked = newState;
            _book = _book.copyWith(isBookmarked: newState);
            _isLoadingBookmark = false;
          });

          ScaffoldMessenger.of(context).clearSnackBars(); // Clear existing
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isBookmarked
                  ? "Added to bookmarks"
                  : "Removed from bookmarks"),
              duration: const Duration(seconds: 1),
              backgroundColor: _isBookmarked ? Colors.green : Colors.redAccent,
            ),
          );
        }
      } else {
        // User not logged in
        if (mounted) {
          setState(() => _isLoadingBookmark = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please login to bookmark books")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error toggling bookmark: $e");
      if (mounted) {
        setState(() => _isLoadingBookmark = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update bookmark")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Image (Blurred)
          Positioned.fill(
            child: _book.thumbnailUrl.isNotEmpty
                ? Image.network(
                    _book.thumbnailUrl,
                    fit: BoxFit.cover,
                  )
                : Container(color: theme.primaryColor.withOpacity(0.5)),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black
                    .withOpacity(0.5), // Darker overlay for better contrast
              ),
            ),
          ),

          SafeArea(
            child: _isLoadingDetails
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : Column(
                    children: [
                      // App Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildIconButton(
                              context,
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.pop(context),
                            ),
                            Text(
                              "Book Details",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            _buildIconButton(
                              context,
                              icon: _isBookmarked
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: _isBookmarked
                                  ? theme.primaryColor
                                  : Colors.white,
                              isLoading: _isLoadingBookmark,
                              onTap: _toggleBookmark,
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              // Book Cover (Hero)
                              Hero(
                                tag: _book.id,
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 280,
                                      width: 190,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.4),
                                            blurRadius: 25,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                        image: _book.thumbnailUrl.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                    _book.thumbnailUrl),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: _book.thumbnailUrl.isEmpty
                                          ? const Center(
                                              child: Icon(Icons.book,
                                                  size: 50, color: Colors.grey),
                                            )
                                          : null,
                                    ),
                                    if (_book.isPremium)
                                      Positioned(
                                        top: 15,
                                        right: 15,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.amber,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.star_rounded,
                                                  color: Colors.white,
                                                  size: 16),
                                              SizedBox(width: 4),
                                              Text("PREMIUM",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Title & Author
                              Text(
                                _book.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 500.ms)
                                  .slideY(begin: 0.2, end: 0),
                              const SizedBox(height: 8),
                              Text(
                                _book.authors.join(", "),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                                  .animate(delay: 100.ms)
                                  .fadeIn()
                                  .slideY(begin: 0.2, end: 0),

                              const SizedBox(height: 30),

                              // Info Row (Rating, Pages, Language)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildInfoItem(
                                        "Rating", "${_book.rating} ⭐"),
                                    _buildDivider(),
                                    _buildInfoItem(
                                        "Pages", "${_book.pageCount}"),
                                    _buildDivider(),
                                    _buildInfoItem(
                                        "Language",
                                        _book.previewPages > 0
                                            ? "PREVIEW"
                                            : "FULL"),
                                  ],
                                ),
                              ).animate(delay: 200.ms).fadeIn().scale(),

                              const SizedBox(height: 30),

                              // Description
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Description",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ).animate(delay: 300.ms).fadeIn(),
                              const SizedBox(height: 12),
                              Text(
                                _book.description,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withOpacity(0.7),
                                  height: 1.6,
                                ),
                              ).animate(delay: 350.ms).fadeIn(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isLoadingDetails
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AudioPlayerScreen(book: _book),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Icon(Icons.headphones_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 60,
                      child: _StartReadingButton(book: _book, theme: theme),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 500.ms).slideY(begin: 1, end: 0).fadeIn(),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }
}

class _StartReadingButton extends StatefulWidget {
  final BookModel book;
  final ThemeData theme;

  const _StartReadingButton({required this.book, required this.theme});

  @override
  State<_StartReadingButton> createState() => _StartReadingButtonState();
}

class _StartReadingButtonState extends State<_StartReadingButton> {
  bool _isLoading = false;

  Future<void> _handleRead() async {
    setState(() => _isLoading = true);
    debugPrint(
        "BookDetailScreen: _handleRead clicked for book ${widget.book.id}");
    try {
      final cachedUser = await AuthService.getUser();
      final token = cachedUser?.token;

      if (token == null || token.isEmpty) {
        throw Exception("Please login to continue");
      }

      // 1. Always fetch latest profile to check subscription status as requested
      debugPrint("BookDetailScreen: Refreshing user profile...");
      LoginModel user;
      try {
        user = await ApiService.getUserProfile(token);
        await AuthService.saveUser(user);
        debugPrint(
            "BookDetailScreen: Profile refreshed. Status: ${user.subscriptionStatus}");
      } catch (e) {
        debugPrint(
            "BookDetailScreen: Profile refresh failed, using cached: $e");
        user = cachedUser!;
      }

      // 2. If book is premium, check if user has active subscription
      if (widget.book.isPremium) {
        final bool isAlreadyPremium = user.isUserPremium;
        debugPrint("BookDetailScreen: Is User premium? $isAlreadyPremium");

        if (!isAlreadyPremium) {
          debugPrint(
              "BookDetailScreen: User not premium, opening SubscriptionScreen");
          final success = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
          );

          // If they returned from subscription, we should check again or they might have paid
          if (success == true) {
            debugPrint(
                "BookDetailScreen: User returned from successful subscription. Refreshing...");
            return _handleRead(); // Recursive call to check again
          } else {
            if (mounted) setState(() => _isLoading = false);
            return;
          }
        }
      }

      if (token.isNotEmpty) {
        debugPrint(
            "BookDetailScreen: Calling ApiService.readBook for ${widget.book.id}");
        final readData = await ApiService.readBook(widget.book.id, token);

        if (readData != null) {
          debugPrint("BookDetailScreen: readBook raw data: $readData");
          final dataObj = readData;
          final fileData = dataObj['file_data'];

          String pdfUrl = '';
          String epubLink = '';

          if (fileData != null) {
            if (fileData['type'] == 'pdf') {
              pdfUrl = fileData['url'] ?? '';
            } else if (fileData['type'] == 'epub') {
              epubLink = fileData['url'] ?? '';
            }
          } else {
            pdfUrl = dataObj['pdf_url'] ?? dataObj['pdf_file']?['url'] ?? '';
            epubLink = dataObj['epub_url'] ?? '';
          }

          // Re-prefix if relative and from mindgym
          if (pdfUrl.isNotEmpty && !pdfUrl.startsWith('http')) {
            pdfUrl = "${ApiService.baseUrl}/$pdfUrl";
          }
          if (epubLink.isNotEmpty && !epubLink.startsWith('http')) {
            epubLink = "${ApiService.baseUrl}/$epubLink";
          }

          debugPrint(
              "BookDetailScreen: Resolved URLs - PDF: $pdfUrl, EPUB: $epubLink");

          final bool isPreview = dataObj['isPreview'] ?? false;

          if (mounted) {
            if (epubLink.isNotEmpty) {
              debugPrint(
                  "BookDetailScreen: Navigating to ReadingScreen (EPUB)");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReadingScreen(
                    url: epubLink,
                    title: widget.book.title + (isPreview ? " (Preview)" : ""),
                    isEpub: true,
                    isPreview: isPreview,
                    token: token,
                  ),
                ),
              );
              setState(() => _isLoading = false);
              return;
            } else if (pdfUrl.isNotEmpty) {
              debugPrint("BookDetailScreen: Navigating to ReadingScreen (PDF)");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReadingScreen(
                    url: pdfUrl,
                    title: widget.book.title + (isPreview ? " (Preview)" : ""),
                    isPdf: true,
                    isPreview: isPreview,
                    token: token,
                  ),
                ),
              );
              setState(() => _isLoading = false);
              return;
            }
          }
        }
      } else {
        debugPrint(
            "BookDetailScreen: Token is null or empty, skipping readBook API");
      }

      // Fallback to existing logic if readBook fails or user is not logged in
      if (!mounted) return;

      debugPrint(
          "BookDetailScreen: Fallback logic - PDF url: ${widget.book.pdfUrl}, EPUB url: ${widget.book.epubLink}, Preview url: ${widget.book.previewLink}");

      // 1. Check for PDF (Direct URL)
      if (widget.book.pdfUrl.isNotEmpty) {
        debugPrint(
            "BookDetailScreen: Fallback - Navigating to ReadingScreen (PDF)");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReadingScreen(
              url: widget.book.pdfUrl,
              title: widget.book.title,
              isPdf: true,
              token: token,
            ),
          ),
        );
      }
      // 2. Check for EPUB Link (Native Reading)
      else if (widget.book.epubLink.isNotEmpty) {
        debugPrint(
            "BookDetailScreen: Fallback - Navigating to ReadingScreen (EPUB)");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReadingScreen(
              url: widget.book.epubLink,
              title: widget.book.title,
              isEpub: true,
              token: token,
            ),
          ),
        );
      }
      // 3. Check for Preview Link (WebView)
      else if (widget.book.previewLink.isNotEmpty) {
        debugPrint(
            "BookDetailScreen: Fallback - Navigating to ReadingScreen (WEBVIEW)");
        String url = widget.book.previewLink;
        if (url.startsWith('http://')) {
          url = url.replaceFirst('http://', 'https://');
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReadingScreen(
              url: url,
              title: widget.book.title,
              isEpub: false,
              token: token,
            ),
          ),
        );
      } else {
        debugPrint("BookDetailScreen: All fallback checks failed");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No preview available for this book')),
        );
      }
    } catch (e) {
      debugPrint("BookDetailScreen Error catch: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load book: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleRead,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : const Text(
              "Start Reading",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
    );
  }
}
