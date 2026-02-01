/// Model representing a vendor card displayed in customer app
class VendorCard {
  final int? id;
  final String vendorId;
  final int categoryId;
  final String studioName;
  final String city;
  final String imagePath;
  final List<String> serviceTags;
  final List<String> qualityTags;
  final double originalPrice;
  final double discountedPrice;
  final DateTime? createdAt;

  VendorCard({
    this.id,
    required this.vendorId,
    required this.categoryId,
    required this.studioName,
    required this.city,
    required this.imagePath,
    required this.serviceTags,
    required this.qualityTags,
    required this.originalPrice,
    required this.discountedPrice,
    this.createdAt,
  });

  /// Calculate discount percentage
  int get discountPercentage {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - discountedPrice) / originalPrice * 100).round();
  }

  /// Get category name from ID
  String get categoryName {
    const categories = {
      1: 'Photography',
      2: 'Mehndi Artist',
      3: 'Make-Up Artist',
      4: 'Caterers',
      5: 'DJ & Bands',
      6: 'Decoraters',
      7: 'Pandits🕉️',
      8: 'Invites & Gifts 🎁',
    };
    return categories[categoryId] ?? 'Unknown';
  }

  /// Get folder name for storage from category ID
  static String getFolderName(int categoryId) {
    const folders = {
      1: 'photography',
      2: 'mehndi',
      3: 'makeup',
      4: 'caterers',
      5: 'dj',
      6: 'decorators',
      7: 'pandits',
      8: 'invites',
    };
    return folders[categoryId] ?? 'other';
  }

  /// Convert from Supabase JSON
  factory VendorCard.fromJson(Map<String, dynamic> json) {
    return VendorCard(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      vendorId: json['vendor_id'] as String,
      categoryId: json['category_id'] is int 
          ? json['category_id'] as int 
          : int.parse(json['category_id'].toString()),
      studioName: json['studio_name'] as String,
      city: json['city'] as String,
      imagePath: json['image_path'] as String,
      serviceTags: (json['service_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      qualityTags: (json['quality_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      originalPrice: (json['original_price'] as num).toDouble(),
      discountedPrice: (json['discounted_price'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to Supabase JSON for insert/update
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vendor_id': vendorId,
      'category_id': categoryId,
      'studio_name': studioName,
      'city': city,
      'image_path': imagePath,
      'service_tags': serviceTags,
      'quality_tags': qualityTags,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
    };
  }

  /// Create a copy with updated fields
  VendorCard copyWith({
    int? id,
    String? vendorId,
    int? categoryId,
    String? studioName,
    String? city,
    String? imagePath,
    List<String>? serviceTags,
    List<String>? qualityTags,
    double? originalPrice,
    double? discountedPrice,
    DateTime? createdAt,
  }) {
    return VendorCard(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      categoryId: categoryId ?? this.categoryId,
      studioName: studioName ?? this.studioName,
      city: city ?? this.city,
      imagePath: imagePath ?? this.imagePath,
      serviceTags: serviceTags ?? this.serviceTags,
      qualityTags: qualityTags ?? this.qualityTags,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Available categories
class VendorCategory {
  final int id;
  final String name;

  const VendorCategory(this.id, this.name);

  static const List<VendorCategory> all = [
    VendorCategory(1, 'Photography'),
    VendorCategory(2, 'Mehndi Artist'),
    VendorCategory(3, 'Make-Up Artist'),
    VendorCategory(4, 'Caterers'),
    VendorCategory(5, 'DJ & Bands'),
    VendorCategory(6, 'Decoraters'),
    VendorCategory(7, 'Pandits🕉️'),
    VendorCategory(8, 'Invites & Gifts 🎁'),
  ];
}

/// Tag options for vendor cards
class VendorCardTags {
  // Quality tags - generic across all categories
  static const List<String> qualityTags = [
    'Quality Service',
    'Experienced',
    'Customizable',
    'Professional',
    'Hygienic',
    'Modern Equipment',
  ];

  // Service tags - category specific
  static Map<int, List<String>> serviceTags = {
    1: [ // Photography
      'Wedding Photographer',
      'Pre-wedding',
      'Videography',
      'Editing',
      'Candid Photography',
      'Traditional Photography',
    ],
    2: [ // Mehndi Artist
      'Bridal Mehndi',
      'Arabic Mehndi',
      'Traditional Mehndi',
      'Modern Designs',
      'Indo-Western',
      'Rajasthani Mehndi',
    ],
    3: [ // Make-Up Artist
      'Bridal Makeup',
      'HD Makeup',
      'Airbrush Makeup',
      'Party Makeup',
      'Hair Styling',
      'Nail Art',
    ],
    4: [ // Caterers
      'North Indian',
      'South Indian',
      'Chinese',
      'Continental',
      'Live Counters',
      'Desserts',
    ],
    5: [ // DJ & Bands
      'DJ Services',
      'Live Band',
      'Sound System',
      'Lighting',
      'Dhol Players',
      'Bollywood Music',
    ],
    6: [ // Decorators
      'Stage Decoration',
      'Floral Decor',
      'Lighting Setup',
      'Theme Decoration',
      'Entrance Decor',
      'Mandap Decoration',
    ],
    7: [ // Pandits
      'Wedding Rituals',
      'Griha Pravesh',
      'Satyanarayan Puja',
      'Kundli Matching',
      'Muhurat Consultation',
      'All Hindu Rituals',
    ],
    8: [ // Invites & Gifts
      'Wedding Cards',
      'Digital Invites',
      'Return Gifts',
      'Trousseau Packing',
      'Gift Hampers',
      'Customized Gifts',
    ],
  };

  /// Get service tags for specific category
  static List<String> getServiceTagsForCategory(int categoryId) {
    return serviceTags[categoryId] ?? [];
  }
}

/// Indian cities for dropdown
class IndianCities {
  static const List<String> cities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
    'Ahmedabad',
    'Chennai',
    'Kolkata',
    'Pune',
    'Jaipur',
    'Surat',
    'Lucknow',
    'Kanpur',
    'Nagpur',
    'Indore',
    'Thane',
    'Bhopal',
    'Visakhapatnam',
    'Pimpri-Chinchwad',
    'Patna',
    'Vadodara',
    'Ghaziabad',
    'Ludhiana',
    'Agra',
    'Nashik',
    'Faridabad',
    'Meerut',
    'Rajkot',
    'Kalyan-Dombivali',
    'Vasai-Virar',
    'Varanasi',
    'Srinagar',
    'Aurangabad',
    'Dhanbad',
    'Amritsar',
    'Navi Mumbai',
    'Allahabad',
    'Ranchi',
    'Howrah',
    'Coimbatore',
    'Jabalpur',
    'Gwalior',
    'Vijayawada',
    'Jodhpur',
    'Madurai',
    'Raipur',
    'Kota',
    'Chandigarh',
    'Guwahati',
    'Solapur',
    'Hubli-Dharwad',
    'Mysore',
    'Tiruchirappalli',
    'Bareilly',
    'Aligarh',
    'Tiruppur',
    'Moradabad',
    'Jalandhar',
    'Bhubaneswar',
    'Salem',
    'Warangal',
    'Guntur',
    'Bhiwandi',
    'Saharanpur',
    'Gorakhpur',
    'Bikaner',
    'Amravati',
    'Noida',
    'Jamshedpur',
    'Bhilai',
    'Cuttack',
    'Firozabad',
    'Kochi',
    'Nellore',
    'Bhavnagar',
    'Dehradun',
    'Durgapur',
    'Asansol',
    'Rourkela',
    'Nanded',
    'Kolhapur',
    'Ajmer',
    'Akola',
    'Gulbarga',
    'Jamnagar',
    'Ujjain',
    'Loni',
    'Siliguri',
    'Jhansi',
    'Ulhasnagar',
    'Jammu',
    'Sangli-Miraj & Kupwad',
    'Mangalore',
    'Erode',
    'Belgaum',
    'Ambattur',
    'Tirunelveli',
    'Malegaon',
    'Gaya',
    'Jalgaon',
    'Udaipur',
    'Maheshtala',
  ];
}
