import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _nameController.text.trim(),
        }, // Store name in metadata initially
      );

      if (response.user == null) throw "Signup failed";

      // If email confirmation is off, we have a session.
      // If on, we might not. But the prompt says: "create supabase user -> then proceed with the additional details"
      // If we don't have a session, we can't proceed to insert details yet.
      // However, the user asked to "proceed with the additional details".
      // If session is null, we strictly show the "Verify Email" dialog.
      // If session is active, we go to CompleteProfilePage.

      if (response.session == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text("Verification Required"),
              content: const Text(
                "Please check your email to confirm your account. Then login to complete setup.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(c);
                    Navigator.pushReplacementNamed(
                      context,
                      AppConstants.loginRoute,
                    );
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
        return;
      }

      // If we have a session, we proceed to the Next Step (Details)
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/',
        ); // Main wrapper will route to CompleteProfilePage because profile is null
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF121212), Colors.black],
          ),
        ),
        child: Stack(
          children: [
            // Background Elements
            Positioned(
              top: -size.height * 0.15,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Join DreamVentz as a Vendor",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        _buildTextField(
                          label: "Full Name",
                          hint: "John Doe",
                          prefixIcon: Icons.person_outline,
                          controller: _nameController,
                          validator: Validators.validateFullName,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: "Email Address",
                          hint: "vendor@example.com",
                          prefixIcon: Icons.email_outlined,
                          controller: _emailController,
                          validator: Validators.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                          controller: _passwordController,
                          label: "Password",
                          isVisible: _isPasswordVisible,
                          onVisibilityChanged: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                          validator: Validators
                              .validatePassword, // Use existing strong validator
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: "Confirm Password",
                          isVisible: _isConfirmPasswordVisible,
                          onVisibilityChanged: () => setState(
                            () => _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible,
                          ),
                          validator: (val) => val != _passwordController.text
                              ? "Passwords do not match"
                              : null,
                        ),

                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text(
                                  "Continue",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Already have an account? Login",
                            style: TextStyle(color: Colors.amber[400]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData prefixIcon,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[300],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              prefixIcon: Icon(
                prefixIcon,
                color: Colors.amber.withOpacity(0.7),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
    required String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[300],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            obscureText: !isVisible,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "••••••••",
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.amber.withOpacity(0.7),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[500],
                ),
                onPressed: onVisibilityChanged,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
