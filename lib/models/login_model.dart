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
    required this.token,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      id: json['id'],
      userType: json['user_type'] ?? '',
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      additionalPhone: json['additional_phone'] ?? '',
      profile: ProfileData.fromJson(json['profile'] ?? {}),
      isActive: json['is_active'] ?? false,
      isVerified: json['is_verified'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      token: json['token'] ?? '',
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
