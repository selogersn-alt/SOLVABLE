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
  final int toilets;
  final int? totalRooms;
  final int? salons;
  final int? kitchens;
  final bool hasGarage;
  final bool hasBalcony;
  final bool hasTerrace;
  final String? documentType;
  final bool isBoosted;
  final DateTime createdAt;
  final List<PropertyImage> images;
  final Owner owner;
  final String absoluteUrl;
  final double surface;
  final double latitude;
  final double longitude;
  final bool isFavorite;

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
    required this.toilets,
    this.totalRooms,
    this.salons,
    this.kitchens,
    this.hasGarage = false,
    this.hasBalcony = false,
    this.hasTerrace = false,
    this.documentType,
    required this.surface,
    required this.isBoosted,
    required this.createdAt,
    required this.images,
    required this.owner,
    required this.absoluteUrl,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.isFavorite = false,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString(),
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      pricePerNight: json['price_per_night'] != null ? double.tryParse(json['price_per_night'].toString()) : null,
      city: json['city']?.toString() ?? '',
      neighborhood: json['neighborhood']?.toString() ?? '',
      propertyType: json['property_type']?.toString() ?? '',
      propertyTypeDisplay: json['property_type_display']?.toString() ?? '',
      listingCategory: json['listing_category']?.toString() ?? '',
      listingCategoryDisplay: json['listing_category_display']?.toString() ?? '',
      bedrooms: int.tryParse(json['bedrooms']?.toString() ?? '0') ?? 0,
      toilets: int.tryParse(json['toilets']?.toString() ?? '0') ?? 0,
      totalRooms: int.tryParse(json['total_rooms']?.toString() ?? ''),
      salons: int.tryParse(json['salons']?.toString() ?? ''),
      kitchens: int.tryParse(json['kitchens']?.toString() ?? ''),
      hasGarage: json['has_garage'] == true,
      hasBalcony: json['has_balcony'] == true,
      hasTerrace: json['has_terrace'] == true,
      documentType: json['document_type']?.toString(),
      surface: double.tryParse(json['surface']?.toString() ?? '0') ?? 0.0,
      isBoosted: json['is_boosted'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      images: (json['images'] as List?)?.map((i) => PropertyImage.fromJson(i)).toList() ?? [],
      owner: Owner.fromJson(json['owner'] ?? {}),
      absoluteUrl: json['absolute_url']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      isFavorite: json['is_favorite'] == true,
    );
  }
}

class PropertyImage {
  final String id;
  final String imageUrl;

  PropertyImage({required this.id, required this.imageUrl});

  factory PropertyImage.fromJson(Map<String, dynamic> json) {
    // Some API versions use 'image', others 'image_url'
    String url = json['image_url'] ?? json['image'] ?? '';
    return PropertyImage(
      id: json['id'].toString(),
      imageUrl: url,
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
