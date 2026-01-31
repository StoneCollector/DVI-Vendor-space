import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vendor_profile.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _supabase = Supabase.instance.client;
  List<VendorProfile> _pendingVendors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingVendors();
  }

  Future<void> _fetchPendingVendors() async {
    try {
      final response = await _supabase
          .from('vendors')
          .select()
          .eq('verification_status', 'pending');

      final vendors = (response as List)
          .map((e) => VendorProfile.fromJson(e))
          .toList();

      setState(() {
        _pendingVendors = vendors;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching vendors: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(
    String vendorId,
    String status, {
    String? reason,
  }) async {
    try {
      await _supabase
          .from('vendors')
          .update({'verification_status': status, 'rejection_reason': reason})
          .eq('id', vendorId);

      await _fetchPendingVendors();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Vendor ${status == 'verified' ? 'Approved' : 'Rejected'}",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showRejectDialog(String vendorId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Application"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Reason for rejection"),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context);
                _updateStatus(
                  vendorId,
                  'rejected',
                  reason: reasonController.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  void _showDocument(String? path) {
    if (path == null) return;

    final url = _supabase.storage.from('vendor_docs').getPublicUrl(path);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: 200,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(20),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 40),
                        Text("Could not load document"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color(0xff0c1c2c),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  AppConstants.loginRoute,
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPendingVendors,
        color: const Color(0xff0c1c2c),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pendingVendors.isEmpty
            ? ListView(
                // Using ListView to allow pull-to-refresh even when empty
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text("No pending applications")),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Pull down to refresh",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _pendingVendors.length,
                itemBuilder: (context, index) {
                  final vendor = _pendingVendors[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(vendor.email),
                          Text(vendor.phone),
                          const Divider(),
                          Text(
                            "Address: ${vendor.address}, ${vendor.city}, ${vendor.state} - ${vendor.pincode}",
                          ),
                          if (vendor.identificationUrl != null)
                            TextButton.icon(
                              onPressed: () =>
                                  _showDocument(vendor.identificationUrl),
                              icon: const Icon(Icons.file_present),
                              label: const Text("View ID Document"),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _showRejectDialog(vendor.id),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text("Reject"),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () =>
                                    _updateStatus(vendor.id, 'verified'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text("Verify"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
