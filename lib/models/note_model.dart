class NoteModel {
  final int id;
  final int userId;
  final String title;
  final String content;
  final String? chapterName;
  final String createdAt;
  final String updatedAt;

  NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.chapterName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? json['user_id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      chapterName: json['chapterName'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'chapterName': chapterName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
