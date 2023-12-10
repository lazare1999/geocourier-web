import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/commons/mini_menu/mini_menu.dart';
import 'package:geo_couriers/app/roles/courier/main/start_delivering_parcel_page.dart';
import 'package:geo_couriers/app/commons/info/info.dart';
import 'package:geo_couriers/app/commons/animation_controller_class.dart';
import 'package:geo_couriers/app/commons/models/parcels_model.dart';
import 'package:geo_couriers/app/main_menu.dart';
import 'package:geo_couriers/app/roles/courier/orders_control_panel/courier_orders_control_panel.dart';
import 'package:geo_couriers/app/roles/courier/windows/jobs_window_page.dart';
import 'package:geo_couriers/app/roles/courier/windows/near_parcels_window_page.dart';
import 'package:geo_couriers/app/roles/courier/windows/parcels_window_page.dart';
import 'package:geo_couriers/app/roles/courier/windows/stacked_parcels_window_page.dart';
import 'package:geo_couriers/app/roles/courier/windows/working_mode_parcels_window_page.dart';
import 'package:geo_couriers/globals.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geo_couriers/app/roles/courier/parcel_locations.dart' as locations;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../main.dart';
import '../../../../utils/create_icons.dart';

class CourierMainPage extends StatefulWidget {

  final String? kGoogleApiKey;

  CourierMainPage({required this.kGoogleApiKey});
  
  @override
  _CourierMainPage createState() => _CourierMainPage(kGoogleApiKey: kGoogleApiKey);
}

// TODO : კურიერს უჩანდეს კონკრეტულ ამანათზე მუშაობისას რამდენი უნდა მისცენ ხელზე
class _CourierMainPage extends State<CourierMainPage> {

  final String? kGoogleApiKey;

  _CourierMainPage({required this.kGoogleApiKey});

  num searchRadiusDistance = 100;
  late GoogleMapController controllerCouriersMainPage;
  final Map<int?, Marker> markersCouriersMainPage = {};
  List<int?> alreadyOpenParcelJobWindowParcelIdList = List<int?>.empty(growable: true);
  bool scrollGesturesEnabled = true;

  Icon? btnOneIcon;

  bool selectJobMode = true;
  bool workingMode = false;

  bool hideCartButton = false;
  bool hideParcelListButton = true;
  bool hideWriteOffParcelButton = true;

  late LatLng centerCourier;
  bool disableMarkerInfoWindowClick = false;
  bool doNotUpdateParcelsList = false;

  final GlobalKey<ScaffoldState> scaffoldKeyCourierMainPage = GlobalKey();

  Future<void> _onMapCreated(GoogleMapController controller) async {
    controllerCouriersMainPage = controller;
  }

  Future<void> _update(LatLng latLng) async {
    controllerCouriersMainPage.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: latLng,
      zoom: 13.0,
    )));
  }

  _markerOnTab(parcel, position, _foCourier, _parcels) async {
    if (disableMarkerInfoWindowClick) {
      return;
    }

    if (alreadyOpenParcelJobWindowParcelIdList.contains(parcel.orderId)) {
      return;
    }
    doNotUpdateParcelsList = true;
    setState(() {
      alreadyOpenParcelJobWindowParcelIdList.add(parcel.orderId);
      scrollGesturesEnabled = !scrollGesturesEnabled;
      disableMarkerInfoWindowClick = true;
    });
    if (selectJobMode) {
      showDialog(
        context: context,
        useSafeArea: false,
        useRootNavigator: false,
        builder: (context) => AlertDialog(
          content: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: ParcelsWindowPage(update: _update, orderJobId: parcel.jobId, kGoogleApiKey: kGoogleApiKey),
          ),
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
              side: BorderSide(color: Colors.black)
          ),
        ),
      ).then((value) {
        scrollGesturesEnabled = !scrollGesturesEnabled;
        alreadyOpenParcelJobWindowParcelIdList.remove(parcel.orderId);
        disableMarkerInfoWindowClick = false;
        doNotUpdateParcelsList = false;
        setState(() {});
      });
    } else if (workingMode) {
      if (_foCourier && parcel.arrivalInProgress! && parcel.orderStatus !=null && parcel.orderStatus == "ACTIVE") {

        var _distanceBetweenCourierAndDeliver = await getDistanceMatrix(position.latitude,
            position.longitude, parcel.parcelAddressToBeDeliveredLatitude,
            parcel.parcelAddressToBeDeliveredLongitude, kGoogleApiKey, context);

        var _distanceAndTimeBlack = RichText(
          text: TextSpan(
            text: AppLocalizations.of(context)!.courier_position + ": ",
            style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold
            ),
            children: <TextSpan>[
              TextSpan(
                  text: _distanceBetweenCourierAndDeliver!.origins.toString() + "\n",
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
                  text: _distanceBetweenCourierAndDeliver.destinations.toString() + "\n",
                  style: TextStyle(
                    color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                  )
              ),
              TextSpan(
                text: AppLocalizations.of(context)!.distance + ": ",
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold
                ),
              ),
              TextSpan(
                  text: _distanceBetweenCourierAndDeliver.elements[0].distance.text.toString() + "\n",
                  style: TextStyle(
                    color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                  )
              ),
              TextSpan(
                text: AppLocalizations.of(context)!.time + ": ",
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold
                ),
              ),
              TextSpan(
                  text: _distanceBetweenCourierAndDeliver.elements[0].duration.text.toString(),
                  style: TextStyle(
                    color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                  )
              ),
            ],
          ),
        );

        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: RichText(
                    text: TextSpan(
                        text: AppLocalizations.of(context)!.hand_overed_parcel + "\n",
                        style: TextStyle(
                            color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: parcel.serviceParcelIdentifiable,
                            style: TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0
                            ),
                          ),
                        ]
                    )
                ),
                content: _distanceAndTimeBlack,
                actions: [
                  Center(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        side: BorderSide(width: 2, color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: Center(child: Text(AppLocalizations.of(context)!.jobs_done,
                                  style: TextStyle(
                                      color: Colors.green
                                  )))
                          )
                        ],
                      ),
                      onPressed: () async {
                        if (kIsWeb) {
                          return;
                        }
                        if(await checkIfCurrentPositionInDistanceFromGivenLocation(parcel.parcelAddressToBeDeliveredLatitude, parcel.parcelAddressToBeDeliveredLongitude, searchRadiusDistance)) {
                          try {

                            final res = await geoCourierClient.post(
                              'orders_courier/jobs_done',
                              queryParameters: {
                                "orderId": parcel.orderId.toString(),
                              },
                            );

                            if(res.statusCode ==200) {
                              showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(' '),
                                    content: Text(searchRadiusDistance.toString() + " " + AppLocalizations.of(context)!.near_parcels_info_text),
                                    actions: <Widget>[
                                      OutlinedButton(
                                        child: Text(AppLocalizations.of(context)!.yes),
                                        onPressed: () {
                                          var _nearParcels = getNearParcelsThatCanBeDelivered(_parcels, parcel.parcelAddressToBeDeliveredLatitude, parcel.parcelAddressToBeDeliveredLongitude, searchRadiusDistance, parcel.orderId);
                                          if (_nearParcels.isNotEmpty) {
                                            List<Parcels> _parcelsToDisplay = List<Parcels>.empty(growable: true);
                                            _parcels.forEach((element) {
                                              if (_nearParcels.contains(element.orderId)) {
                                                _parcelsToDisplay.add(element);
                                              }
                                            });

                                            showDialog(
                                              context: context,
                                              useSafeArea: false,
                                              useRootNavigator: false,
                                              builder: (context) => AlertDialog(
                                                content: Container(
                                                  height: MediaQuery.of(context).size.height * 0.7,
                                                  child: NearParcelsWindowPage(parcelsToDisplay: _parcelsToDisplay, searchRadiusDistance: searchRadiusDistance, kGoogleApiKey: kGoogleApiKey),
                                                ),
                                                contentPadding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(18.0),
                                                    side: BorderSide(color: Colors.black)
                                                ),
                                              ),
                                            ).then((value) {
                                              Navigator.pop(context,false);
                                              Navigator.pop(context,false);
                                            });
                                          } else {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  content: Text(
                                                    AppLocalizations.of(context)!.near_parcels_can_not_found,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(18.0),
                                                      side: BorderSide(color: Colors.black)
                                                  ),
                                                );
                                              },
                                            ).then((value) {
                                              Navigator.pop(context,false);
                                              Navigator.pop(context,false);
                                            });
                                          }
                                        }, //exit the app
                                      ),
                                      OutlinedButton(
                                        child: Text(AppLocalizations.of(context)!.no),
                                        onPressed: () {
                                          Navigator.pop(context,false);
                                          Navigator.pop(context,false);
                                        },
                                      )
                                    ],
                                  )
                              );

                              if(res.data == false) {
                                showAlertDialog(context, "", AppLocalizations.of(context)!.express_expired);
                              }

                            }
                          } catch (e) {
                            if (e is DioException && e.response?.statusCode == 403) {
                              reloadApp(context);
                            } else {
                              showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
                            }
                            return;
                          }
                        } else {
                          showAlertDialog(context, AppLocalizations.of(context)!.you_are_not_close_to_the_parcel, "");
                        }
                      }, //exit the app
                    ),
                  ),
                  Center(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        side: BorderSide(width: 2, color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: Center(child: Text(AppLocalizations.of(context)!.write_down_parcel,
                                  style: TextStyle(
                                      color: Colors.red
                                  )))
                          )
                        ],
                      ),
                      onPressed: ()  {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(' '),
                              content: Text(AppLocalizations.of(context)!.write_off_parcel_question),
                              actions: <Widget>[
                                OutlinedButton(
                                  child: Text(AppLocalizations.of(context)!.yes),
                                  onPressed: () {
                                    Navigator.pop(context,false);
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                            actions: <Widget>[
                                              OutlinedButton(
                                                child: Text(AppLocalizations.of(context)!.call_to_store,
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                  ),
                                                ),
                                                onPressed: () async {

                                                  try {

                                                    final res = await geoCourierClient.post(
                                                        'get_phone_by_user_id',
                                                        queryParameters: {
                                                          "senderUserId": parcel.senderUserId.toString(),
                                                        }
                                                    );
                                                    launchUrl(Uri.parse('tel:' + res.data));
                                                  } catch (e) {

                                                  }
                                                }, //e/exit the app
                                              ),
                                              OutlinedButton(
                                                  child: Text(AppLocalizations.of(context)!.write_down_parcel,
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    try {

                                                      final res = await geoCourierClient.post(
                                                        'orders_courier/set_parcel_as_unsuccessful',
                                                        queryParameters: {
                                                          "orderId": parcel.orderId.toString(),
                                                        },
                                                      );

                                                      if(res.statusCode ==200) {
                                                        Navigator.pop(context,false);
                                                        Navigator.pop(context,false);
                                                        setState(() {});

                                                        if(res.data == false) {
                                                          showAlertDialog(context, "", AppLocalizations.of(context)!.express_expired);
                                                        }

                                                      }
                                                    } catch (e) {
                                                      if (e is DioException && e.response?.statusCode == 403) {
                                                        reloadApp(context);
                                                      } else {
                                                        showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
                                                      }
                                                      return;
                                                    }
                                                  }
                                              )
                                            ],
                                            actionsPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0)
                                        )
                                    );
                                  }, //exit the app
                                ),
                                OutlinedButton(
                                  child: Text(AppLocalizations.of(context)!.no),
                                  onPressed: ()=> Navigator.pop(context,false),
                                )
                              ],
                            )
                        );


                      }, //exit the app
                    ),
                  ),
                  Center(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        side: BorderSide(width: 2, color: Colors.blue),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: Center(child: Text(AppLocalizations.of(context)!.start_handing_over,
                                  style: TextStyle(
                                      color: Colors.blue
                                  )))
                          )
                        ],
                      ),

                      onPressed: () async {

                        //შავი
                        if (!kIsWeb) {
                          try {

                            final res = await geoCourierClient.post(
                              'orders_buyer/get_courier_user_id_by_job_id',
                              queryParameters: {
                                "jobId": parcel.jobId.toString(),
                              },
                            );

                            if(res.statusCode ==200) {
                              var body = res.data;
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => StartDeliveringParcelPage(parcels: _parcels, parcel: parcel, kGoogleApiKey: kGoogleApiKey, courierUserId: body)),
                              );
                            }
                          } catch (e) {
                            if (e is DioException && e.response?.statusCode == 403) {
                              reloadApp(context);
                            } else {
                              showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
                            }
                            return;
                          }
                        }

                        var latitude = double.parse(parcel.parcelAddressToBeDeliveredLatitude!);
                        var longitude = double.parse(parcel.parcelAddressToBeDeliveredLongitude!);
                        openMap(latitude, longitude, parcel.serviceParcelIdentifiable!, context);

                      }, //exit the app
                    ),
                  ),
                  Center(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        side: BorderSide(width: 2, color: Color.fromRGBO(218,165,32, 1.0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 1,
                              child: Icon(Icons.call, color: Color.fromRGBO(218,165,32, 1.0),)
                          ),
                          Expanded(
                              flex: 3,
                              child: Text(AppLocalizations.of(context)!.call_to_store,
                                  style: TextStyle(
                                      color: Color.fromRGBO(218,165,32, 1.0)
                                  ))
                          )
                        ],
                      ),
                      onPressed: () async {

                        try {

                          final res = await geoCourierClient.post(
                              'get_phone_by_user_id',
                              queryParameters: {
                                "senderUserId": parcel.senderUserId.toString(),
                              }
                          );

                          launchUrl(Uri.parse('tel:' + res.data));
                        } catch (e) {

                        }
                      },
                    ),
                  ),
                  Center(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        side: BorderSide(width: 2, color: Color.fromRGBO(218,165,32, 1.0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 1,
                              child: Icon(Icons.call, color: Color.fromRGBO(218,165,32, 1.0),)
                          ),
                          Expanded(
                              flex: 3,
                              child: Text(AppLocalizations.of(context)!.call_to_costumer,
                                  style: TextStyle(
                                      color: Color.fromRGBO(218,165,32, 1.0)
                                  ))
                          )
                        ],
                      ),
                      onPressed: () {
                        launchUrl(Uri.parse('tel:' + parcel.viewerPhone.toString()));
                      }, //exit the app
                    ),
                  ),
                ],
                actionsPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0)
            )
        ).then((value) {
          scrollGesturesEnabled = !scrollGesturesEnabled;
          alreadyOpenParcelJobWindowParcelIdList.remove(parcel.orderId);
          disableMarkerInfoWindowClick = false;
          doNotUpdateParcelsList = false;
          setState(() {});
        });
      } else {
        var _distanceBetweenTakeAndDest = await getDistanceMatrix(position.latitude,
            position.longitude, parcel.parcelPickupAddressLatitude,
            parcel.parcelPickupAddressLongitude, kGoogleApiKey, context);

        var _distanceAndTime = RichText(
          text: TextSpan(
            text: AppLocalizations.of(context)!.courier_position + ": ",
            style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold
            ),
            children: <TextSpan>[
              TextSpan(
                  text: _distanceBetweenTakeAndDest!.origins.toString() + "\n",
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
                  text: _distanceBetweenTakeAndDest.destinations.toString() + "\n",
                  style: TextStyle(
                    color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                  )
              ),
              TextSpan(
                text: AppLocalizations.of(context)!.distance + ": ",
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold
                ),
              ),
              TextSpan(
                  text: _distanceBetweenTakeAndDest.elements[0].distance.text.toString() + "\n",
                  style: TextStyle(
                    color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                  )
              ),
              TextSpan(
                text: AppLocalizations.of(context)!.time + ": ",
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold
                ),
              ),
              TextSpan(
                  text: _distanceBetweenTakeAndDest.elements[0].duration.text.toString(),
                  style: TextStyle(
                    color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                  )
              ),
            ],
          ),
        );
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: RichText(
                  text: TextSpan(
                      text: AppLocalizations.of(context)!.pick_up_parcel+ "\n",
                      style: TextStyle(
                          color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: parcel.serviceParcelIdentifiable,
                          style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.0
                          ),
                        ),
                      ]
                  )
              ),
              content: _distanceAndTime,
              actions: <Widget>[
                Center(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      side: BorderSide(width: 2, color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            child: Center(child: Text(AppLocalizations.of(context)!.take_parcel,
                                style: TextStyle(
                                    color: Colors.green
                                )))
                        )
                      ],
                    ),
                    onPressed: () async {
                      if (kIsWeb) {
                        return;
                      }

                      if(await checkIfCurrentPositionInDistanceFromGivenLocation(parcel.parcelPickupAddressLatitude, parcel.parcelPickupAddressLongitude, searchRadiusDistance)) {
                        try {

                          final res = await geoCourierClient.post(
                            'orders_courier/take_parcel',
                            queryParameters: {
                              "orderId": parcel.orderId.toString(),
                            },
                          );

                          if(res.statusCode ==200) {
                            Navigator.pop(context,false);

                            if(parcel.express!) {
                              var alertText = AppLocalizations.of(context)!.note_express_limit + "\n\n";
                              if (parcel.serviceDate !=null) {
                                alertText += AppLocalizations.of(context)!.must_deliver_exactly + parcel.serviceDate.toString();
                              }
                              if (parcel.serviceDateFrom !=null) {
                                alertText += AppLocalizations.of(context)!.must_deliver_from + parcel.serviceDateFrom.toString();
                              }
                              if (parcel.serviceDateTo !=null) {
                                alertText += AppLocalizations.of(context)!.must_deliver_to + parcel.serviceDateTo.toString();
                              }

                              showAlertDialog(context, alertText, AppLocalizations.of(context)!.attention);
                            }

                            setState(() {});
                          }
                        } catch (e) {
                          if (e is DioException && e.response?.statusCode == 403) {
                            reloadApp(context);
                          } else {
                            showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
                          }
                          return;
                        }

                      } else {
                        showAlertDialog(context, AppLocalizations.of(context)!.you_are_not_close_to_the_parcel, "");
                      }
                    }, //exit the app
                  ),
                ),
                Center(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      side: BorderSide(width: 2, color: Colors.blue),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            child: Center(child: Text(AppLocalizations.of(context)!.draw_path,
                                style: TextStyle(
                                    color: Colors.blue
                                )))
                        )
                      ],
                    ),
                    onPressed: () {
                      //წითელი
                      var latitude = double.parse(parcel.parcelPickupAddressLatitude!);
                      var longitude = double.parse(parcel.parcelPickupAddressLongitude!);
                      openMap(latitude, longitude, parcel.serviceParcelIdentifiable!, context);
                    }, //exit the app
                  ),
                ),
                Center(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      side: BorderSide(width: 2, color: Color.fromRGBO(218,165,32, 1.0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Icon(Icons.call, color: Color.fromRGBO(218,165,32, 1.0),)
                        ),
                        Expanded(
                            flex: 3,
                            child: Text(AppLocalizations.of(context)!.call_to_store,
                                style: TextStyle(
                                    color: Color.fromRGBO(218,165,32, 1.0)
                                ))
                        )
                      ],
                    ),
                    onPressed: () async {

                      try {

                        final res = await geoCourierClient.post(
                            'get_phone_by_user_id',
                            queryParameters: {
                              "senderUserId": parcel.senderUserId.toString(),
                            }
                        );

                        launchUrl(Uri.parse('tel:' + res.data));
                      } catch (e) {

                      }
                    }, //exit the app
                  ),
                ),
                Center(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      side: BorderSide(width: 2, color: Color.fromRGBO(218,165,32, 1.0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Icon(Icons.call, color: Color.fromRGBO(218,165,32, 1.0),)
                        ),
                        Expanded(
                            flex: 3,
                            child: Text(AppLocalizations.of(context)!.call_to_costumer,
                                style: TextStyle(
                                    color: Color.fromRGBO(218,165,32, 1.0)
                                ))
                        )
                      ],
                    ),
                    onPressed: () {
                      launchUrl(Uri.parse('tel:' + parcel.viewerPhone.toString()));
                    }, //exit the app
                  ),
                ),
              ],
            )
        ).then((value) {
          scrollGesturesEnabled = !scrollGesturesEnabled;
          alreadyOpenParcelJobWindowParcelIdList.remove(parcel.orderId);
          disableMarkerInfoWindowClick = false;
          doNotUpdateParcelsList = false;
          setState(() {});
        });
      }
    }
  }

  Future<bool> _courierMainPageLoad() async {

    if (!hideCartButton) {
      btnOneIcon = Icon(Icons.shopping_cart);
    }

    if (!hideParcelListButton) {
      btnOneIcon = Icon(Icons.open_in_browser_outlined);
    }

    if (!hideWriteOffParcelButton) {
      btnOneIcon = Icon(Icons.highlight_remove_rounded);
    }

    var _foCourier = false;
    if (workingMode) {
      _foCourier = true;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);

    centerCourier = LatLng(position.latitude, position.longitude);

    if (doNotUpdateParcelsList) {
      return true;
    }

    markersCouriersMainPage.clear();

    HashMap<LatLng, List<Parcels>> _stackedParcels = new HashMap<LatLng, List<Parcels>>();
    var _parcels = await locations.getParcels(context, _foCourier);
    for (final _parcel in _parcels!) {
      if (_parcel.parcelPickupAddressLatitude ==""
          || _parcel.parcelPickupAddressLongitude==null
          || _parcel.parcelAddressToBeDeliveredLatitude==""
          || _parcel.parcelAddressToBeDeliveredLongitude==null) {
        continue;
      }

      var _markerLatLng;
      if (_foCourier && _parcel.arrivalInProgress! && _parcel.orderStatus !=null && _parcel.orderStatus == "ACTIVE") {
        _markerLatLng = LatLng(double.parse(_parcel.parcelAddressToBeDeliveredLatitude!), double.parse(_parcel.parcelAddressToBeDeliveredLongitude!));
      } else {
        _markerLatLng = LatLng(double.parse(_parcel.parcelPickupAddressLatitude!), double.parse(_parcel.parcelPickupAddressLongitude!));
      }

      if(_stackedParcels[_markerLatLng] == null) {
        List<Parcels>? _tempList = <Parcels>[];
        _tempList.add(_parcel);
        _stackedParcels[_markerLatLng] = _tempList;

        if (!_foCourier && _parcel.orderStatus !=null && _parcel.orderStatus == "ACTIVE") {
          switch (_parcel.parcelType) {
            case "SMALL" : _parcel.express! ? myIcon = greenExpressCar : myIcon = greenCar; break;
            case "BIG" : _parcel.express! ? myIcon = greenTruckExpress : myIcon = greenTruck; break;
            case "FOOD" : _parcel.express! ? myIcon = greenExpressFood : myIcon = greenFood; break;
          }
        } else if (_foCourier && _parcel.arrivalInProgress! && _parcel.orderStatus !=null && _parcel.orderStatus == "ACTIVE") {
          switch (_parcel.parcelType) {
            case "SMALL" : _parcel.express! ? myIcon = blackExpressCar : myIcon = blackCar; break;
            case "BIG" : _parcel.express! ? myIcon = blackTruckExpress : myIcon = blackTruck; break;
            case "FOOD" : _parcel.express! ? myIcon = blackExpressFood : myIcon = blackFood; break;
          }
        } else {
          switch (_parcel.parcelType) {
            case "SMALL" : _parcel.express! ? myIcon = redExpressCar : myIcon = redCar; break;
            case "BIG" : _parcel.express! ? myIcon = redTruckExpress : myIcon = redTruck; break;
            case "FOOD" : _parcel.express! ? myIcon = redExpressFood : myIcon = redFood; break;
          }
        }

        markersCouriersMainPage[_parcel.orderId] = Marker(
            icon: myIcon!,
            onTap: () => _markerOnTab(_parcel, position, _foCourier, _parcels),
            markerId: MarkerId(_parcel.orderId.toString()),
            position: _markerLatLng
        );

      } else if (_stackedParcels[_markerLatLng]!.length >=1) {

        _stackedParcels[_markerLatLng]!.forEach((element) {
          markersCouriersMainPage.remove(element.orderId);
        });

        List<Parcels>? _tempList = <Parcels>[];
        _tempList = _stackedParcels[_markerLatLng];
        _tempList!.add(_parcel);
        _stackedParcels.remove(_markerLatLng);
        _stackedParcels[_markerLatLng] = _tempList;

        final marker = Marker(
          icon: stackedParcels!,
          markerId: MarkerId(_parcel.orderId.toString()),
          position: _markerLatLng,
          onTap: () {
            doNotUpdateParcelsList = true;
            setState(() {
              scrollGesturesEnabled = !scrollGesturesEnabled;
              disableMarkerInfoWindowClick = true;
            });
            showDialog(
              context: context,
              useSafeArea: false,
              useRootNavigator: false,
              builder: (context) => AlertDialog(
                content: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: StackedParcelsWindowPage(stackedParcels: _stackedParcels[_markerLatLng]!,
                      position: position, kGoogleApiKey: kGoogleApiKey, parcels: _parcels,
                      searchRadiusDistance: searchRadiusDistance, workingMode: workingMode,
                      selectJobMode: selectJobMode, controllerCouriersMainPage: controllerCouriersMainPage),
                ),
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.black)
                ),
              ),
            ).then((value) {
              scrollGesturesEnabled = !scrollGesturesEnabled;
              disableMarkerInfoWindowClick = false;
              doNotUpdateParcelsList = false;
              setState(() {});
            });
          }
        );
        markersCouriersMainPage[_parcel.orderId] = marker;

      }
    }

    return true;
  }

  Future<bool> _onBackPressed(){
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MainMenu()),
    ).then((x) => x ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: _courierMainPageLoad(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return PopScope(
                canPop: true,
                onPopInvoked: (bool didPop) {
                  _onBackPressed();
                },
                child: Scaffold(
                  key: scaffoldKeyCourierMainPage,
                  resizeToAvoidBottomInset: false,
                  appBar: AppBar(
                    actions: <Widget>[
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                        ),
                        onPressed: () {
                          scaffoldKeyCourierMainPage.currentState!.openEndDrawer();
                        },
                      )
                    ],
                  ),
                  drawer: Drawer(
                      child: MiniMenu()
                  ),
                  endDrawer: Drawer(
                        child: Info(
                          safeAreaChild: ListView(
                            children: <Widget>[
                              ListTile(
                                title: Row(
                                  children: <Widget>[
                                    Icon(Icons.shopping_cart, color: Colors.deepOrange),
                                    Flexible(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Text(AppLocalizations.of(context)!.go_to_parcels_orders_section),
                                        )
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                  color: Colors.black
                              ),
                              ListTile(
                                title: Row(
                                  children: <Widget>[
                                    Icon(Icons.code, color: Colors.deepOrange),
                                    Flexible(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Text(AppLocalizations.of(context)!.working_mode),
                                        )
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                  color: Colors.black
                              ),
                              ListTile(
                                title: Row(
                                  children: <Widget>[
                                    Icon(Icons.list_alt_rounded, color: Colors.deepOrange),
                                    Flexible(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Text(AppLocalizations.of(context)!.available_jobs),
                                        )
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                  color: Colors.black
                              ),
                              ListTile(
                                title: Row(
                                  children: <Widget>[
                                    Image.asset('assets/images/parcels/green/empty.png', width: 30, height: 30,),
                                    Flexible(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 5.0),
                                          child: Text(AppLocalizations.of(context)!.courier_main_page_info_1),
                                        )
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                  color: Colors.black
                              ),
                              ListTile(
                                title: Row(
                                  children: <Widget>[
                                    Image.asset('assets/images/parcels/black/empty.png', width: 30, height: 30,),
                                    Flexible(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 5.0),
                                          child: Text(AppLocalizations.of(context)!.courier_main_page_info_2),
                                        )
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                  color: Colors.black
                              ),
                              ListTile(
                                title: Row(
                                  children: <Widget>[
                                    Image.asset('assets/images/parcels/red/empty.png', width: 30, height: 30,),
                                    Flexible(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 5.0),
                                          child: Text(AppLocalizations.of(context)!.courier_main_page_info_3),
                                        )
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                  color: Colors.black
                              ),
                              ListTile(
                                title: Row(
                                  children: <Widget>[
                                    Icon(Icons.star, color: Color.fromRGBO(218,165,32, 1.0)),
                                    Flexible(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 5.0),
                                          child: Text(AppLocalizations.of(context)!.express_parcel),
                                        )
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                  color: Colors.black
                              ),
                              ListTile(
                                title: Row(
                                  children: <Widget>[
                                    Icon(Icons.open_in_browser_outlined, color: Colors.deepOrange),
                                    Flexible(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 5.0),
                                          child: Text(AppLocalizations.of(context)!.courier_main_page_1),
                                        )
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                  color: Colors.black
                              ),
                              ListTile(
                                title: Row(
                                  children: <Widget>[
                                    Image.asset('assets/icons/courier.png', width: 25, height: 30,),
                                    Flexible(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 5.0),
                                          child: Text(AppLocalizations.of(context)!.courier_main_page_2),
                                        )
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          youtubeLink: "https://www.youtube.com/watch?v=Cb8gQVwByNM"
                        )
                  ),
                  body: GoogleMap(
                    scrollGesturesEnabled: scrollGesturesEnabled,
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: centerCourier,
                      zoom: 13.0,
                    ),
                    myLocationEnabled: true,
                    trafficEnabled: false,
                    zoomControlsEnabled: false,
                    markers: Set<Marker>.of(markersCouriersMainPage.values)
                  ),
                  floatingActionButton: Padding(
                      padding: EdgeInsets.all(1),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 30.0,
                          ),
                          Expanded(
                            child: FloatingActionButton(
                              heroTag: "btn1",
                              child: btnOneIcon,
                              onPressed: () {

                                if (!hideCartButton) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => CourierOrdersControlPanel(kGoogleApiKey: kGoogleApiKey)),
                                  );
                                } else if (workingMode) {
                                  doNotUpdateParcelsList = true;
                                  setState(() {
                                    scrollGesturesEnabled = !scrollGesturesEnabled;
                                    disableMarkerInfoWindowClick = true;
                                  });
                                  showDialog(
                                    context: context,
                                    useSafeArea: false,
                                    useRootNavigator: false,
                                    builder: (context) => AlertDialog(
                                      content: Container(
                                        height: MediaQuery.of(context).size.height * 0.7,
                                        child: WorkingModeParcelsWindowPage(update: _update, kGoogleApiKey: kGoogleApiKey),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18.0),
                                          side: BorderSide(color: Colors.black)
                                      ),
                                    ),
                                  ).then((value) {
                                    scrollGesturesEnabled = !scrollGesturesEnabled;
                                    disableMarkerInfoWindowClick = false;
                                    doNotUpdateParcelsList = false;
                                    setState(() {});
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: 5.0,
                          ),
                          Expanded(
                            child: Container(
                              width: 70.0,
                              height: 70.0,
                              child: FloatingActionButton(
                                heroTag: "btn2",
                                backgroundColor: selectJobMode == true && workingMode ==false ? Colors.green : Colors.deepOrange,
                                child: Icon(
                                  Icons.code,
                                  size: 35
                                ),
                                onPressed: () {
                                  if (selectJobMode == true && workingMode ==false) {
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(' '),
                                          content: Text(AppLocalizations.of(context)!.really_want_go_to_work_mode),
                                          actions: <Widget>[
                                            OutlinedButton(
                                              child: Text(AppLocalizations.of(context)!.yes),
                                              onPressed: () {
                                                selectJobMode = false;
                                                workingMode = true;
                                                hideCartButton = true;
                                                hideParcelListButton = false;
                                                setState(() {
                                                  selectJobMode = selectJobMode;
                                                  workingMode = workingMode;
                                                  hideCartButton = hideCartButton;
                                                  hideParcelListButton = hideParcelListButton;
                                                });
                                                Navigator.pop(context,false);
                                              }, //exit the app
                                            ),
                                            OutlinedButton(
                                              child: Text(AppLocalizations.of(context)!.no),
                                              onPressed: ()=> Navigator.pop(context,false),
                                            )
                                          ],
                                        )
                                    );
                                  } else if (selectJobMode == false && workingMode ==true) {
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(' '),
                                          content: Text(AppLocalizations.of(context)!.really_want_get_out_of_work_mode),
                                          actions: <Widget>[
                                            OutlinedButton(
                                              child: Text(AppLocalizations.of(context)!.yes),
                                              onPressed: () {
                                                selectJobMode = true;
                                                workingMode = false;
                                                hideCartButton = false;
                                                hideParcelListButton = true;
                                                setState(() {
                                                  selectJobMode = selectJobMode;
                                                  workingMode = workingMode;
                                                  hideCartButton = hideCartButton;
                                                  hideParcelListButton = hideParcelListButton;
                                                });
                                                Navigator.pop(context,false);
                                              }, //exit the app
                                            ),
                                            OutlinedButton(
                                              child: Text(AppLocalizations.of(context)!.no),
                                              onPressed: ()=> Navigator.pop(context,false),
                                            )
                                          ],
                                        )
                                    );
                                  }
                                },
                              ),
                            )
                          ),
                          SizedBox(
                            width: 5.0,
                          ),
                          selectJobMode ? Expanded(
                            child: FloatingActionButton(
                              heroTag: "btn5",
                              child: Icon(Icons.list_alt_rounded),
                              onPressed: () {
                                doNotUpdateParcelsList = true;
                                setState(() {
                                  scrollGesturesEnabled = !scrollGesturesEnabled;
                                  disableMarkerInfoWindowClick = true;
                                });
                                showDialog(
                                  context: context,
                                  useSafeArea: false,
                                  useRootNavigator: false,
                                  builder: (context) => AlertDialog(
                                    content: Container(
                                      height: MediaQuery.of(context).size.height * 0.7,
                                      child: JobsWindowPage(update: _update, kGoogleApiKey: kGoogleApiKey),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18.0),
                                        side: BorderSide(color: Colors.black)
                                    ),
                                  ),
                                ).then((value) {
                                  scrollGesturesEnabled = !scrollGesturesEnabled;
                                  disableMarkerInfoWindowClick = false;
                                  doNotUpdateParcelsList = false;
                                  setState(() {});
                                });
                              },
                            ),
                          ) : Visibility(
                            visible: false, child: Container(),
                          ),
                          SizedBox(
                            width: 5.0,
                          ),
                          selectJobMode ? Expanded(
                            child: FloatingActionButton(
                              heroTag: "btn6",
                              child: Icon(Icons.refresh),
                              onPressed: () {
                                setState(() {});
                              },
                            ),
                          ) : Visibility(
                            visible: false, child: Container(),
                          ),
                        ],
                      ),
                    )
                )
            );
          } else {
            return AnimationControllerClass();
          }
        }
    );

  }

}