import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final Dio _dio;

  ApiClient._internal()
      : _dio = Dio(BaseOptions(
          baseUrl: dotenv.env['API_URL']!,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 3),
        ));

  Dio get dio => _dio;
}
