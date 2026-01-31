/// Model representing a venue owned by a vendor
class VenueData {
  final String? id;
  final String vendorId;
  final String name;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final double basePrice;
  final double venueDiscountPercent;
  final String? policies;
  final double? rating;
  final int reviewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Related data (loaded separately)
  List<VenueService> services;
  List<VenueGalleryImage> galleryImages;

  VenueData({
    this.id,
    required this.vendorId,
    required this.name,
    this.description,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.basePrice = 0,
    this.venueDiscountPercent = 0,
    this.policies,
    this.rating,
    this.reviewCount = 0,
    this.createdAt,
    this.updatedAt,
    this.services = const [],
    this.galleryImages = const [],
  });

  factory VenueData.fromJson(Map<String, dynamic> json) {
    return VenueData(
      id: json['id'],
      vendorId: json['vendor_id'],
      name: json['name'] ?? '',
      description: json['description'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      locationAddress: json['location_address'],
      basePrice: (json['base_price'] ?? 0).toDouble(),
      venueDiscountPercent: (json['venue_discount_percent'] ?? 0).toDouble(),
      policies: json['policies'],
      rating: json['rating']?.toDouble(),
      reviewCount: json['review_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vendor_id': vendorId,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'location_address': locationAddress,
      'base_price': basePrice,
      'venue_discount_percent': venueDiscountPercent,
      'policies': policies,
      // rating and review_count are not included as they're managed by the system
    };
  }

  /// Calculate discounted venue price
  double get discountedVenuePrice {
    return basePrice * (1 - venueDiscountPercent / 100);
  }

  /// Get rating display text
  String get ratingDisplay {
    if (rating == null || reviewCount == 0) {
      return 'Unrated';
    }
    return '${rating!.toStringAsFixed(1)} ($reviewCount reviews)';
  }

  /// Create a copy with updated fields
  VenueData copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? locationAddress,
    double? basePrice,
    double? venueDiscountPercent,
    String? policies,
    double? rating,
    int? reviewCount,
    List<VenueService>? services,
    List<VenueGalleryImage>? galleryImages,
  }) {
    return VenueData(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      basePrice: basePrice ?? this.basePrice,
      venueDiscountPercent: venueDiscountPercent ?? this.venueDiscountPercent,
      policies: policies ?? this.policies,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      services: services ?? this.services,
      galleryImages: galleryImages ?? this.galleryImages,
    );
  }
}

/// Model representing a service offered at a venue
class VenueService {
  final String? id;
  final String? venueId;
  final String serviceName;
  final double price;
  final double discountPercent;
  final DateTime? createdAt;

  VenueService({
    this.id,
    this.venueId,
    required this.serviceName,
    required this.price,
    this.discountPercent = 0,
    this.createdAt,
  });

  factory VenueService.fromJson(Map<String, dynamic> json) {
    return VenueService(
      id: json['id'],
      venueId: json['venue_id'],
      serviceName: json['service_name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPercent: (json['discount_percent'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (venueId != null) 'venue_id': venueId,
      'service_name': serviceName,
      'price': price,
      'discount_percent': discountPercent,
    };
  }

  /// Calculate discounted price
  double get discountedPrice {
    return price * (1 - discountPercent / 100);
  }
}

/// Model representing an image in venue gallery
class VenueGalleryImage {
  final String? id;
  final String? venueId;
  final String imageFilename;
  final int displayOrder;
  final DateTime? createdAt;

  VenueGalleryImage({
    this.id,
    this.venueId,
    required this.imageFilename,
    this.displayOrder = 0,
    this.createdAt,
  });

  factory VenueGalleryImage.fromJson(Map<String, dynamic> json) {
    return VenueGalleryImage(
      id: json['id'],
      venueId: json['venue_id'],
      imageFilename: json['image_filename'] ?? '',
      displayOrder: json['display_order'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (venueId != null) 'venue_id': venueId,
      'image_filename': imageFilename,
      'display_order': displayOrder,
    };
  }
}
