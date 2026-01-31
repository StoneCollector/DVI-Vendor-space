import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/venue_data.dart';
import '../services/venue_data_service.dart';
import 'venue_form_page.dart';

/// Widget that displays a list of venues owned by the current vendor
class VenueListWidget extends StatefulWidget {
  const VenueListWidget({super.key});

  @override
  State<VenueListWidget> createState() => _VenueListWidgetState();
}

class _VenueListWidgetState extends State<VenueListWidget> {
  final _venueService = VenueDataService();
  List<VenueData> _venues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    setState(() => _isLoading = true);
    try {
      final venues = await _venueService.getVendorVenues();
      if (mounted) {
        setState(() {
          _venues = venues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading venues: $e')));
      }
    }
  }

  Future<void> _deleteVenue(VenueData venue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Venue'),
        content: Text(
          'Are you sure you want to delete "${venue.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _venueService.deleteVenue(venue.id!);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Venue deleted successfully')),
          );
          _loadVenues();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete venue')),
          );
        }
      }
    }
  }

  void _navigateToAddVenue() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const VenueFormPage()),
    );
    if (result == true) {
      _loadVenues();
    }
  }

  void _navigateToEditVenue(VenueData venue) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VenueFormPage(existingVenue: venue)),
    );
    if (result == true) {
      _loadVenues();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadVenues,
      color: const Color(0xff0c1c2c),
      child: Column(
        children: [
          // Header with Add button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Venues',
                  style: GoogleFonts.urbanist(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _navigateToAddVenue,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Venue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0c1c2c),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Venue list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _venues.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _venues.length,
                    itemBuilder: (context, index) =>
                        _buildVenueCard(_venues[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        const Icon(
          Icons.store_mall_directory_outlined,
          size: 80,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        Text(
          'No venues yet',
          textAlign: TextAlign.center,
          style: GoogleFonts.urbanist(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap "Add Venue" to create your first venue',
          textAlign: TextAlign.center,
          style: GoogleFonts.urbanist(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          'Pull down to refresh',
          textAlign: TextAlign.center,
          style: GoogleFonts.urbanist(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildVenueCard(VenueData venue) {
    // Get first gallery image or use placeholder
    String? thumbnailUrl;
    if (venue.galleryImages.isNotEmpty) {
      thumbnailUrl = _venueService.getGalleryImageUrl(
        venue.galleryImages.first.imageFilename,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToEditVenue(venue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[200],
              child: thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image_not_supported, size: 50),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildRatingBadge(venue),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Location
                  if (venue.locationAddress != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            venue.locationAddress!,
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // Price info
                  Row(
                    children: [
                      Text(
                        '₹${venue.discountedVenuePrice.toStringAsFixed(0)}',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff0c1c2c),
                        ),
                      ),
                      if (venue.venueDiscountPercent > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${venue.basePrice.toStringAsFixed(0)}',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${venue.venueDiscountPercent.toStringAsFixed(0)}% OFF',
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Services count
                  Text(
                    '${venue.services.length} service${venue.services.length != 1 ? 's' : ''} • ${venue.galleryImages.length} photo${venue.galleryImages.length != 1 ? 's' : ''}',
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _deleteVenue(venue),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToEditVenue(venue),
                        icon: const Icon(Icons.edit, size: 20),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0c1c2c),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(VenueData venue) {
    if (venue.rating == null || venue.reviewCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Unrated',
          style: GoogleFonts.urbanist(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            venue.rating!.toStringAsFixed(1),
            style: GoogleFonts.urbanist(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ' (${venue.reviewCount})',
            style: GoogleFonts.urbanist(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
