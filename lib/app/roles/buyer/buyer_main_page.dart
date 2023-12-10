
import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/app/commons/mini_menu/mini_menu.dart';
import 'package:geo_couriers/app/commons/models/parcels_model.dart';
import 'package:geo_couriers/app/main_menu.dart';
import 'package:geo_couriers/app/commons/info/info.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../main.dart';
import 'fire_map.dart';

class BuyerMainPage extends StatefulWidget {

  final String? kGoogleApiKey;

  BuyerMainPage({required this.kGoogleApiKey});

  @override
  _BuyerMainPage createState() => _BuyerMainPage(kGoogleApiKey: kGoogleApiKey);
}

class _BuyerMainPage extends State<BuyerMainPage> {
  final String? kGoogleApiKey;

  _BuyerMainPage({this.kGoogleApiKey});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  FirebaseFirestore _fireStore = FirebaseFirestore.instance;

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
    if (mounted) {
      try {

        final res = await geoCourierClient.post(
          '/orders_buyer/buyer_parcels',
          queryParameters: {
            "pageKey": pageKey,
            "pageSize": _pageSize,
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
  }

  Future<bool> _onBackPressed(){
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MainMenu()),
    ).then((x) => x ?? false);
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
                          Flexible(
                              child: Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(AppLocalizations.of(context)!.buyer_info_1,
                                  style: TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
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
                          Icon(Icons.history_outlined, color: Colors.deepOrange),
                          Flexible(
                              child: Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(AppLocalizations.of(context)!.parcel_history),
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
          body: RefreshIndicator(
            onRefresh: () => Future.sync(() => _pagingController.refresh(),),
            child: PagedListView<int, Parcels>.separated(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<Parcels>(
                itemBuilder: (context, item, index) {

                  var _courierColor = Color(0xFFF44336);
                  if (item.arrivalInProgress! && item.orderStatus !=null && item.orderStatus == "ACTIVE") {
                    _courierColor = Color(0xFF000000);
                  }

                  return generateCard(
                      Padding(
                          padding: EdgeInsets.only(
                              left: 25.0, right: 25.0, top: 2.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              Expanded(
                                child: MaterialButton(
                                  child: Icon(CustomIcons.courier, color: _courierColor),
                                  onPressed: () async {

                                    if (!item.arrivalInProgress!) {
                                      return;
                                    }

                                    try {

                                      final res = await geoCourierClient.post(
                                        'orders_buyer/get_courier_user_id_by_job_id',
                                        queryParameters: {
                                          "jobId": item.jobId.toString(),
                                        },
                                      );

                                      if(res.statusCode ==200) {
                                        var body = res.data;

                                        var resume = false;
                                        await _fireStore.collection('locations')
                                            .where('user_id', isEqualTo: body).where('parcel_id', isEqualTo: item.orderId).get()
                                            .then((event) {

                                          if (event.docs.isNotEmpty) {
                                            resume = true;
                                          }
                                        });

                                        if(!resume) {
                                          return;
                                        }

                                        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
                                        var initialCameraPosition = CameraPosition(
                                            target: LatLng(position.latitude, position.longitude),
                                            zoom: 18
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => FireMap(userId: body, initialCameraPosition: initialCameraPosition, parcelId: item.orderId)),
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
                                  }, //exit the app
                                ),
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
          floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FloatingActionButton(
                  heroTag: "btn1",
                  child: Icon(CustomIcons.fb_messenger),
                  onPressed: () {
                    launchUrl(Uri.parse("http://" +dotenv.env['MESSENGER']!), mode: LaunchMode.externalApplication);
                  },
                ),
                FloatingActionButton(
                  child: Icon(Icons.history_outlined),
                  onPressed: () async {

                    int _doneParcelsCount = 0;
                    try {
                      final res = await geoCourierClient.post('orders_buyer/done_buyer_parcels');

                      if(res.statusCode ==200) {
                        _doneParcelsCount = res.data;
                      }

                    } catch (e) {
                      if (e is DioException && e.response?.statusCode == 403) {
                        reloadApp(context);
                      }
                      return;
                    }

                    showAlertDialog(context, _doneParcelsCount.toString(), AppLocalizations.of(context)!.past_orders);
                  },
                ),
              ],
            ),
          ),
        )
    );

  }

}