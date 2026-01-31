import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

/// Lightweight search-based location picker
/// Uses OpenStreetMap Nominatim for geocoding (free, no API key)
class LocationSearchPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  const LocationSearchPicker({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  @override
  State<LocationSearchPicker> createState() => _LocationSearchPickerState();
}

class _LocationSearchPickerState extends State<LocationSearchPicker> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  List<LocationResult> _searchResults = [];
  LocationResult? _selectedLocation;
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Pre-populate if editing
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LocationResult(
        displayName: widget.initialAddress ?? 'Selected Location',
        lat: widget.initialLat!,
        lng: widget.initialLng!,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    // Debounce 500ms to avoid too many API calls
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchLocation(query);
    });
  }

  Future<void> _searchLocation(String query) async {
    setState(() => _isSearching = true);

    try {
      // Use Nominatim geocoding API (free, no API key)
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&limit=10'
        '&countrycodes=in', // Limit to India for faster results
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'DreamVentz-Vendor-App'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (mounted) {
          setState(() {
            _searchResults = data
                .map(
                  (item) => LocationResult(
                    displayName: item['display_name'] ?? '',
                    lat: double.parse(item['lat']),
                    lng: double.parse(item['lon']),
                  ),
                )
                .toList();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectLocation(LocationResult location) {
    setState(() {
      _selectedLocation = location;
      _searchResults = [];
      _searchController.text = location.shortName;
    });
    _focusNode.unfocus();
  }

  void _confirmSelection() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please search and select a location')),
      );
      return;
    }
    Navigator.pop(context, _selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Location',
          style: GoogleFonts.urbanist(color: Colors.white),
        ),
        backgroundColor: const Color(0xff0c1c2c),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search field
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search for venue location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Search results or selected location
          Expanded(
            child: _searchResults.isNotEmpty
                ? _buildSearchResults()
                : _selectedLocation != null
                ? _buildSelectedLocation()
                : _buildEmptyState(),
          ),
        ],
      ),
      bottomNavigationBar: _selectedLocation != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0c1c2c),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Confirm Location',
                    style: GoogleFonts.urbanist(fontSize: 16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xff0c1c2c),
            child: Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
          title: Text(
            result.shortName,
            style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            result.displayName,
            style: GoogleFonts.urbanist(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _selectLocation(result),
        );
      },
    );
  }

  Widget _buildSelectedLocation() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Location',
            style: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedLocation!.shortName,
                        style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedLocation!.lat.toStringAsFixed(6)}, ${_selectedLocation!.lng.toStringAsFixed(6)}',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Full Address:',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedLocation!.displayName,
            style: GoogleFonts.urbanist(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedLocation = null;
                _searchController.clear();
              });
              _focusNode.requestFocus();
            },
            icon: const Icon(Icons.search),
            label: const Text('Search Different Location'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_searching, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search for a location',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type at least 3 characters to search\nfor venues, cities, or addresses',
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Location result model
class LocationResult {
  final String displayName;
  final double lat;
  final double lng;

  LocationResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  /// Get short name (first part of address)
  String get shortName {
    final parts = displayName.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return parts.first.trim();
  }
}
