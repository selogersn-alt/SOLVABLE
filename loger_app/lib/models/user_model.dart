class AppUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? companyName;
  final String role;
  final bool isVerified;
  final String? profilePicture;

  AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.companyName,
    required this.role,
    required this.isVerified,
    this.profilePicture,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      companyName: json['company_name'],
      role: json['role'] ?? '',
      isVerified: json['is_verified_pro'] ?? false,
      profilePicture: json['profile_picture']?.toString(),
    );
  }

  String get displayName => companyName ?? '$firstName $lastName';
}
