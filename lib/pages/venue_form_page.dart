import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/venue_data.dart';
import '../services/venue_data_service.dart';
import 'location_picker_page.dart';

/// Page for creating or editing a venue
class VenueFormPage extends StatefulWidget {
  final VenueData? existingVenue; // null = create mode, non-null = edit mode

  const VenueFormPage({super.key, this.existingVenue});

  @override
  State<VenueFormPage> createState() => _VenueFormPageState();
}

class _VenueFormPageState extends State<VenueFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _venueService = VenueDataService();
  final _picker = ImagePicker();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _venueDiscountController = TextEditingController();
  final _policiesController = TextEditingController();

  // Location data
  double? _latitude;
  double? _longitude;
  String? _locationAddress;

  // Services list
  List<ServiceEntry> _services = [];

  // Gallery images
  List<GalleryEntry> _galleryImages = [];

  // State
  bool _isLoading = false;
  bool _isSaving = false;

  bool get isEditMode => widget.existingVenue != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final venue = widget.existingVenue!;
    _nameController.text = venue.name;
    _descriptionController.text = venue.description ?? '';
    _basePriceController.text = venue.basePrice.toString();
    _venueDiscountController.text = venue.venueDiscountPercent.toString();
    _policiesController.text = venue.policies ?? '';
    _latitude = venue.latitude;
    _longitude = venue.longitude;
    _locationAddress = venue.locationAddress;

    // Load existing services
    _services = venue.services
        .map(
          (s) => ServiceEntry(
            id: s.id,
            nameController: TextEditingController(text: s.serviceName),
            priceController: TextEditingController(text: s.price.toString()),
            discountController: TextEditingController(
              text: s.discountPercent.toString(),
            ),
          ),
        )
        .toList();

    // Load existing gallery images
    _galleryImages = venue.galleryImages
        .map(
          (g) => GalleryEntry(
            id: g.id,
            filename: g.imageFilename,
            imageUrl: _venueService.getGalleryImageUrl(g.imageFilename),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _venueDiscountController.dispose();
    _policiesController.dispose();
    for (final s in _services) {
      s.dispose();
    }
    super.dispose();
  }

  // ==================== Location Picker ====================

  Future<void> _openLocationPicker() async {
    // Navigate to search-based location picker (lightweight)
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSearchPicker(
          initialLat: _latitude,
          initialLng: _longitude,
          initialAddress: _locationAddress,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result.lat;
        _longitude = result.lng;
        _locationAddress = result.shortName;
      });
    }
  }

  // ==================== Image Gallery ====================

  Future<void> _addGalleryImage() async {
    try {
      // image_picker handles permissions internally on modern Android
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compress for faster uploads
      );

      if (image != null && mounted) {
        setState(() {
          _galleryImages.add(GalleryEntry(localFile: File(image.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _removeGalleryImage(int index) {
    setState(() {
      final entry = _galleryImages[index];
      entry.markedForDeletion = true;
      if (entry.id == null) {
        // New image, just remove
        _galleryImages.removeAt(index);
      }
    });
  }

  // ==================== Services Management ====================

  void _addService() {
    setState(() {
      _services.add(
        ServiceEntry(
          nameController: TextEditingController(),
          priceController: TextEditingController(),
          discountController: TextEditingController(text: '0'),
        ),
      );
    });
  }

  void _removeService(int index) {
    setState(() {
      _services[index].dispose();
      _services.removeAt(index);
    });
  }

  // ==================== Price Calculator ====================

  double get _calculatedVenuePrice {
    final basePrice = double.tryParse(_basePriceController.text) ?? 0;
    final discount = double.tryParse(_venueDiscountController.text) ?? 0;
    return basePrice * (1 - discount / 100);
  }

  double get _calculatedServicesTotal {
    double total = 0;
    for (final service in _services) {
      final price = double.tryParse(service.priceController.text) ?? 0;
      final discount = double.tryParse(service.discountController.text) ?? 0;
      total += price * (1 - discount / 100);
    }
    return total;
  }

  double get _grandTotal => _calculatedVenuePrice + _calculatedServicesTotal;

  // ==================== Form Submission ====================

  Future<void> _saveVenue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Create/update venue
      final venue = VenueData(
        id: widget.existingVenue?.id,
        vendorId: '', // Will be set by service
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        locationAddress: _locationAddress,
        basePrice: double.tryParse(_basePriceController.text) ?? 0,
        venueDiscountPercent:
            double.tryParse(_venueDiscountController.text) ?? 0,
        policies: _policiesController.text.trim(),
      );

      VenueData? savedVenue;
      if (isEditMode) {
        savedVenue = await _venueService.updateVenue(venue);
      } else {
        savedVenue = await _venueService.createVenue(venue);
      }

      if (savedVenue == null) throw Exception('Failed to save venue');

      // Save services
      final services = _services
          .map(
            (s) => VenueService(
              id: s.id,
              serviceName: s.nameController.text.trim(),
              price: double.tryParse(s.priceController.text) ?? 0,
              discountPercent: double.tryParse(s.discountController.text) ?? 0,
            ),
          )
          .toList();

      await _venueService.replaceVenueServices(savedVenue.id!, services);

      // Handle gallery images
      // Delete marked images
      for (final entry in _galleryImages.where((e) => e.markedForDeletion)) {
        if (entry.id != null && entry.filename != null) {
          await _venueService.deleteGalleryImage(
            VenueGalleryImage(id: entry.id, imageFilename: entry.filename!),
          );
        }
      }

      // Upload new images
      int order = 0;
      for (final entry in _galleryImages.where((e) => !e.markedForDeletion)) {
        if (entry.localFile != null) {
          await _venueService.uploadGalleryImage(
            savedVenue.id!,
            entry.localFile!,
            order,
          );
        }
        order++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Venue updated successfully!'
                  : 'Venue created successfully!',
            ),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==================== Build UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Venue' : 'Add New Venue',
          style: GoogleFonts.urbanist(color: Colors.white),
        ),
        backgroundColor: const Color(0xff0c1c2c),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),
                  _buildLocationSection(),
                  const SizedBox(height: 24),
                  _buildGallerySection(),
                  const SizedBox(height: 24),
                  _buildServicesSection(),
                  const SizedBox(height: 24),
                  _buildPricingSection(),
                  const SizedBox(height: 24),
                  _buildPoliciesSection(),
                  const SizedBox(height: 24),
                  _buildPriceCalculator(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Information'),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Venue Name *',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Location'),
        InkWell(
          onTap: _openLocationPicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xff0c1c2c)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _locationAddress ?? 'Tap to select location',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          color: _locationAddress != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_latitude != null && _longitude != null)
                        Text(
                          '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection() {
    final visibleImages = _galleryImages
        .where((e) => !e.markedForDeletion)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Gallery Images'),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add button
              GestureDetector(
                onTap: _addGalleryImage,
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 32),
                      SizedBox(height: 4),
                      Text('Add', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              // Existing images
              ...visibleImages.asMap().entries.map((entry) {
                final index = _galleryImages.indexOf(
                  entry.value,
                ); // Get real index
                final image = entry.value;

                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: image.localFile != null
                              ? FileImage(image.localFile!)
                              : NetworkImage(image.imageUrl!) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _removeGalleryImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Services'),
            TextButton.icon(
              onPressed: _addService,
              icon: const Icon(Icons.add),
              label: const Text('Add Service'),
            ),
          ],
        ),
        if (_services.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No services added yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...(_services.asMap().entries.map((entry) {
            final index = entry.key;
            final service = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: service.nameController,
                            decoration: const InputDecoration(
                              labelText: 'Service Name',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeService(index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: service.priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price (₹)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: service.discountController,
                            decoration: const InputDecoration(
                              labelText: 'Discount %',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          })),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Venue Pricing'),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _basePriceController,
                decoration: const InputDecoration(
                  labelText: 'Base Price (₹) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _venueDiscountController,
                decoration: const InputDecoration(
                  labelText: 'Venue Discount %',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPoliciesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Policies'),
        TextFormField(
          controller: _policiesController,
          decoration: const InputDecoration(
            labelText: 'Venue Policies',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            hintText: 'Enter venue policies, terms and conditions...',
          ),
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildPriceCalculator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Calculator',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          _buildPriceRow(
            'Venue Base Price',
            '₹${_basePriceController.text.isEmpty ? '0' : _basePriceController.text}',
          ),
          _buildPriceRow(
            'Venue Discount',
            '-${_venueDiscountController.text.isEmpty ? '0' : _venueDiscountController.text}%',
          ),
          _buildPriceRow(
            'Venue After Discount',
            '₹${_calculatedVenuePrice.toStringAsFixed(2)}',
          ),
          const Divider(),
          _buildPriceRow(
            'Services Total (after discounts)',
            '₹${_calculatedServicesTotal.toStringAsFixed(2)}',
          ),
          const Divider(),
          _buildPriceRow(
            'Grand Total',
            '₹${_grandTotal.toStringAsFixed(2)}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveVenue,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff0c1c2c),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              isEditMode ? 'Save Changes' : 'Create Venue',
              style: GoogleFonts.urbanist(fontSize: 16),
            ),
    );
  }
}

// ==================== Helper Classes ====================

/// Helper class to manage service form entries
class ServiceEntry {
  final String? id;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController discountController;

  ServiceEntry({
    this.id,
    required this.nameController,
    required this.priceController,
    required this.discountController,
  });

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    discountController.dispose();
  }
}

/// Helper class to manage gallery image entries
class GalleryEntry {
  final String? id;
  final String? filename;
  final String? imageUrl;
  final File? localFile;
  bool markedForDeletion;

  GalleryEntry({
    this.id,
    this.filename,
    this.imageUrl,
    this.localFile,
    this.markedForDeletion = false,
  });
}
