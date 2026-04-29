class Booking {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String propertyImage;
  final String userId;
  final String userName;
  final DateTime startDate;
  final DateTime endDate;
  final String? message;
  final String status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyImage,
    required this.userId,
    required this.userName,
    required this.startDate,
    required this.endDate,
    this.message,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      propertyId: json['property'], // Assuming it returns property ID
      propertyTitle: json['property_title'] ?? '',
      propertyImage: json['property_image'] ?? '',
      userId: json['user'],
      userName: json['user_name'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      message: json['message'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
