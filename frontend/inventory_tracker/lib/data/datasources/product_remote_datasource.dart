import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductRemoteDataSource {
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  final String _token;

  ProductRemoteDataSource(this._token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  Future<List<dynamic>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['products'] ?? [];
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> createProduct(
    String name,
    String description,
    int threshold, {
    String? imagePath,
  }) async {
    final uri = Uri.parse('$baseUrl/products/create');
    var request = http.MultipartRequest('POST', uri)
      ..fields['name'] = name
      ..fields['description'] = description
      ..fields['threshold'] = threshold.toString();

    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    request.headers['Authorization'] = 'Bearer $_token';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create product: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> receiveItem(int productId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/receive'),
        headers: _headers,
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to receive item');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> dispatchItem(String barcodeData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/items/dispatch'),
        headers: _headers,
        body: json.encode({'barcode_data': barcodeData}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to dispatch item');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<dynamic>> getAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/alerts'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['alerts'];
      } else {
        throw Exception('Failed to load alerts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
