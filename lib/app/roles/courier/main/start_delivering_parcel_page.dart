
// import 'package:background_location/background_location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/commons/info/info.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/app/commons/models/parcels_model.dart';
import 'package:geo_couriers/app/roles/courier/windows/near_parcels_window_page.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';


class StartDeliveringParcelPage extends StatefulWidget {

  final List<Parcels>? parcels;
  final Parcels? parcel;
  final String? kGoogleApiKey;
  final int? courierUserId;

  StartDeliveringParcelPage({required this.parcels, required this.parcel, required this.kGoogleApiKey, required this.courierUserId});

  @override
  _StartDeliveringParcelPage createState() => _StartDeliveringParcelPage(parcels: parcels, parcel: parcel, kGoogleApiKey: kGoogleApiKey, courierUserId: courierUserId);
}

class _StartDeliveringParcelPage extends State<StartDeliveringParcelPage> {

  final List<Parcels>? parcels;
  final Parcels? parcel;
  final String? kGoogleApiKey;
  final int? courierUserId;

  _StartDeliveringParcelPage({required this.parcels, required this.parcel, required this.kGoogleApiKey, required this.courierUserId});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  num _searchRadiusDistance = 300;

  FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  // Geoflutterfire _geo = Geoflutterfire();

  _startBackgroundLocation() async {

    // await BackgroundLocation.startLocationService(distanceFilter: 20);
    // BackgroundLocation.getLocationUpdates((location) {
    //   _fireStore.collection('locations')
    //       .where('user_id', isEqualTo: courierUserId).where('parcel_id', isEqualTo: parcel!.orderId).get()
    //       .then((val) {
    //
    //     GeoFirePoint point = _geo.point(latitude: location.latitude!, longitude: location.longitude!);
    //     var data = {
    //       'position': point.data,
    //       'user_id': courierUserId,
    //       'parcel_id': parcel!.orderId
    //     };
    //
    //     if (val.docs.isNotEmpty) {
    //       val.docs.first.reference.update(data);
    //     } else if (val.docs.length ==0) {
    //       _fireStore.collection('locations').add(data);
    //     }
    //   });
    // });
  }

  _stopBackgroundLocation() async {

    // BackgroundLocation.stopLocationService();

    await _fireStore.collection('locations')
        .where('user_id', isEqualTo: courierUserId).where('parcel_id', isEqualTo: parcel!.orderId).get()
        .then((val) {

          if (val.docs.isNotEmpty) {
            val.docs.forEach((element) {
              _fireStore.collection('locations').doc(element.reference.id).delete();
            });
          }
    });
  }

  Future<bool> _onBackPressed() async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.really_want_to_exit_question),
        content: Text(AppLocalizations.of(context)!.start_del_warning),
        actions: <Widget>[
          OutlinedButton(
            child: Text(AppLocalizations.of(context)!.yes),
            onPressed: () {
              _stopBackgroundLocation();
              Navigator.pop(context,false);
              Navigator.pop(context,false);
            }, //exit the app
          ),
          OutlinedButton(
            child: Text(AppLocalizations.of(context)!.no),
            onPressed: ()=> Navigator.pop(context,false),
          )
        ],
      ),
    )) ?? false;
  }

  @override
  void initState() {
    super.initState();
    _startBackgroundLocation();
  }

  @override
  Widget build(BuildContext context) {

    return PopScope(
        canPop: true,
        onPopInvoked: (bool didPop) {
          _onBackPressed();
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () { _onBackPressed(); },
                );
              },
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                ),
                onPressed: () {
                  _scaffoldKey.currentState!.openEndDrawer();
                },
              )
            ],
          ),
          endDrawer: Drawer(
              child: Info(
                safeAreaChild: ListView(
                  children: <Widget>[

                  ],
                ),
                youtubeLink: "https://www.youtube.com/watch?v=Cb8gQVwByNM"
              )
          ),
          body: Center(
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                    children: [
                      ...[
                        generateCard(Center(
                          child: MaterialButton(
                            child: Text(AppLocalizations.of(context)!.jobs_done,
                              style: TextStyle(
                                color: Colors.green,
                              ),
                            ),
                            onPressed: () async {
                              if (kIsWeb) {
                                return;
                              }
                              if(await checkIfCurrentPositionInDistanceFromGivenLocation(parcel!.parcelAddressToBeDeliveredLatitude, parcel!.parcelAddressToBeDeliveredLongitude, _searchRadiusDistance)) {
                                try {

                                  final res = await geoCourierClient.post(
                                    'orders_courier/jobs_done',
                                    queryParameters: {
                                      "orderId": parcel!.orderId.toString(),
                                    },
                                  );

                                  if(res.statusCode ==200) {
                                    _stopBackgroundLocation();
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(' '),
                                          content: Text(_searchRadiusDistance.toString() + " " + AppLocalizations.of(context)!.near_parcels_info_text),
                                          actions: <Widget>[
                                            OutlinedButton(
                                              child: Text(AppLocalizations.of(context)!.yes),
                                              onPressed: () {
                                                var _nearParcels = getNearParcelsThatCanBeDelivered(parcels!, parcel!.parcelAddressToBeDeliveredLatitude, parcel!.parcelAddressToBeDeliveredLongitude, _searchRadiusDistance, parcel!.orderId);
                                                if (_nearParcels.isNotEmpty) {
                                                  List<Parcels> _parcelsToDisplay = List<Parcels>.empty(growable: true);
                                                  parcels!.forEach((element) {
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
                                                        child: NearParcelsWindowPage(parcelsToDisplay: _parcelsToDisplay, searchRadiusDistance: _searchRadiusDistance, kGoogleApiKey: kGoogleApiKey),
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
                        ), 10.0),
                        generateCard(Center(
                          child: MaterialButton(
                            child: Text(AppLocalizations.of(context)!.write_down_parcel,
                              style: TextStyle(
                                color: Colors.red,
                              ),
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
                                        onPressed: () async {

                                          _stopBackgroundLocation();
                                          Navigator.pop(context,false);
                                          Navigator.pop(context,false);
                                          showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                  actions: <Widget>[
                                                    OutlinedButton(
                                                      child: Text(AppLocalizations.of(context)!.draw_path,
                                                        style: TextStyle(
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        var latitude = double.parse(parcel!.parcelAddressToBeDeliveredLatitude!);
                                                        var longitude = double.parse(parcel!.parcelAddressToBeDeliveredLongitude!);
                                                        openMap(latitude, longitude, parcel!.serviceParcelIdentifiable!, context);
                                                      }, //exit the app
                                                    ),
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
                                                                  "senderUserId": parcel!.senderUserId.toString(),
                                                                }
                                                            );

                                                            launchUrl(Uri.parse('tel:' + res.data));
                                                          } catch (e) {

                                                          }
                                                        }, //exit the app
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
                                                                "orderId": parcel!.orderId.toString(),
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
                        ), 10.0),
                        generateCard(Center(
                          child: MaterialButton(
                            child: Text(AppLocalizations.of(context)!.draw_path,
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                            onPressed: ()  {
                              var latitude = double.parse(parcel!.parcelAddressToBeDeliveredLatitude!);
                              var longitude = double.parse(parcel!.parcelAddressToBeDeliveredLongitude!);
                              openMap(latitude, longitude, parcel!.serviceParcelIdentifiable!, context);
                            }, //exit the app
                          ),
                        ), 10.0),
                      ]
                    ]
                )
              ),
            ),
          ),
        )
    );
  }

}