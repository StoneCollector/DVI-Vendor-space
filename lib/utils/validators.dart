/// Form validation utilities
class Validators {
  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required *';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  /// Validate password with strict rules
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required *';
    if (value.length < 8) return 'Min 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Must contain uppercase';
    if (!value.contains(RegExp(r'[a-z]'))) return 'Must contain lowercase';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Must contain digit';
    if (!value.contains(RegExp(r'[!@#\$&*~]')))
      return 'Must contain special char';
    return null;
  }

  /// Validate Full Name (at least 2 words)
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) return 'Full Name is required *';
    if (value.trim().split(' ').length < 2)
      return 'Enter full name (First & Last)';
    return null;
  }

  /// Validate Phone Number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone is required *';
    if (!RegExp(r'^\d{10}$').hasMatch(value))
      return 'Enter valid 10-digit number';
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Generic required field validator
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
