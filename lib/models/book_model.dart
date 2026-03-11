class BookModel {
  final String id;
  final String title;
  final String slug;
  final List<String> authors;
  final String description;
  final String thumbnailUrl;
  final String coverImageUrl;
  final double rating;
  final int pageCount;
  final String publisher;
  final String publishedDate;
  final String previewLink;
  final String epubLink;
  final String pdfUrl;
  final List<String> categories;
  final bool isBookmarked;
  final bool isPremium;
  final String price;
  final String originalPrice;
  final bool isBestselling;
  final bool isTrending;
  final int previewPages;
  final String readUrl;
  final String condition;
  final int stock;
  final String highlights;
  final int categoryId;
  final bool isActive;
  final String isbn;
  final String language;
  final String otherDescription;
  final String dimensions;
  final String weight;
  final String categoryName;

  BookModel({
    required this.id,
    required this.title,
    this.slug = '',
    required this.authors,
    required this.description,
    required this.thumbnailUrl,
    this.coverImageUrl = '',
    required this.rating,
    required this.pageCount,
    required this.publisher,
    required this.publishedDate,
    required this.previewLink,
    this.epubLink = '',
    this.pdfUrl = '',
    required this.categories,
    this.isBookmarked = false,
    this.isPremium = false,
    this.price = '',
    this.originalPrice = '',
    this.isBestselling = false,
    this.isTrending = false,
    this.previewPages = 0,
    this.readUrl = '',
    this.condition = '',
    this.stock = 0,
    this.highlights = '',
    this.categoryId = 0,
    this.isActive = true,
    this.isbn = '',
    this.language = '',
    this.otherDescription = '',
    this.dimensions = '',
    this.weight = '',
    this.categoryName = '',
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
      thumbnailUrl:
          thumb, // High res if available? Google api usually gives 'thumbnail'
      rating: (volumeInfo['averageRating'] ?? 0.0).toDouble(),
      pageCount: volumeInfo['pageCount'] ?? 0,
      publisher: volumeInfo['publisher'] ?? 'Unknown Publisher',
      publishedDate: volumeInfo['publishedDate'] ?? 'Unknown Date',
      previewLink: volumeInfo['previewLink'] ?? '',
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
    String link = formats['text/html'] ??
        formats['text/html; charset=utf-8'] ??
        formats['text/plain'] ??
        formats['text/plain; charset=utf-8'] ??
        '';
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
      description:
          "A classic book from Project Gutenberg. Enjoy reading this public domain work.", // Gutendex doesn't provide descriptions
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

  factory BookModel.fromBookmarkedJson(Map<String, dynamic> json) {
    final bookData = json['book'] ?? {};
    return BookModel.fromMindGymJson(bookData).copyWith(isBookmarked: true);
  }

  factory BookModel.fromMindGymJson(Map<String, dynamic> json) {
    // Authors
    List<String> authorsList = [];
    if (json['author'] != null) {
      authorsList.add(json['author']);
    } else {
      authorsList.add('Unknown Author');
    }

    // Categories
    List<String> categoriesList = [];
    String categoryName = '';
    if (json['category'] != null) {
      if (json['category'] is Map) {
        categoryName = json['category']['name'] ?? '';
      } else {
        categoryName = json['category'].toString();
      }
      if (categoryName.isNotEmpty) {
        categoriesList.add(categoryName);
      }
    }

    String pdfUrl = '';
    String epubLink = '';

    if (json['file_data'] != null && json['file_data'] is Map) {
      final fileData = json['file_data'];
      if (fileData['type'] == 'pdf') {
        pdfUrl = fileData['url'] ?? '';
      } else if (fileData['type'] == 'epub') {
        epubLink = fileData['url'] ?? '';
      }
    }

    String thumbUrl = '';
    if (json['thumbnail'] != null) {
      if (json['thumbnail'] is Map) {
        thumbUrl = json['thumbnail']['url'] ?? '';
      } else {
        thumbUrl = json['thumbnail'].toString();
      }
    }

    String coverUrl = '';
    if (json['cover_image'] != null) {
      if (json['cover_image'] is Map) {
        coverUrl = json['cover_image']['url'] ?? '';
      } else {
        coverUrl = json['cover_image'].toString();
      }
    }

    return BookModel(
      id: json['id'].toString(),
      title: json['title'] ?? 'No Title',
      slug: json['slug'] ?? '',
      authors: authorsList,
      description: json['description'] ?? 'No description available.',
      thumbnailUrl: thumbUrl,
      coverImageUrl: coverUrl,
      rating: 4.5, // Default
      pageCount: json['page_count'] ?? 0,
      publisher: 'MindGym',
      publishedDate: json['published_date'] ?? '',
      previewLink: '',
      epubLink: epubLink,
      pdfUrl: pdfUrl,
      categories: categoriesList,
      isBookmarked: json['isBookmarked'] ?? json['is_read'] ?? false,
      isPremium: json['is_premium'] ?? false,
      price: json['price']?.toString() ?? '',
      originalPrice: json['original_price']?.toString() ?? '',
      isBestselling: json['is_bestselling'] ?? false,
      isTrending: json['is_trending'] ?? false,
      previewPages: json['previewPages'] ?? 0,
      readUrl: json['read_url'] ?? '',
      condition: json['condition'] ?? '',
      stock: json['stock'] ?? 0,
      highlights: json['highlights'] ?? '',
      categoryId: json['category_id'] ?? 0,
      isActive: json['is_active'] ?? true,
      isbn: json['isbn'] ?? '',
      language: json['language'] ?? '',
      otherDescription: json['otherdescription'] ?? '',
      dimensions: json['dimensions'] ?? '',
      weight: json['weight']?.toString() ?? '',
      categoryName: categoryName,
    );
  }

  BookModel copyWith({
    String? id,
    String? title,
    String? slug,
    List<String>? authors,
    String? description,
    String? thumbnailUrl,
    String? coverImageUrl,
    double? rating,
    int? pageCount,
    String? publisher,
    String? publishedDate,
    String? previewLink,
    String? epubLink,
    String? pdfUrl,
    List<String>? categories,
    bool? isBookmarked,
    bool? isPremium,
    String? price,
    String? originalPrice,
    bool? isBestselling,
    bool? isTrending,
    int? previewPages,
    String? readUrl,
    String? condition,
    int? stock,
    String? highlights,
    int? categoryId,
    bool? isActive,
    String? isbn,
    String? language,
    String? otherDescription,
    String? dimensions,
    String? weight,
    String? categoryName,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      authors: authors ?? this.authors,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      rating: rating ?? this.rating,
      pageCount: pageCount ?? this.pageCount,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      previewLink: previewLink ?? this.previewLink,
      epubLink: epubLink ?? this.epubLink,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      categories: categories ?? this.categories,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isPremium: isPremium ?? this.isPremium,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      isBestselling: isBestselling ?? this.isBestselling,
      isTrending: isTrending ?? this.isTrending,
      previewPages: previewPages ?? this.previewPages,
      readUrl: readUrl ?? this.readUrl,
      condition: condition ?? this.condition,
      stock: stock ?? this.stock,
      highlights: highlights ?? this.highlights,
      categoryId: categoryId ?? this.categoryId,
      isActive: isActive ?? this.isActive,
      isbn: isbn ?? this.isbn,
      language: language ?? this.language,
      otherDescription: otherDescription ?? this.otherDescription,
      dimensions: dimensions ?? this.dimensions,
      weight: weight ?? this.weight,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}
