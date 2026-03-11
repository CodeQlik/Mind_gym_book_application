class UserRegisterResponse {
  final bool success;
  final String message;
  final UserModel data;

  UserRegisterResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory UserRegisterResponse.fromJson(Map<String, dynamic> json) {
    return UserRegisterResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: UserModel.fromJson(json['data'] ?? {}),
    );
  }
}

class UserModel {
  final List<dynamic> addressIds;
  final bool isVerified;
  final String subscriptionStatus;
  final String subscriptionPlan;
  final int id;
  final String name;
  final String email;
  final String phone;
  final String additionalPhone;
  final String userType;
  final UserProfile? profile;
  final bool isActive;
  final String updatedAt;
  final String createdAt;

  UserModel({
    required this.addressIds,
    required this.isVerified,
    required this.subscriptionStatus,
    required this.subscriptionPlan,
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.additionalPhone,
    required this.userType,
    required this.profile,
    required this.isActive,
    required this.updatedAt,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      addressIds: json['address_ids'] ?? [],
      isVerified: json['is_verified'] ?? false,
      subscriptionStatus: json['subscription_status'] ?? '',
      subscriptionPlan: json['subscription_plan'] ?? '',
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      additionalPhone: json['additional_phone'] ?? '',
      userType: json['user_type'] ?? '',
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'])
          : null,
      isActive: json['is_active'] ?? false,
      updatedAt: json['updatedAt'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class UserProfile {
  final String url;
  final String publicId;
  final String initials;

  UserProfile({
    required this.url,
    required this.publicId,
    required this.initials,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      url: json['url'] ?? '',
      publicId: json['public_id'] ?? '',
      initials: json['initials'] ?? '',
    );
  }
}
