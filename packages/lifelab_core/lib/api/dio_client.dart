import 'package:dio/dio.dart';

class DioClient {
  static const String baseUrl = 'https://lifeos-api.lablogicapp.workers.dev';
  late final Dio dio;

  DioClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }
}
