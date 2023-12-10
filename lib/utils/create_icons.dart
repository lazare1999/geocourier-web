import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

BitmapDescriptor? myIcon = BitmapDescriptor.defaultMarker;

BitmapDescriptor? blackCar;
BitmapDescriptor? blackExpressCar;
BitmapDescriptor? blackFood;
BitmapDescriptor? blackExpressFood;
BitmapDescriptor? blackTruck;
BitmapDescriptor? blackTruckExpress;

BitmapDescriptor? greenCar;
BitmapDescriptor? greenExpressCar;
BitmapDescriptor? greenFood;
BitmapDescriptor? greenExpressFood;
BitmapDescriptor? greenTruck;
BitmapDescriptor? greenTruckExpress;

BitmapDescriptor? redCar;
BitmapDescriptor? redExpressCar;
BitmapDescriptor? redFood;
BitmapDescriptor? redExpressFood;
BitmapDescriptor? redTruck;
BitmapDescriptor? redTruckExpress;

BitmapDescriptor? stackedParcels;

Future<void> populateIcons() async {

  blackCar = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/black/car.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/black/car.png', 200));
  blackExpressCar = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/black/car_express.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/black/car_express.png', 200));
  blackFood = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/black/food.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/black/food.png', 200));
  blackExpressFood = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/black/food_express.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/black/food_express.png', 200));
  blackTruck = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/black/truck.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/black/truck.png', 200));
  blackTruckExpress = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/black/truck_express.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/black/truck_express.png', 200));

  greenCar = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/green/car.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/green/car.png', 200));
  greenExpressCar = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/green/car_express.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/green/car_express.png', 200));
  greenFood = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/green/food.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/green/food.png', 200));
  greenExpressFood = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/green/food_express.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/green/food_express.png', 200));
  greenTruck = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/green/truck.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/green/truck.png', 200));
  greenTruckExpress = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/green/truck_express.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/green/truck_express.png', 200));


  redCar = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/red/car.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/red/car.png', 200));
  redExpressCar = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/red/car_express.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/red/car_express.png', 200));
  redFood = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/red/food.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/red/food.png', 200));
  redExpressFood = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/red/food_express.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/red/food_express.png', 200));
  redTruck = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/red/truck.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/red/truck.png', 200));
  redTruckExpress = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/images/parcels/red/truck_express.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/images/parcels/red/truck_express.png', 200));

  stackedParcels = kIsWeb
      ? await BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(50, 60)), 'assets/icons/courier.png')
      : BitmapDescriptor.fromBytes(await getBytesFromAsset('assets/icons/courier.png', 200));

}