import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/book_model.dart';
import 'reading_screen.dart';

class BookDetailScreen extends StatelessWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
     final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Image (Blurred)
          Positioned.fill(
            child: book.thumbnailUrl.isNotEmpty
                ? Image.network(
                    book.thumbnailUrl,
                    fit: BoxFit.cover,
                  )
                : Container(color: theme.primaryColor.withOpacity(0.5)),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withOpacity(0.5), // Darker overlay for better contrast
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        icon: Icons.bookmark_border_rounded,
                        onTap: () {},
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
                          tag: book.id,
                          child: Container(
                            height: 280,
                            width: 190,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              image: book.thumbnailUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(book.thumbnailUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: book.thumbnailUrl.isEmpty
                                ? const Center(
                                    child: Icon(Icons.book, size: 50, color: Colors.grey),
                                  )
                                : null,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Title & Author
                        Text(
                          book.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          book.authors.join(", "),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 30),

                        // Info Row (Rating, Pages, Language)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInfoItem("Rating", "${book.rating} ⭐"),
                              _buildDivider(),
                              _buildInfoItem("Pages", "${book.pageCount}"),
                              _buildDivider(),
                              _buildInfoItem("Language", "ENG"),
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
                          book.description,
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              // 1. Check for EPUB Link (Native Reading)
              if (book.epubLink.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReadingScreen(
                      url: book.epubLink,
                      title: book.title,
                      isEpub: true,
                    ),
                  ),
                );
              } 
              // 2. Check for Preview Link (WebView)
              else if (book.previewLink.isNotEmpty) {
                // Ensure the URL is HTTPS
                String url = book.previewLink;
                if (url.startsWith('http://')) {
                  url = url.replaceFirst('http://', 'https://');
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReadingScreen(
                      url: url,
                      title: book.title,
                      isEpub: false,
                    ),
                  ),
                );
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No preview available for this book')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor, // Use theme primary
              foregroundColor: Colors.white,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Start Reading",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ).animate(delay: 500.ms).slideY(begin: 1, end: 0).fadeIn(),
    );
  }

  Widget _buildIconButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
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
