import 'dart:async';
import 'dart:collection';

import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/commons/models/parcels_model.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../main.dart';

class ParcelsWindowPage extends StatefulWidget {
  final int? orderJobId;
  final ValueChanged<LatLng>? update;
  final String? kGoogleApiKey;

  ParcelsWindowPage({this.update, this.orderJobId, required this.kGoogleApiKey});

  @override
  _ParcelsWindowPage createState() => _ParcelsWindowPage(update: update, orderJobId: orderJobId, kGoogleApiKey: kGoogleApiKey);
}

class _ParcelsWindowPage extends State<ParcelsWindowPage> {
  final int? orderJobId;
  final ValueChanged<LatLng>? update;
  final String? kGoogleApiKey;

  _ParcelsWindowPage({this.update, this.orderJobId, required this.kGoogleApiKey});

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

    if (pageKey >0) {
      pageKey = pageKey - _pageSize +1;
    }

    try {

      final res = await geoCourierClient.post(
        'orders_courier/get_parcels_by_job',
        queryParameters: {
          "pageKey": pageKey.toString(),
          "pageSize": _pageSize.toString(),
          "orderJobId": orderJobId.toString(),
        },
      );

      if(res.statusCode ==200) {
        List<Parcels> newItems = List<Parcels>.from(res.data.map((i) => Parcels.fromJson(i)));

        final isLastPage = newItems.length < _pageSize;
        if (isLastPage) {
          _pagingController.appendLastPage(newItems);
        } else {
          final nextPageKey = pageKey + newItems.length;
          _pagingController.appendPage(newItems, nextPageKey);
        }

      }

    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        reloadApp(context);
      } else {
        _pagingController.error = e;
      }
      return;
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
                          left: 10.0, right: 10.0, top: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          item.express ==true ? Expanded(
                              flex: 1,
                              child: Icon(Icons.star, color: Color.fromRGBO(218,165,32, 1.0),)
                          ) : Visibility(
                            visible: false, child: Container(),
                          ),
                          Expanded(
                            flex: 3,
                            child: ArgonTimerButton(
                              height: 50,
                              width: MediaQuery.of(context).size.width * 0.45,
                              minWidth: MediaQuery.of(context).size.width * 0.30,
                              highlightColor: Colors.transparent,
                              highlightElevation: 0,
                              roundLoadingShape: false,
                              onTap: (startTimer, btnState) async {
                                if (btnState == ButtonState.Idle) {
                                  startTimer(15);
                                  showParcelInfoDialog(item, context, kGoogleApiKey!);
                                  update!(LatLng(double.parse(item.parcelPickupAddressLatitude!), double.parse(item.parcelPickupAddressLongitude!)));
                                }
                              },
                              child: Text(
                                item.serviceParcelIdentifiable!,
                              ),
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(left: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FloatingActionButton(
              heroTag: "btn1",
              backgroundColor: Colors.white,
              child: Icon(Icons.route, color: Colors.blue),
              onPressed: () async {

                if (_pagingController.itemList ==null || _pagingController.itemList!.isEmpty)
                  return;

                Position position = await Geolocator.getCurrentPosition();
                HashMap<int?, String> _parcelsAndDistances = new HashMap<int?, String>();

                for (final _p in _pagingController.itemList!) {
                  var pm = await getDistanceMatrix(position.latitude, position.longitude, _p.parcelPickupAddressLatitude, _p.parcelPickupAddressLongitude, dotenv.env['GOOGLE_API_KEY'], context);
                  _parcelsAndDistances[pm!.elements[0].distance.value] = _p.parcelPickupAddressLatitude.toString() + "," + _p.parcelPickupAddressLongitude.toString();
                }


                var sortedKeys = _parcelsAndDistances.keys.toList()..sort();

                String waypoints = "";

                for (final k in sortedKeys) {

                  if (sortedKeys.first ==k)
                    continue;


                  if (_parcelsAndDistances[k] ==null)
                    continue;

                  waypoints += _parcelsAndDistances[k].toString();

                  if (sortedKeys.last ==k)
                    continue;

                  waypoints += "|";
                }


                openGoogleMapMultipleLocations(_parcelsAndDistances[sortedKeys.first].toString(), waypoints, position);
              },
            ),
            FloatingActionButton(
              heroTag: "btn2",
              backgroundColor: Colors.white,
              child: Icon(Icons.check, color: Colors.green),
              onPressed: () async {

                bool _containsExpress = false;
                _pagingController.value.itemList!.forEach((element) {
                  if(element.express ==true) {
                    _containsExpress = true;
                  }
                });

                var alert = RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: AppLocalizations.of(context)!.really_want_take_order,
                    style: Theme.of(context).textTheme.bodyLarge,
                    children: [
                      TextSpan(
                        text: _containsExpress ? AppLocalizations.of(context)!.parcels_window_page_info_1 : "",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red
                        ),
                      )
                    ],
                  ),
                );

                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(' '),
                      content: alert,
                      actions: <Widget>[
                        OutlinedButton(
                          child: Text(AppLocalizations.of(context)!.yes),
                          onPressed: () async {

                            try {

                              final res = await geoCourierClient.post(
                                'orders_courier/approve_job',
                                queryParameters: {
                                  "orderJobId": orderJobId.toString(),
                                },
                              );

                              if(res.statusCode ==200) {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();

                                switch (res.data) {
                                  case "VIP_STATUS_EXPIRED" : showAlertDialog.call(context, AppLocalizations.of(context)!.vip_status_expired, ""); break;
                                  case "MUST_PAY_DEBT" : showAlertDialog.call(context, AppLocalizations.of(context)!.must_pay_debt, ""); break;
                                  case "ALREADY_TAKEN" : showAlertDialog.call(context, AppLocalizations.of(context)!.already_taken, ""); break;
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

                          }, //exit the app
                        ),
                        OutlinedButton(
                          child: Text(AppLocalizations.of(context)!.no),
                          onPressed: ()=> Navigator.pop(context,false),
                        )
                      ],
                    )
                );


              },
            ),
          ],
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