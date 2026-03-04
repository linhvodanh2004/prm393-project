import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageService {
  // Upload an avatar to Cloudinary
  Future<String?> uploadAvatarToCloudinary(String uid, File imageFile) async {
    try {
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      final apiKey = dotenv.env['CLOUDINARY_API_KEY'];
      final apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];

      if (cloudName == null || apiKey == null || apiSecret == null) {
        print('Cloudinary credentials missing in .env');
        return null;
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
          .toString();
      final publicId =
          'avatar_$uid'; // Force the ID to be the user's UID for rewrites

      // Create signature according to Cloudinary spec:
      // All params (except file, api_key, resource_type, cloud_name) sorted alphabetically -> SHA-1 with apiSecret appended
      // Alphabetical order: overwrite -> public_id -> timestamp
      final stringToSign =
          'overwrite=true&public_id=$publicId&timestamp=$timestamp$apiSecret';

      var bytes = utf8.encode(stringToSign);
      var signature = sha1.convert(bytes).toString();

      var uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      var request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp
        ..fields['public_id'] = publicId
        ..fields['overwrite'] = 'true'
        ..fields['signature'] = signature
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        // We append a random version parameter to the URL to bypass the NetworkImage cache
        // Cloudinary native URLs automatically ignore query parameters, but Flutter's NetworkImage respects them
        final cleanUrl = jsonResponse['secure_url'];
        return '$cleanUrl?v=$timestamp';
      } else {
        print('Cloudinary upload error: ${jsonResponse['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Cloudinary exception: $e');
      return null;
    }
  }

  // Delete an avatar from Cloudinary using its secure URL
  Future<bool> deleteAvatarFromCloudinary(String secureUrl) async {
    try {
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      final apiKey = dotenv.env['CLOUDINARY_API_KEY'];
      final apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];

      if (cloudName == null || apiKey == null || apiSecret == null) {
        print('Cloudinary credentials missing for deletion.');
        return false;
      }

      // Extract the public_id from the URL (e.g. https://res.cloudinary.com/../image/upload/v1234/avatar_xyz.jpg?v=xxx)
      Uri uriInfo = Uri.parse(secureUrl);
      String path = uriInfo
          .path; // e.g. /v1_1/dho7lr4yu/image/upload/v1234/avatar_xyz.jpg
      String filename = path.split('/').last; // e.g. avatar_xyz.jpg
      String publicId = filename.split('.').first; // e.g. avatar_xyz

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
          .toString();

      // Signature for destroy: public_id -> timestamp
      final stringToSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';

      var bytes = utf8.encode(stringToSign);
      var signature = sha1.convert(bytes).toString();

      var uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
      );
      var response = await http.post(
        uri,
        body: {
          'api_key': apiKey,
          'public_id': publicId,
          'timestamp': timestamp,
          'signature': signature,
        },
      );

      var jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['result'] == 'ok') {
        print('Cloudinary: Successfully deleted $publicId');
        return true;
      } else {
        print(
          'Cloudinary delete error: ${jsonResponse['error']?['message'] ?? jsonResponse}',
        );
        return false;
      }
    } catch (e) {
      print('Cloudinary deletion exception: $e');
      return false;
    }
  }
}
