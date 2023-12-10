library my_prj.lazo_utils;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_couriers/app/commons/models/distance_matrix.dart';
import 'package:geo_couriers/app/commons/models/parcels_model.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geodesy/geodesy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../main.dart';

bool isInteger(num? value) =>
    value is int || value == value!.roundToDouble();

showAlertDialog(BuildContext context, String? alertText, String title) {

  bool showTitle = true;
  if(title.isEmpty) {
    showTitle = false;
  }

  AlertDialog alert;
  if(showTitle) {
    alert = AlertDialog(
      title: Text(
        title,
        textAlign: TextAlign.center,
      ),
      content: Text(
        alertText!,
        textAlign: TextAlign.center,
      ),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
          side: BorderSide(color: Colors.black)
      ),
    );
  } else {
    alert = AlertDialog(
      content: Text(
        alertText!,
        textAlign: TextAlign.center,
      ),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
          side: BorderSide(color: Colors.black)
      ),
    );
  }
  // set up the AlertDialog


  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

Card generateCard(child, marginVertical) {
  return Card(
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.symmetric(
      vertical: marginVertical ==null ? 10 : marginVertical,
      horizontal: 25.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50.0),
    ),
    // color: Colors.white,
    child: Padding(
        padding: EdgeInsets.only(
            left: 10.0, right: 10.0, top: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Flexible(
                child: child
            ),
          ],
        )),
  );
}

double coordinateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

double roundDouble(double value, int places){
  double mod = pow(10.0, places) as double;
  return ((value * mod).round().toDouble() / mod);
}

Future<List<dynamic>?> getPlaceViaCoordinates(lat, lng, _kGoogleApiKey, context) async {

  final response = await defaultDio.get(dotenv.env['COMMON_GOOGLE_URL']! +'geocode/json?latlng=$lat,$lng&key=$_kGoogleApiKey');

  if (response.statusCode != 200) {
    return null;
  }

  return response.data['results'][0]['address_components'];
}

Future<String?> getPlaceFormattedAddressViaCoordinates(lat, lng, _kGoogleApiKey, context) async {

  final response = await defaultDio.get(dotenv.env['COMMON_GOOGLE_URL']! +'geocode/json?latlng=$lat,$lng&key=$_kGoogleApiKey');

  if (response.statusCode != 200) {
    return null;
  }

  return response.data['results'][0]['formatted_address'];
}

Future<AutocompleteResponse?> getPlaceAutocompletePredictions(value, _kGoogleApiKey, context) async {

  final response = await defaultDio.get(dotenv.env['COMMON_GOOGLE_URL']! +'place/autocomplete/json?input=$value&key=$_kGoogleApiKey');

  if (response.statusCode != 200) {
    return null;
  }

  return AutocompleteResponse.fromJson(response.data);
}

Future<DetailsResponse?> getPlaceDetails(placeId, _kGoogleApiKey, context) async {

  final response = await defaultDio.get(dotenv.env['COMMON_GOOGLE_URL']! +'place/details/json?place_id=$placeId&key=$_kGoogleApiKey');

  if (response.statusCode != 200) {
    return null;
  }

  return DetailsResponse.fromJson(response.data);
}

Future<DistanceMatrix?> getDistanceMatrix(originsLat, originsLng, destinationsLat, destinationsLng, _kGoogleApiKey, context) async {

  final response = await defaultDio.get(dotenv.env['COMMON_GOOGLE_URL']! +'distancematrix/json?origins=$originsLat,$originsLng&destinations=$destinationsLat,$destinationsLng&key=$_kGoogleApiKey');

  if (response.statusCode != 200) {
    return null;
  }
  try{
    DistanceMatrix distanceMatrix = new DistanceMatrix.fromJson(response.data);
    return distanceMatrix;
  } catch (e) {
    return null;
  }
}

//თარიღისა და დროის ფანჯრები
Future<DateTime?> selectDate(BuildContext context, helpText) async {
  DateTime? date = await showDatePicker(
      helpText: helpText,
      cancelText: AppLocalizations.of(context)!.do_not_specify,
      confirmText: AppLocalizations.of(context)!.indicate,
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900, 8),
      lastDate: DateTime(2101)
  );
  if (date ==null) {
    return null;
  }

  TimeOfDay? time = await showTimePicker(
    context: context,
    cancelText: AppLocalizations.of(context)!.do_not_specify,
    confirmText: AppLocalizations.of(context)!.indicate,
    initialTime: TimeOfDay.now(),
    builder: (BuildContext context, Widget? child) {
      return MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(alwaysUse24HourFormat: false),
        child: child!,
      );
    },);

  return DateTime(date.year, date.month, date.day, time!.hour, time.minute);
}


Future<bool> checkIfCurrentPositionInDistanceFromGivenLocation(String? lat, String? lnt, num distance) async {
  if (lat ==null ||
      lat.isEmpty ||
      lnt ==null ||
      lnt.isEmpty
  ) {
    return false;
  }

  Geodesy geodesy = Geodesy();
  Position position = await Geolocator.getCurrentPosition();

  final distanceFromCurrentPosition = geodesy.distanceBetweenTwoGeoPoints(LatLng(position.latitude, position.longitude), LatLng(double.parse(lat), double.parse(lnt)));
  if (distanceFromCurrentPosition <= distance) {
    return true;
  }
  return false;
}


List<int?> getNearParcelsThatCanBeDelivered(List<Parcels> parcels, String? pointLat, String? pointLng, num distance, num? doneOrderId) {
  List<int?> _parcelIdsList = List<int?>.empty(growable: true);
  if (parcels.isEmpty ||
      pointLat ==null ||
      pointLat == "" ||
      pointLng ==null ||
      pointLng == "" ||
      doneOrderId ==null
  ) {
    return _parcelIdsList;
  }

  Geodesy geodesy = Geodesy();
  var point = LatLng(double.parse(pointLat), double.parse(pointLng));

  for (final p in parcels) {

    if (p.parcelAddressToBeDeliveredLatitude ==null ||
        p.parcelAddressToBeDeliveredLatitude =="" ||
        p.parcelAddressToBeDeliveredLongitude ==null ||
        p.parcelAddressToBeDeliveredLongitude ==""
    ) {
      continue;
    }
    if (p.arrivalInProgress! && p.orderStatus !=null && p.orderStatus == "ACTIVE") {
      final distanceFromCenter = geodesy.distanceBetweenTwoGeoPoints(point, LatLng(double.parse(p.parcelAddressToBeDeliveredLatitude!), double.parse(p.parcelAddressToBeDeliveredLongitude!)));
      if (distanceFromCenter <= distance && doneOrderId !=p.orderId) {
        _parcelIdsList.add(p.orderId);
      }
    }
  }
  return _parcelIdsList;
}


showParcelInfoDialog(Parcels item, BuildContext context, String _kGoogleApiKey) async {

  var _takeawayAddress = await getPlaceFormattedAddressViaCoordinates(item.parcelPickupAddressLatitude, item.parcelPickupAddressLongitude, _kGoogleApiKey, context);
  if (_takeawayAddress ==null) {
    return null;
  }

  var _deliveryAddress = await getPlaceFormattedAddressViaCoordinates(item.parcelAddressToBeDeliveredLatitude, item.parcelAddressToBeDeliveredLongitude, _kGoogleApiKey, context);
  if (_deliveryAddress ==null) {
    return null;
  }

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          item.serviceParcelIdentifiable!,
          textAlign: TextAlign.center,
        ),
        content: RichText(
          text: TextSpan(
            text: AppLocalizations.of(context)!.comment + ": ",
            style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold
            ),
            children: <TextSpan>[
              TextSpan(
                  text: item.orderComment! + "\n",
                  style: TextStyle(
                    color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                  )
              ),
              TextSpan(
                text: AppLocalizations.of(context)!.takeaway_address + ": ",
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold
                ),
              ),
              TextSpan(
                  text: _takeawayAddress + "\n",
                  style: TextStyle(
                    color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                  )
              ),
              TextSpan(
                text: AppLocalizations.of(context)!.delivery_address + ": ",
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold
                ),
              ),
              TextSpan(
                  text: _deliveryAddress,
                  style: TextStyle(
                    color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                  )
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
            side: BorderSide(color: Colors.black)
        ),
      );
    },
  );
}


Future<bool> openGoogleMap(double latitude, double longitude) async {
  try {
    Position position = await Geolocator.getCurrentPosition();
    var lat = position.latitude;
    var lon = position.longitude;

    var url ='https://www.google.com/maps/dir/?api=1&origin=$lat,$lon&destination=$latitude,$longitude&travelmode=driving';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    return true;
  } catch (e) {
    throw e.toString();
  }
}

Future<void> openGoogleMapMultipleLocations(String destination, String waypoints, Position position) async {
  try {

    var latitude = position.latitude;
    var longitude = position.longitude;

    // https://www.google.com/maps/dir/?api=1&origin=12.909227,77.6343&destination=12.909228,77.6343&travelmode=driving&waypoints=12.909188,77.6323|12.91044,77.632507|12.911389,77.632912
    var url ='https://www.google.com/maps/dir/?api=1&origin=$latitude,$longitude&destination=$destination&waypoints=$waypoints&travelmode=driving';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (e) {
    throw e.toString();
  }
}

Future<void> openMap(double latitude, double longitude, String serviceParcelIdentifiable, context) async {
  if (!await openGoogleMap(latitude, longitude)) {
    showAlertDialog(context, " ", AppLocalizations.of(context)!.an_error_occurred);
  } else {
    // try {
    //
    //
    //   final SharedPreferences prefs = await SharedPreferences.getInstance();
    //   final cords = Coords(latitude, longitude);
    //
    //   var mapType;
    //
    //   for (final m in MapType.values) {
    //     if (prefs.get("map_type").toString() == m.toString()) {
    //       mapType = m;
    //       break;
    //     }
    //   }
    //
    //   if (mapType!=null) {
    //
    //     var aa = await MapLauncher.isMapAvailable(mapType);
    //     if (aa!) {
    //       await MapLauncher.showMarker(
    //         mapType: mapType,
    //         coords: cords,
    //         title: serviceParcelIdentifiable,
    //       );
    //     }
    //   } else {
    //     final availableMaps = await MapLauncher.installedMaps;
    //
    //     showModalBottomSheet(
    //       context: context,
    //       builder: (BuildContext context) {
    //         return SafeArea(
    //           child: SingleChildScrollView(
    //             child: Container(
    //               child: Wrap(
    //                 children: <Widget>[
    //                   for (var map in availableMaps)
    //                     ListTile(
    //                       onTap: () async {
    //                         await showDialog(
    //                             context: context,
    //                             builder: (context) => AlertDialog(
    //                               title: Text(' '),
    //                               content: Text("ginda kaloche am mapis damaxsovreba"),
    //                               actions: <Widget>[
    //                                 OutlinedButton(
    //                                   child: Text(AppLocalizations.of(context)!.yes),
    //                                   onPressed: () {
    //                                     prefs.setString("map_type", map.mapType.toString());
    //                                     Navigator.pop(context,false);
    //                                   }, //exit the app
    //                                 ),
    //                                 OutlinedButton(
    //                                   child: Text(AppLocalizations.of(context)!.no),
    //                                   onPressed: ()=> Navigator.pop(context,false),
    //                                 )
    //                               ],
    //                             )
    //                         );
    //
    //                         map.showMarker(
    //                           coords: cords,
    //                           title: serviceParcelIdentifiable,
    //                         );
    //                       },
    //                       title: Text(map.mapName),
    //                       leading: SvgPicture.asset(
    //                         map.icon,
    //                         height: 30.0,
    //                         width: 30.0,
    //                       ),
    //                     ),
    //                 ],
    //               ),
    //             ),
    //           ),
    //         );
    //       },
    //     );
    //   }
    // } catch (e) {
    //   print(e);
    // }
  }
}

void navigateToLastPage(context) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? lastRoute = prefs.getString('last_route');
  if(lastRoute ==null) {
    return;
  }
  if (lastRoute.isNotEmpty && lastRoute != '/') {
    Navigator.of(context).pushNamed(lastRoute);
  }
}

showToast(context, toastDuration, text) {
  FToast fToast = FToast();
  fToast.init(context);

  Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.deepOrange,
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 15
          )
      )
  );

  fToast.showToast(
      gravity: ToastGravity.TOP,
      toastDuration: toastDuration,
      child: toast
  );
}


Future<Uint8List> getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}
