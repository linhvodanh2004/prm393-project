class RegisterDTO {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;
  final String address;
  final DateTime dateOfBirth;
  final String role;

  RegisterDTO({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.dateOfBirth,
    this.role = 'USER',
  });

  // Validate all fields
  String? validate() {
    if (email.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email.trim())) {
      return 'Invalid email format';
    }
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (fullName.trim().isEmpty) {
      return 'Full name is required';
    }
    if (phoneNumber.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (address.trim().isEmpty) {
      return 'Address is required';
    }
    // Simple verification (must be at least 18)
    if (DateTime.now().difference(dateOfBirth).inDays < 365 * 18) {
      return 'You must be at least 18 years old';
    }
    if (role != 'USER' && role != 'HOST' && role != 'ADMIN') {
      return 'Invalid role selected';
    }
    return null; // No errors
  }

  // Convert to Map for Firestore (excluding password).
  // Role is always forced to 'USER' — never trust client-supplied role.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email.trim(),
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'address': address.trim(),
      'dateOfBirth': dateOfBirth,
      'authProvider': 'email',
      'role': 'USER',
    };
  }

  // Create a copy with updated fields
  RegisterDTO copyWith({
    String? email,
    String? password,
    String? fullName,
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
    String? role,
  }) {
    return RegisterDTO(
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
    );
  }
}
