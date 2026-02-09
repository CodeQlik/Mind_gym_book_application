class UserModel {
final int id;
final String name;
final String email;
final String phone;
final String additionalPhone;
final String profileUrl;


UserModel({
required this.id,
required this.name,
required this.email,
required this.phone,
required this.additionalPhone,
required this.profileUrl,
});


factory UserModel.fromJson(Map<String, dynamic> json) {
return UserModel(
id: json['id'],
name: json['name'],
email: json['email'],
phone: json['phone'],
additionalPhone: json['additional_phone'] ?? '',
profileUrl: json['profile'] != null ? json['profile']['url'] ?? '' : '',
);
}
}