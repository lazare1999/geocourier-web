import 'dart:async';

import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/commons/models/parcels_model.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../main.dart';

class NearParcelsWindowPage extends StatefulWidget {

  final List<Parcels>? parcelsToDisplay;
  final num? searchRadiusDistance;
  final String? kGoogleApiKey;

  NearParcelsWindowPage({this.parcelsToDisplay, this.searchRadiusDistance, required this.kGoogleApiKey});

  @override
  _NearParcelsWindowPage createState() => _NearParcelsWindowPage(newItems: parcelsToDisplay, searchRadiusDistance: searchRadiusDistance, kGoogleApiKey: kGoogleApiKey);
}

class _NearParcelsWindowPage extends State<NearParcelsWindowPage> {

  final List<Parcels>? newItems;
  final num? searchRadiusDistance;
  final String? kGoogleApiKey;

  _NearParcelsWindowPage({this.newItems, this.searchRadiusDistance, required this.kGoogleApiKey});

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


    final isLastPage = newItems!.length < _pageSize;
    if (isLastPage) {
      _pagingController.appendLastPage(newItems!);
    } else {
      final nextPageKey = pageKey + newItems!.length;
      _pagingController.appendPage(newItems!, nextPageKey);
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(child: Text(AppLocalizations.of(context)!.parcels +" " + searchRadiusDistance.toString() + " " + AppLocalizations.of(context)!.meters)),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh(),),
        child: PagedListView<int, Parcels>.separated(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<Parcels>(
            itemBuilder: (context, item, index) {
              return generateCard(
                  Padding(
                      padding: EdgeInsets.only(
                          left: 25.0, right: 25.0, top: 2.0),
                      child: Column(
                        children: [
                          ...[
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Expanded(
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
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Expanded(
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
                                        launchUrl(Uri.parse('tel:' + item.viewerPhone.toString()));
                                      }
                                    },
                                    child: Icon(Icons.phone, color: Colors.deepOrange,),
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
                                Expanded(
                                  flex: 2,
                                  child: ArgonTimerButton(
                                    height: 50,
                                    width: MediaQuery.of(context).size.width * 0.2,
                                    minWidth: MediaQuery.of(context).size.width * 0.1,
                                    highlightColor: Colors.transparent,
                                    highlightElevation: 0,
                                    roundLoadingShape: false,
                                    onTap: (startTimer, btnState) async {
                                      if (btnState == ButtonState.Idle) {
                                        startTimer(1);
                                        try {

                                          final res = await geoCourierClient.post(
                                            'orders_courier/jobs_done',
                                            queryParameters: {
                                              "orderId": item.orderId.toString(),
                                            },
                                          );

                                          if(res.statusCode ==200) {
                                            newItems!.remove(item);
                                            _pagingController.refresh();

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
                                          return false;
                                        }
                                      }
                                    },
                                    child: Text(AppLocalizations.of(context)!.jobs_done,
                                      style: TextStyle(
                                        color: Colors.green,
                                      ),
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
                          ]
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