class BookModel {
  final String id;
  final String title;
  final List<String> authors;
  final String description;
  final String thumbnailUrl;
  final double rating;
  final int pageCount;
  final String publisher;
  final String publishedDate;
  final String previewLink;
  final String epubLink;
  final List<String> categories;

  BookModel({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.thumbnailUrl,
    required this.rating,
    required this.pageCount,
    required this.publisher,
    required this.publishedDate,
    required this.previewLink,
    this.epubLink = '',
    required this.categories,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    final imageLinks = volumeInfo['imageLinks'] ?? {};
    
    // Handle authors list safely
    List<String> authorsList = [];
    if (volumeInfo['authors'] != null) {
      authorsList = List<String>.from(volumeInfo['authors']);
    } else {
      authorsList = ['Unknown Author'];
    }

    // Secure HTTPs for images
    String thumb = imageLinks['thumbnail'] ?? '';
    if (thumb.startsWith('http://')) {
      thumb = thumb.replaceFirst('http://', 'https://');
    }

    return BookModel(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'No Title',
      authors: authorsList,
      description: volumeInfo['description'] ?? 'No description available.',
      thumbnailUrl: thumb, // High res if available? Google api usually gives 'thumbnail'
      rating: (volumeInfo['averageRating'] ?? 0.0).toDouble(),
      pageCount: volumeInfo['pageCount'] ?? 0,
      publisher: volumeInfo['publisher'] ?? 'Unknown Publisher',
      publishedDate: volumeInfo['publishedDate'] ?? 'Unknown Date',
      previewLink: volumeInfo['previewLink'] ?? '',
      epubLink: '', // Google Books doesn't give direct EPUB usually
      categories: (volumeInfo['categories'] != null) 
          ? List<String>.from(volumeInfo['categories']) 
          : [],
    );
  }

  factory BookModel.fromGutenbergJson(Map<String, dynamic> json) {
    final formats = json['formats'] ?? {};
    
    // Find thumbnail (cover)
    String thumb = formats['image/jpeg'] ?? '';
    if (thumb.startsWith('http://')) {
      thumb = thumb.replaceFirst('http://', 'https://');
    }

    // Find readable link (prefer HTML, fallback to txt)
    String link = formats['text/html'] ?? formats['text/html; charset=utf-8'] ?? formats['text/plain'] ?? formats['text/plain; charset=utf-8'] ?? '';
    if (link.startsWith('http://')) {
      link = link.replaceFirst('http://', 'https://');
    }

    // Find EPUB link
    String epub = formats['application/epub+zip'] ?? '';
    if (epub.startsWith('http://')) {
      epub = epub.replaceFirst('http://', 'https://');
    }

    // Authors
    List<String> authorsList = [];
    if (json['authors'] != null) {
      for (var author in json['authors']) {
        authorsList.add(author['name'] ?? 'Unknown');
      }
    } else {
      authorsList = ['Unknown Author'];
    }

    return BookModel(
      id: json['id'].toString(),
      title: json['title'] ?? 'No Title',
      authors: authorsList,
      description: "A classic book from Project Gutenberg. Enjoy reading this public domain work.", // Gutendex doesn't provide descriptions
      thumbnailUrl: thumb,
      rating: 4.5, // Default rating for classics
      pageCount: 200, // Default page count
      publisher: 'Project Gutenberg',
      publishedDate: 'Classic',
      previewLink: link,
      epubLink: epub,
      categories: (json['subjects'] != null) 
          ? List<String>.from(json['subjects']) 
          : ['Classic'],
    );
  }
}
