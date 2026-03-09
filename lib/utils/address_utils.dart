/// Utility methods to handle address parsing and formatting
class AddressUtils {
  /// Format address components into a single saveable string
  /// Expected format: "123 Street Name, Ward Name, District Name, Province Name"
  static String formatAddress({
    required String street,
    required String ward,
    required String province,
  }) {
    return '$street, $ward, $province';
  }

  /// Attempts to extract the street part from a previously formatted address string
  static String extractStreetLine(String? fullAddress) {
    if (fullAddress == null || fullAddress.isEmpty) return '';

    final parts = fullAddress.split(', ');
    // If we have 3 parts (Street, Ward, Province), index 0 is street.
    if (parts.length >= 3) {
      return parts.sublist(0, parts.length - 2).join(', ');
    }
    return fullAddress; // Fallback
  }

  /// Attempts to extract the Ward part
  static String? extractWard(String? fullAddress) {
    if (fullAddress == null || fullAddress.isEmpty) return null;
    final parts = fullAddress.split(', ');
    if (parts.length >= 3) {
      return parts[parts.length - 2].trim();
    }
    return null;
  }

  /// Attempts to extract the Province part
  static String? extractProvince(String? fullAddress) {
    if (fullAddress == null || fullAddress.isEmpty) return null;
    final parts = fullAddress.split(', ');
    if (parts.length >= 2) {
      return parts.last.trim();
    }
    return null;
  }
}
