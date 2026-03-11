import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_models.dart';

class LocationService {
  static const String _baseUrl = 'https://provinces.open-api.vn/api/v2';

  // Fetch all provinces
  Future<List<Province>> getProvinces() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/p/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Province.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load provinces');
      }
    } catch (e) {
      throw Exception('Lỗi gọi API Tỉnh/Thành phố: $e');
    }
  }

  // Fetch wards by province code using the detailed province endpoint
  Future<List<Ward>> getWards(int provinceCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/p/$provinceCode?depth=2'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final List<dynamic> wards = data['wards'] ?? [];
        return wards.map((json) => Ward.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load wards');
      }
    } catch (e) {
      throw Exception('Lỗi gọi API Phường/Xã: $e');
    }
  }
}
