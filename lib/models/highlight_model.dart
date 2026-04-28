
class HighlightModel {
  final int? id;
  final int? userId;
  final String bookId;
  final String text;
  final String color;
  final int pageNumber;
  final double rectX;
  final double rectY;
  final double rectWidth;
  final double rectHeight;
  final String? cfi; // Added for EPUB support
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HighlightModel({
    this.id,
    this.userId,
    required this.bookId,
    required this.text,
    required this.color,
    required this.pageNumber,
    required this.rectX,
    required this.rectY,
    required this.rectWidth,
    required this.rectHeight,
    this.cfi,
    this.createdAt,
    this.updatedAt,
  });

  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    return HighlightModel(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id']?.toString() ?? '',
      text: json['text'] ?? '',
      color: json['color'] ?? '#FFFF00',
      pageNumber: json['page_number'] ?? json['page'] ?? 0,
      rectX: (json['rect_x'] as num?)?.toDouble() ?? 0.0,
      rectY: (json['rect_y'] as num?)?.toDouble() ?? 0.0,
      rectWidth: (json['rect_width'] as num?)?.toDouble() ?? 0.0,
      rectHeight: (json['rect_height'] as num?)?.toDouble() ?? 0.0,
      cfi: json['cfi']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'page': pageNumber,
      'color': color,
      'rect_x': rectX,
      'rect_y': rectY,
      'rect_width': rectWidth,
      'rect_height': rectHeight,
      'cfi': cfi,
    };
  }
}
