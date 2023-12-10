import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/app/commons/models/parcels_model.dart';
import 'package:geo_couriers/app/roles/courier/main/start_delivering_parcel_page.dart';
import 'package:geo_couriers/app/roles/courier/windows/parcels_window_page.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import '../../../../main.dart';
import 'near_parcels_window_page.dart';

class StackedParcelsWindowPage extends StatefulWidget {

  final List<Parcels> stackedParcels;
  final List<Parcels> parcels;
  final Position position;
  final String? kGoogleApiKey;
  final num? searchRadiusDistance;
  final bool? workingMode;
  final bool? selectJobMode;
  final GoogleMapController? controllerCouriersMainPage;

  StackedParcelsWindowPage({required this.stackedParcels,
    required this.parcels, required this.position,
    required this.kGoogleApiKey, required this.searchRadiusDistance,
    required this.workingMode, required this.selectJobMode,
    required this.controllerCouriersMainPage
  });

  @override
  _StackedParcelsWindowPage createState() => _StackedParcelsWindowPage(stackedParcels: stackedParcels,
      parcels: parcels, position: position, kGoogleApiKey: kGoogleApiKey,
      searchRadiusDistance: searchRadiusDistance, workingMode: workingMode,
      selectJobMode: selectJobMode, controllerCouriersMainPage: controllerCouriersMainPage);
}

class _StackedParcelsWindowPage extends State<StackedParcelsWindowPage> {

  final List<Parcels> stackedParcels;
  final List<Parcels> parcels;
  final Position position;
  final String? kGoogleApiKey;
  final num? searchRadiusDistance;
  final bool? workingMode;
  final bool? selectJobMode;
  final GoogleMapController? controllerCouriersMainPage;

  _StackedParcelsWindowPage({required this.stackedParcels,
    required this.parcels, required this.position,
    required this.kGoogleApiKey, required this.searchRadiusDistance,
    required this.workingMode, required this.selectJobMode,
    required this.controllerCouriersMainPage
  });

  Future<void> _update(LatLng latLng) async {
    controllerCouriersMainPage!.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: latLng,
      zoom: 13.0,
    )));
  }

  static const _pageSize = 10;

  final PagingController<int, Parcels> _pagingController = PagingController(firstPageKey: 0);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {


    var newItems = stackedParcels;

    final isLastPage = newItems.length < _pageSize;

    if (isLastPage) {
      _pagingController.appendLastPage(newItems);
    } else {
      final nextPageKey = pageKey + newItems.length;
      _pagingController.appendPage(newItems, nextPageKey.toInt());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh(),),
        child: PagedListView<int, Parcels>.separated(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<Parcels>(
            itemBuilder: (context, item, index) {
              return generateCard(
                  Padding(
                      padding: EdgeInsets.only(
                          left: 5.0, right: 5.0, top: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Expanded(
                            child: Icon(Icons.directions_run_rounded, color: item.arrivalInProgress! ? Colors.black : Colors.red),
                          ),
                          Expanded(
                            flex: 4,
                            child: ArgonTimerButton(
                              height: 50,
                              width: MediaQuery.of(context).size.width * 0.2,
                              minWidth: MediaQuery.of(context).size.width * 0.1,
                              highlightColor: Colors.transparent,
                              highlightElevation: 0,
                              roundLoadingShape: false,
                              onTap: (startTimer, btnState) async {
                                if (btnState == ButtonState.Idle) {
                                  startTimer(5);

                                  if (selectJobMode!) {
                                    await showDialog(
                                      context: context,
                                      useSafeArea: false,
                                      useRootNavigator: false,
                                      builder: (context) => AlertDialog(
                                        content: Container(
                                          height: MediaQuery.of(context).size.height * 0.7,
                                          child: ParcelsWindowPage(update: _update, orderJobId: item.jobId, kGoogleApiKey: kGoogleApiKey),
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18.0),
                                            side: BorderSide(color: Colors.black)
                                        ),
                                      ),
                                    );

                                    Navigator.pop(context, false);
                                  }
                                  else if (workingMode!) {
                                    if (item.arrivalInProgress! && item.orderStatus !=null && item.orderStatus == "ACTIVE") {

                                      var _distanceBetweenCourierAndDeliver = await getDistanceMatrix(position.latitude,
                                          position.longitude, item.parcelAddressToBeDeliveredLatitude,
                                          item.parcelAddressToBeDeliveredLongitude, kGoogleApiKey, context);

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
                                                    color: Colors.black
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
                                                text: _distanceBetweenCourierAndDeliver.destinations.toString() + "\n",
                                                style: TextStyle(
                                                    color: Colors.black
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
                                                    color: Colors.black
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
                                                    color: Colors.black
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
                                                      text: AppLocalizations.of(context)!.hand_overed_parcel+ "\n",
                                                      style: TextStyle(
                                                          color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 20.0
                                                      ),
                                                      children: <TextSpan>[
                                                        TextSpan(
                                                          text: item.serviceParcelIdentifiable,
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
                                                      if(await checkIfCurrentPositionInDistanceFromGivenLocation(item.parcelAddressToBeDeliveredLatitude, item.parcelAddressToBeDeliveredLongitude, searchRadiusDistance!)) {
                                                        try {

                                                          final res = await geoCourierClient.post(
                                                            'orders_courier/jobs_done',
                                                            queryParameters: {
                                                              "orderId": item.orderId.toString(),
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
                                                                        var _nearParcels = getNearParcelsThatCanBeDelivered(parcels, item.parcelAddressToBeDeliveredLatitude, item.parcelAddressToBeDeliveredLongitude, searchRadiusDistance!, item.orderId);
                                                                        if (_nearParcels.isNotEmpty) {
                                                                          List<Parcels> _parcelsToDisplay = List<Parcels>.empty(growable: true);
                                                                          parcels.forEach((element) {
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
                                                                                        "senderUserId": item.senderUserId.toString(),
                                                                                      }
                                                                                  );

                                                                                  launchUrl(Uri.parse('tel:' + res.data));
                                                                                } catch (e) {

                                                                                }
                                                                              },  //exit the app
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
                                                                                        "orderId": item.orderId.toString(),
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
                                                              "jobId": item.jobId.toString(),
                                                            },
                                                          );

                                                          if(res.statusCode ==200) {
                                                            var body = res.data;
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(builder: (context) => StartDeliveringParcelPage(parcels: parcels, parcel: item, kGoogleApiKey: kGoogleApiKey, courierUserId: body)),
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

                                                      var latitude = double.parse(item.parcelAddressToBeDeliveredLatitude!);
                                                      var longitude = double.parse(item.parcelAddressToBeDeliveredLongitude!);
                                                      openMap(latitude, longitude, item.serviceParcelIdentifiable!, context);

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
                                                              "senderUserId": item.senderUserId.toString(),
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
                                                      launchUrl(Uri.parse('tel:' + item.viewerPhone.toString()));
                                                    }, //exit the app
                                                  ),
                                                ),
                                              ],
                                              actionsPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0)
                                          )
                                      );
                                    }
                                    else {
                                      var _distanceBetweenTakeAndDest = await getDistanceMatrix(position.latitude,
                                          position.longitude, item.parcelPickupAddressLatitude,
                                          item.parcelPickupAddressLongitude, kGoogleApiKey, context);

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
                                                        text: item.serviceParcelIdentifiable,
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

                                                    if(await checkIfCurrentPositionInDistanceFromGivenLocation(item.parcelPickupAddressLatitude, item.parcelPickupAddressLongitude, searchRadiusDistance!)) {
                                                      try {

                                                        final res = await geoCourierClient.post(
                                                          'orders_courier/take_parcel',
                                                          queryParameters: {
                                                            "orderId": item.orderId.toString(),
                                                          },
                                                        );

                                                        if(res.statusCode ==200) {
                                                          Navigator.pop(context,false);

                                                          if(item.express!) {
                                                            var alertText = AppLocalizations.of(context)!.note_express_limit + "\n\n";
                                                            if (item.serviceDate !=null) {
                                                              alertText += AppLocalizations.of(context)!.must_deliver_exactly + item.serviceDate.toString();
                                                            }
                                                            if (item.serviceDateFrom !=null) {
                                                              alertText += AppLocalizations.of(context)!.must_deliver_from + item.serviceDateFrom.toString();
                                                            }
                                                            if (item.serviceDateTo !=null) {
                                                              alertText += AppLocalizations.of(context)!.must_deliver_to + item.serviceDateTo.toString();
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
                                                    var latitude = double.parse(item.parcelPickupAddressLatitude!);
                                                    var longitude = double.parse(item.parcelPickupAddressLongitude!);
                                                    openMap(latitude, longitude, item.serviceParcelIdentifiable!, context);
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
                                                            "senderUserId": item.senderUserId.toString(),
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
                                                    launchUrl(Uri.parse('tel:' + item.viewerPhone.toString()));
                                                  }, //exit the app
                                                ),
                                              ),
                                            ],
                                          )
                                      );
                                    }
                                  }



                                }
                              },
                              child: Text(item.serviceParcelIdentifiable!),
                              loader: (timeLeft) {
                                return Text(
                                  AppLocalizations.of(context)!.please_wait + " | $timeLeft",
                                  style: TextStyle(
                                      color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                                      fontSize: 15
                                  ),
                                );
                              },
                              borderRadius: 18.0,
                              color: Colors.transparent,
                              elevation: 0,
                            ),
                          ),
                        ],
                      )
                  ), 10.0
              );
            },
          ),
          separatorBuilder: (context, index) => const Divider(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

}