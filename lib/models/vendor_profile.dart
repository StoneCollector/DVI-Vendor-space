class VendorProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String? identificationUrl;
  final String verificationStatus;
  final String? rejectionReason;

  VendorProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.identificationUrl,
    this.verificationStatus = 'pending',
    this.rejectionReason,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      identificationUrl: json['identification_url'],
      verificationStatus: json['verification_status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'identification_url': identificationUrl,
      'verification_status': verificationStatus,
      'rejection_reason': rejectionReason,
    };
  }
}
