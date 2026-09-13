import 'package:dio/dio.dart';
import '../../auth/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  AuthInterceptor(this.tokenStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenStorage.getSession();
    if (token != null) {
      options.headers['Cookie'] = 'session=$token';
    }
    handler.next(options);
  }
}
