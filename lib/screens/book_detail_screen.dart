import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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
  bool _hasAudio = false;
  bool _hasReading = false;
  bool _isAudioPreview = false;
  bool _isLoadingDetails = false;

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _isBookmarked = widget.book.isBookmarked;
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
    _initBookDetails();
  }

  Future<void> _initBookDetails() async {
    final user = await AuthService.getUser();
    final token = user?.token;
    if (_book.pdfUrl.isEmpty || token != null) _loadFullDetails(token);
  }

  Future<void> _loadFullDetails(String? token) async {
    setState(() => _isLoadingDetails = true);
    try {
      final fullBook = await ApiService.getBookById(_book.id, token: token);
      if (fullBook != null && mounted) {
        setState(() {
          _book = fullBook;
          if (token != null) _isBookmarked = fullBook.isBookmarked;
          _hasReading = _book.pdfUrl.isNotEmpty || _book.epubLink.isNotEmpty;
          _hasAudio = _book.audioUrl.isNotEmpty;
        });
      }

      if (token != null && mounted) {
        final data = await ApiService.getBookContent(widget.book.id, token);
        if (data != null && mounted) {
          final chapters = data['audio_chapters'] as List<dynamic>?;
          setState(() {
            _hasReading = data['file_url'] != null && data['file_url'].toString().isNotEmpty;
            _hasAudio = chapters != null && chapters.isNotEmpty;
            final isPremium = data['is_premium'] ?? false;
            _isAudioPreview = !isPremium;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading full details: $e");
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleBookmark() async {
    setState(() => _isLoadingBookmark = true);
    try {
      final user = await AuthService.getUser();
      if (user != null && user.token.isNotEmpty) {
        if (mounted) {
          await ApiService.toggleBookmark(_book.id, user.token);
          setState(() {
            _isBookmarked = !_isBookmarked;
            _book = _book.copyWith(isBookmarked: _isBookmarked);
            _isLoadingBookmark = false;
          });
        }
      } else {
        if (mounted) {
           setState(() => _isLoadingBookmark = false);
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to bookmark")));
        }
      }
    } catch (e) {
       if (mounted) setState(() => _isLoadingBookmark = false);
    }
  }

  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildEliteBackground(theme),
          _isLoadingDetails
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFBBF24)))
              : RefreshIndicator(
                  onRefresh: _initBookDetails,
                  displacement: 80,
                  color: const Color(0xFFFBBF24),
                  backgroundColor: const Color(0xFF1E1E2C),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(), // Important for pull-to-refresh
                    slivers: [
                      _buildEliteAppBar(context, theme, size),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _buildEliteTitleSection(theme),
                              const SizedBox(height: 24),
                              _buildEliteStatsGrid(theme),
                              const SizedBox(height: 32),
                              _buildEliteDescription(theme),
                              if (_book.highlights.isNotEmpty) ...[
                                const SizedBox(height: 32),
                                _buildEliteHighlights(theme),
                              ],
                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          if (!_isLoadingDetails) _buildEliteBottomActions(context, theme),
        ],
      ),
    );
  }

  Widget _buildEliteBackground(ThemeData theme) {
    return Positioned.fill(
      child: Stack(
        children: [
          if (_book.thumbnailUrl.isNotEmpty)
            Image.network(_book.thumbnailUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
          else
            Container(color: theme.primaryColor),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.8), Colors.black],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEliteAppBar(BuildContext context, ThemeData theme, Size size) {
    // Parallax logic for image (Clamped to prevent assertion errors on overscroll)
    final double opacity = (1.0 - (_scrollOffset / 200)).clamp(0.0, 1.0);
    final double scale = 1.0 + (_scrollOffset / size.height).clamp(0, 0.2);

    return SliverAppBar(
      expandedHeight: size.height * 0.45,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildGlassIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildGlassIconButton(
            icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: _isBookmarked ? const Color(0xFFFBBF24) : Colors.white,
            isLoading: _isLoadingBookmark,
            onTap: _toggleBookmark,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: Hero(
                tag: _book.id,
                child: Container(
                  margin: const EdgeInsets.only(top: 80),
                  height: 260, width: 175,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 40, offset: const Offset(0, 20)),
                      BoxShadow(color: theme.primaryColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _book.thumbnailUrl.isNotEmpty 
                      ? Image.network(_book.thumbnailUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey[900], child: const Icon(Icons.book, size: 50, color: Colors.grey)),
                  ),
                ),
              ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack).fadeIn(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap, Color color = Colors.white, bool isLoading = false}) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 44, width: 44,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Center(
              child: isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(icon, color: color, size: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEliteTitleSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_book.title, style: theme.textTheme.headlineMedium).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(_book.authors.join(', '), style: theme.textTheme.titleSmall), // Using Inter for Author/Subtitle
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFBBF24).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(_book.categoryName, style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ],
        ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.05, end: 0),
      ],
    );
  }

  Widget _buildEliteStatsGrid(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildThinStat("RATING", "${_book.rating}"),
          _buildVerticalStatDivider(),
          _buildThinStat("LANGUAGE", _book.language.toUpperCase()),
          _buildVerticalStatDivider(),
          _buildThinStat("PRICING", _book.isPremium ? "ELITE" : "FREE"),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildThinStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVerticalStatDivider() => Container(width: 1, height: 20, color: Colors.white.withOpacity(0.05));

  Widget _buildEliteDescription(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("About this Book", style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(
          _book.description,
          maxLines: _isDescriptionExpanded ? null : 4, overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70, height: 1.6),
        ),
        GestureDetector(
          onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_isDescriptionExpanded ? "Show Less" : "Read More", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ],
    ).animate(delay: 600.ms).fadeIn();
  }

  Widget _buildEliteHighlights(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFFBBF24).withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CORE HIGHLIGHTS", style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text(_book.highlights, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.white70)),
        ],
      ),
    ).animate(delay: 800.ms).fadeIn().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildEliteBottomActions(BuildContext context, ThemeData theme) {
    return Positioned(
      bottom: 32, left: 32, right: 32,
      child: Row(
        children: [
          if (_hasReading) Expanded(child: _StartReadingButton(book: _book, theme: theme)),
          if (_hasReading && _hasAudio) const SizedBox(width: 16),
          if (_hasAudio) _buildListenAction(theme),
        ],
      ).animate().slideY(begin: 1, end: 0, duration: 800.ms, curve: Curves.easeOutQuart),
    );
  }

  Widget _buildListenAction(ThemeData theme) {
    return Container(
      height: 56, width: 56,
      decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: InkWell(
        onTap: _handleAudio,
        borderRadius: BorderRadius.circular(18),
        child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFBBF24), size: 32),
      ),
    );
  }

  Future<void> _handleAudio() async {
    // 1. Get fresh user data to ensure the premium status is up-to-date
    final user = await AuthService.getUser();
    final bool userIsPremium = user?.isUserPremium ?? false;

    // 2. Logic: The content is locked only if _isAudioPreview is true 
    // AND the user does not have a global premium subscription.
    // In your API, _isAudioPreview is the opposite of data['is_premium'].
    final bool isContentLocked = _isAudioPreview && !userIsPremium;

    if (isContentLocked) {
      final success = await Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const SubscriptionScreen())
      );
      
      if (success == true) {
        final updatedUser = await AuthService.getUser();
        _loadFullDetails(updatedUser?.token);
      }
      return;
    }

    // 3. Flow: Content is unlocked (either free or user is premium)
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => AudioPlayerScreen(book: _book))
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFFFBBF24).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRead,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        child: Text(_isLoading ? "PREPARING..." : "START READING", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
      ),
    );
  }

  Future<void> _handleRead() async {
    setState(() => _isLoading = true);
    try {
      final cachedUser = await AuthService.getUser();
      final token = cachedUser?.token;
      if (token == null || token.isEmpty) throw Exception("Please login");

      LoginModel user;
      try { user = await ApiService.getUserProfile(token); await AuthService.saveUser(user); } catch (e) { user = cachedUser!; }

      if (widget.book.isPremium && !user.isUserPremium) {
        final success = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen()));
        if (success == true) return _handleRead();
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final readData = await ApiService.getBookContent(widget.book.id, token);
      if (readData != null && mounted) {
        String fileUrl = readData['file_url'] ?? '';
        final fileType = readData['file_type'] ?? '';
        final bool isPremium = readData['is_premium'] ?? false;
        if (fileType == 'epub' && !isPremium) {
           final success = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen()));
           if (success == true) return _handleRead();
           if (mounted) setState(() => _isLoading = false);
           return;
        }
        if (fileUrl.isNotEmpty && !fileUrl.startsWith('http')) fileUrl = "${ApiService.baseUrl}/$fileUrl";

        Navigator.push(context, MaterialPageRoute(builder: (context) => ReadingScreen(
          bookId: widget.book.id.toString(),
          title: widget.book.title,
          url: fileUrl,
          isPdf: fileType == 'pdf',
          isEpub: fileType == 'epub',
          isPreview: !isPremium,
          token: token,
        )));
      }
    } catch (e) {
      debugPrint("Read Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
