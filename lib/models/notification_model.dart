class NotificationModel {
  final int id;
  final int? userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final String status;
  final String? scheduledAt;
  final String createdAt;
  final String updatedAt;

  NotificationModel({
    required this.id,
    this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.metadata,
    required this.isRead,
    required this.status,
    this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? json['user_id'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      metadata:
          json['metadata'] is Map<String, dynamic> ? json['metadata'] : null,
      isRead: json['is_read'] ?? false,
      status: json['status'] ?? '',
      scheduledAt: json['scheduled_at'],
      createdAt: json['createdAt'] ?? json['created_at'] ?? '',
      updatedAt: json['updatedAt'] ?? json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'metadata': metadata,
      'is_read': isRead,
      'status': status,
      'scheduled_at': scheduledAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  NotificationModel copyWith({
    int? id,
    int? userId,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? metadata,
    bool? isRead,
    String? status,
    String? scheduledAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
