class AppUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? companyName;
  final String userType;
  final String city;
  final String role;
  final bool isVerified;

  AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.companyName,
    required this.userType,
    required this.city,
    required this.role,
    required this.isVerified,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      companyName: json['company_name'],
      userType: json['user_type'] ?? '',
      city: json['city'] ?? '',
      role: json['role'] ?? '',
      isVerified: json['is_verified'] ?? false,
    );
  }

  String get displayName => companyName ?? '$firstName $lastName';
}
