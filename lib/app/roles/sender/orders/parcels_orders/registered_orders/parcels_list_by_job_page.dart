import 'dart:async';

import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/commons/info/info.dart';
import 'package:geo_couriers/app/commons/models/parcels_model.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../../../main.dart';

class ParcelsListByJobPage extends StatefulWidget {
  final int? orderJobId;
  final String? kGoogleApiKey;
  final bool? orderHasCourier;

  ParcelsListByJobPage({this.orderJobId, required this.kGoogleApiKey, required this.orderHasCourier});

  @override
  _ParcelsListByJobPage createState() => _ParcelsListByJobPage(orderJobId: orderJobId, kGoogleApiKey: kGoogleApiKey, orderHasCourier: orderHasCourier);
}

class _ParcelsListByJobPage extends State<ParcelsListByJobPage> {
  final int? orderJobId;
  final String? kGoogleApiKey;
  final bool? orderHasCourier;

  _ParcelsListByJobPage({this.orderJobId, this.kGoogleApiKey, this.orderHasCourier});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

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
        'orders_sender/orders_by_job',
        queryParameters: {
          "orderJobId": orderJobId.toString(),
          "pageKey": pageKey.toString(),
          "pageSize": _pageSize.toString(),
        }
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
      key: _scaffoldKey,
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () { Navigator.pop(context); },
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
                ListTile(
                  title: Row(
                    children: <Widget>[
                      Icon(CustomIcons.courier, color: Color(0xFF000000)),
                      Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(AppLocalizations.of(context)!.parcels_list_by_job_page_info_1),
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
                      Icon(CustomIcons.courier, color: Color(0xFFF44336)),
                      Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(AppLocalizations.of(context)!.parcels_list_by_job_page_info_2),
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
                      Icon(Icons.star, color: Colors.deepOrange),
                      Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(AppLocalizations.of(context)!.express_parcel),
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

              var _starIcon;
              if (item.express!) {
                _starIcon = Icons.star;
              }

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
                          orderHasCourier! ? Expanded(
                            child: Icon(CustomIcons.courier, color: _courierColor),
                          ) : Container(),
                          Expanded(
                            child: MaterialButton(
                              child: Icon(_starIcon, color: Colors.deepOrange),
                              onPressed: () {
                                if (item.express!) {
                                  showAlertDialog(context, AppLocalizations.of(context)!.express, "");
                                }
                              },
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
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}