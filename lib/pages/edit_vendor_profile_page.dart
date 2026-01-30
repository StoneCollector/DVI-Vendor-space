import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:country_picker/country_picker.dart';
import '../models/vendor_profile.dart';
import '../utils/validators.dart';

class EditVendorProfilePage extends StatefulWidget {
  final VendorProfile profile;
  const EditVendorProfilePage({super.key, required this.profile});

  @override
  State<EditVendorProfilePage> createState() => _EditVendorProfilePageState();
}

class _EditVendorProfilePageState extends State<EditVendorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;

  String _selectedCountryCode = '91';
  File? _idDocument;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);

    // Parse phone number to extract country code if possible
    String rawPhone = widget.profile.phone;
    if (rawPhone.startsWith('+')) {
      // Simple heuristic: assume country code is first 2-3 digits after +
      // Better to store country code separately, but for now we try to parse or default
      if (rawPhone.length > 10) {
        // e.g. +91 9876543210 or +919876543210
        // Let's just strip non-digits and take last 10 as phone, rest as code
        String digits = rawPhone.replaceAll(RegExp(r'\D'), '');
        if (digits.length > 10) {
          _phoneController = TextEditingController(
            text: digits.substring(digits.length - 10),
          );
          _selectedCountryCode = digits.substring(0, digits.length - 10);
        } else {
          _phoneController = TextEditingController(text: digits);
        }
      } else {
        _phoneController = TextEditingController(text: rawPhone);
      }
    } else {
      _phoneController = TextEditingController(text: rawPhone);
    }

    _addressController = TextEditingController(text: widget.profile.address);
    _cityController = TextEditingController(text: widget.profile.city);
    _stateController = TextEditingController(text: widget.profile.state);
    _pincodeController = TextEditingController(text: widget.profile.pincode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _showCustomToast(String message, {bool isError = true}) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: isError ? Colors.redAccent : Colors.green,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _idDocument = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? docPath = widget.profile.identificationUrl;
      final userId = Supabase.instance.client.auth.currentUser!.id;

      if (_idDocument != null) {
        final fileName =
            'id_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('vendor_docs')
            .upload(fileName, _idDocument!);
        docPath = fileName;
      }

      await Supabase.instance.client
          .from('vendors')
          .update({
            'full_name': _nameController.text,
            'phone': '+$_selectedCountryCode ${_phoneController.text}',
            'address': _addressController.text,
            'city': _cityController.text,
            'state': _stateController.text,
            'pincode': _pincodeController.text,
            'identification_url': docPath,
            // Resubmit for verification if rejected
            'verification_status':
                widget.profile.verificationStatus == 'rejected'
                ? 'pending'
                : widget.profile.verificationStatus,
          })
          .eq('id', userId);

      if (mounted) {
        _showCustomToast("Profile Updated Successfully", isError: false);
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) _showCustomToast("Error updating profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Application"),
        backgroundColor: const Color(0xff0c1c2c),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Update your details below to process your application.",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.validateFullName,
                    ),
                    const SizedBox(height: 15),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            showCountryPicker(
                              context: context,
                              showPhoneCode: true,
                              onSelect: (c) => setState(
                                () => _selectedCountryCode = c.phoneCode,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "+$_selectedCountryCode",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: Validators.validatePhone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _pincodeController,
                            decoration: const InputDecoration(
                              labelText: 'Pincode',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.length < 6 ? 'Invalid' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text("Identification Document"),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _idDocument != null
                            ? Image.file(_idDocument!, fit: BoxFit.cover)
                            : (widget.profile.identificationUrl != null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 50,
                                        ),
                                        Text(
                                          "Document Uploaded",
                                          style: TextStyle(color: Colors.green),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.upload_file, size: 50),
                                        Text("Tap to Change"),
                                      ],
                                    )),
                      ),
                    ),
                    if (_idDocument != null)
                      TextButton(
                        onPressed: () => setState(() => _idDocument = null),
                        child: const Text("Clear Selection"),
                      ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("Update Application"),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
