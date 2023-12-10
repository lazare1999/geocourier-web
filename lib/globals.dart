import 'package:dio/dio.dart';
import 'package:geo_couriers/app/authenticate/client/geo_courier_api_client.dart';

var geoCourierClient = GeoCourierApiClient().getApiClient();
var defaultDio = Dio();