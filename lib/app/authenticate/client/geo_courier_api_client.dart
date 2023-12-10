import 'package:dio/dio.dart';
import 'geo_couriers_api_interseptor.dart';

class GeoCourierApiClient {

  static final Dio _dio = Dio();

  Dio getApiClient() {
    _dio.interceptors.clear();
    _dio.interceptors.add(GeoCouriersApiInterceptor());
    return _dio;
  }


}