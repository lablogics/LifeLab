import 'dio_client.dart';

class ApiClient {
  late final DioClient dioClient;
  ApiClient() { dioClient = DioClient(); }
  DioClient get dio => dioClient;
}
