import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductRemoteDataSource {
  static const String baseUrl = 'http://localhost:5000/api';
  final String _token;

  ProductRemoteDataSource(this._token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['products'];
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<Map<String, dynamic>> createProduct(String name, String description, int threshold) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: _headers,
      body: json.encode({
        'name': name,
        'description': description,
        'threshold': threshold,
      }),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create product');
    }
  }

  Future<Map<String, dynamic>> receiveItem(int productId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products/$productId/receive'),
      headers: _headers,
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to receive item');
    }
  }

  Future<Map<String, dynamic>> dispatchItem(String barcodeData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/items/dispatch'),
      headers: _headers,
      body: json.encode({'barcode_data': barcodeData}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to dispatch item');
    }
  }

  Future<List<dynamic>> getAlerts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/alerts'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['alerts'];
    } else {
      throw Exception('Failed to load alerts');
    }
  }
}