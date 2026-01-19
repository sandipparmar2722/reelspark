import 'package:dio/dio.dart';

class ProductApi {
  final Dio _dio;

  ProductApi({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetch product list. Returns a List<dynamic> of products.
  Future<List<dynamic>> fetchProducts() async {
    final response = await _dio.get('https://dummyjson.com/products');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map && data.containsKey('products')) {
        return List<dynamic>.from(data['products'] as List);
      }
      return List<dynamic>.from(data as List);
    }

    throw Exception('Failed to fetch products: ${response.statusCode}');
  }
}

