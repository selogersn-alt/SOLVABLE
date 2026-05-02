import 'dart:convert';

class PropertyAlert {
  final String id;
  final String label;
  final String? city;
  final String? propertyType;
  final String? listingCategory;
  final double? minPrice;
  final double? maxPrice;
  final DateTime createdAt;

  PropertyAlert({
    required this.id,
    required this.label,
    this.city,
    this.propertyType,
    this.listingCategory,
    this.minPrice,
    this.maxPrice,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'city': city,
        'propertyType': propertyType,
        'listingCategory': listingCategory,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PropertyAlert.fromJson(Map<String, dynamic> json) => PropertyAlert(
        id: json['id'],
        label: json['label'],
        city: json['city'],
        propertyType: json['propertyType'],
        listingCategory: json['listingCategory'],
        minPrice: json['minPrice']?.toDouble(),
        maxPrice: json['maxPrice']?.toDouble(),
        createdAt: DateTime.parse(json['createdAt']),
      );

  static String encodeList(List<PropertyAlert> alerts) =>
      json.encode(alerts.map((a) => a.toJson()).toList());

  static List<PropertyAlert> decodeList(String src) =>
      (json.decode(src) as List)
          .map((e) => PropertyAlert.fromJson(e))
          .toList();
}
