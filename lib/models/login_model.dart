class LoginModel {
  final int id;
  final String userType;
  final String name;
  final String email;
  final String phone;
  final String additionalPhone;
  final ProfileData profile;
  final bool isActive;
  final bool isVerified;
  final String createdAt;
  final String updatedAt;
  final String subscriptionStatus;
  final String subscriptionPlan;
  final String subscriptionEndDate;
  final String token;

  LoginModel({
    required this.id,
    required this.userType,
    required this.name,
    required this.email,
    required this.phone,
    required this.additionalPhone,
    required this.profile,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    required this.subscriptionStatus,
    required this.subscriptionPlan,
    required this.subscriptionEndDate,
    required this.token,
  });

  bool get isUserPremium =>
      subscriptionStatus == 'active' || subscriptionStatus == 'premium';

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      id: json['id'] is int
          ? json['id']
          : (json['user_id'] is int
              ? json['user_id']
              : int.tryParse(json['id']?.toString() ??
                      json['user_id']?.toString() ??
                      '0') ??
                  0),
      userType:
          json['user_type']?.toString() ?? json['userType']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      additionalPhone: json['additional_phone']?.toString() ??
          json['additionalPhone']?.toString() ??
          '',
      profile: ProfileData.fromJson(json['profile'] ?? {}),
      isActive: json['is_active'] == true || json['isActive'] == true,
      isVerified: json['is_verified'] == true || json['isVerified'] == true,
      createdAt: (json['created_at'] ?? json['createdAt'])?.toString() ?? '',
      updatedAt: (json['updated_at'] ?? json['updatedAt'])?.toString() ?? '',
      subscriptionStatus:
          (json['subscription_status'] ?? json['subscriptionStatus'])
                  ?.toString() ??
              '',
      subscriptionPlan:
          (json['subscription_plan'] ?? json['subscriptionPlan'])?.toString() ??
              '',
      subscriptionEndDate:
          (json['subscription_end_date'] ?? json['subscriptionEndDate'])
                  ?.toString() ??
              '',
      token: (json['token']?.toString().isNotEmpty == true)
          ? json['token'].toString()
          : (json['accessToken']?.toString().isNotEmpty == true)
              ? json['accessToken'].toString()
              : '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_type': userType,
      'name': name,
      'email': email,
      'phone': phone,
      'additional_phone': additionalPhone,
      'profile': profile.toJson(),
      'is_active': isActive,
      'is_verified': isVerified,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'subscription_status': subscriptionStatus,
      'subscription_plan': subscriptionPlan,
      'subscription_end_date': subscriptionEndDate,
      'token': token,
    };
  }
}

class ProfileData {
  final String url;
  final String initials;
  final String publicId;

  ProfileData({
    required this.url,
    required this.initials,
    required this.publicId,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      url: json['url'] ?? '',
      initials: json['initials'] ?? '',
      publicId: json['public_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'initials': initials,
      'public_id': publicId,
    };
  }
}
