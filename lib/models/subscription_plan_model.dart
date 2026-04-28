import 'dart:convert';

class SubscriptionPlanModel {
  final int id;
  final String name;
  final String price;
  final String planType;
  final int durationMonths;
  final String description;
  final List<String> features;
  final int deviceLimit;
  final int bookReadLimit;
  final String status;
  final bool isAdFree;

  SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.planType,
    required this.durationMonths,
    required this.description,
    required this.features,
    required this.deviceLimit,
    required this.bookReadLimit,
    required this.status,
    required this.isAdFree,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    List<String> featuresList = [];
    if (json['features'] != null) {
      try {
        if (json['features'] is String) {
          featuresList = List<String>.from(jsonDecode(json['features']));
        } else if (json['features'] is List) {
          featuresList = List<String>.from(json['features']);
        }
      } catch (e) {
        featuresList = [];
      }
    }

    return SubscriptionPlanModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price']?.toString() ?? '0',
      planType: json['plan_type'] ?? '',
      durationMonths: json['duration_months'] ?? 0,
      description: json['description'] ?? '',
      features: featuresList,
      deviceLimit: json['device_limit'] ?? 0,
      bookReadLimit: json['book_read_limit'] ?? 0,
      status: json['status'] ?? '',
      isAdFree: json['is_ad_free'] ?? false,
    );
  }
}
