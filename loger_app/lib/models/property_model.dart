class Property {
  final String id;
  final String title;
  final String? slug;
  final String description;
  final double price;
  final double? pricePerNight;
  final String city;
  final String neighborhood;
  final String propertyType;
  final String propertyTypeDisplay;
  final String listingCategory;
  final String listingCategoryDisplay;
  final int bedrooms;
  final int bathrooms;
  final double surface;
  final bool isBoosted;
  final DateTime createdAt;
  final List<PropertyImage> images;
  final Owner owner;
  final String absoluteUrl;

  Property({
    required this.id,
    required this.title,
    this.slug,
    required this.description,
    required this.price,
    this.pricePerNight,
    required this.city,
    required this.neighborhood,
    required this.propertyType,
    required this.propertyTypeDisplay,
    required this.listingCategory,
    required this.listingCategoryDisplay,
    required this.bedrooms,
    required this.bathrooms,
    required this.surface,
    required this.isBoosted,
    required this.createdAt,
    required this.images,
    required this.owner,
    required this.absoluteUrl,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      pricePerNight: json['price_per_night'] != null ? (json['price_per_night'] as num).toDouble() : null,
      city: json['city'] ?? '',
      neighborhood: json['neighborhood'] ?? '',
      propertyType: json['property_type'] ?? '',
      propertyTypeDisplay: json['property_type_display'] ?? '',
      listingCategory: json['listing_category'] ?? '',
      listingCategoryDisplay: json['listing_category_display'] ?? '',
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      surface: (json['surface'] as num?)?.toDouble() ?? 0.0,
      isBoosted: json['is_boosted'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      images: (json['images'] as List).map((i) => PropertyImage.fromJson(i)).toList(),
      owner: Owner.fromJson(json['owner']),
      absoluteUrl: json['absolute_url'] ?? '',
    );
  }
}

class PropertyImage {
  final int id;
  final String imageUrl;

  PropertyImage({required this.id, required this.imageUrl});

  factory PropertyImage.fromJson(Map<String, dynamic> json) {
    return PropertyImage(
      id: json['id'],
      imageUrl: json['image_url'],
    );
  }
}

class Owner {
  final String id;
  final String firstName;
  final String lastName;
  final String? companyName;
  final String phoneNumber;

  Owner({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.companyName,
    required this.phoneNumber,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'].toString(),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      companyName: json['company_name'],
      phoneNumber: json['phone_number'] ?? '',
    );
  }

  String get displayName => companyName ?? '$firstName $lastName';
}
