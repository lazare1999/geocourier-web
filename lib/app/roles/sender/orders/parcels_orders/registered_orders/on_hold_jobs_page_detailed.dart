import 'dart:async';

import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/commons/models/parcels_model.dart';
import 'package:geo_couriers/app/roles/sender/orders/parcels_orders/registered_orders/on_hold_jobs_page.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../../../main.dart';

class OnHoldJobsPageDetailed extends StatefulWidget {
  final int? orderJobId;
  final String? kGoogleApiKey;

  OnHoldJobsPageDetailed({this.orderJobId, required this.kGoogleApiKey});

  @override
  _OnHoldJobsPageDetailed createState() => _OnHoldJobsPageDetailed(orderJobId: orderJobId, kGoogleApiKey: kGoogleApiKey);
}

class _OnHoldJobsPageDetailed extends State<OnHoldJobsPageDetailed> {
  final int? orderJobId;
  final String? kGoogleApiKey;

  _OnHoldJobsPageDetailed({this.orderJobId, this.kGoogleApiKey});

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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.parcels),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh(),),
        child: PagedListView<int, Parcels>.separated(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<Parcels>(
            itemBuilder: (context, item, index) {

              return Column(
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
                    generateCard(
                        Padding(
                            padding: EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Expanded(
                                  child: MaterialButton(
                                    child: Icon(Icons.star, color: item.express! ? Colors.deepOrange : Colors.grey),
                                    onPressed: () async {
                                      if (item.express!) {
                                        showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(' '),
                                              content: Text(AppLocalizations.of(context)!.change_parcel_to_un_express),
                                              actions: <Widget>[
                                                OutlinedButton(
                                                  child: Text(AppLocalizations.of(context)!.yes),
                                                  onPressed: () async {

                                                    if (item.orderId ==null) {
                                                      return;
                                                    }

                                                    try {

                                                      final res = await geoCourierClient.post(
                                                        'orders_sender/remove_status_express',
                                                        queryParameters: {
                                                          "orderId": item.orderId.toString(),
                                                        },
                                                      );

                                                      if(res.statusCode ==200) {
                                                        Navigator.pop(context,false);
                                                        _pagingController.refresh();
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
                                      } else {

                                        var _continue = false;

                                        await showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(' '),
                                              content: Text(AppLocalizations.of(context)!.change_parcel_to_express),
                                              actions: <Widget>[
                                                OutlinedButton(
                                                  child: Text(AppLocalizations.of(context)!.yes),
                                                  onPressed: () {
                                                    _continue = true;
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

                                        if (_continue) {
                                          var _serviceDateFrom;
                                          var _serviceDateTo;
                                          var _serviceDate;

                                          _continue =false;

                                          await showModalBottomSheet<void>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return Container(
                                                height: 200,
                                                color: Colors.white,
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: <Widget>[
                                                      MaterialButton(
                                                        child: Text(
                                                          AppLocalizations.of(context)!.deliver_in_exact_time,
                                                          style: TextStyle(
                                                            fontFamily: 'Pacifico',
                                                            fontSize: 14.0,
                                                          ),
                                                        ),
                                                        onPressed: () async {
                                                          var value = await selectDate(context, " ");
                                                          _serviceDateFrom =null;
                                                          _serviceDateTo =null;
                                                          _serviceDate = value;
                                                          _continue = true;
                                                          Navigator.pop(context);
                                                        },
                                                      ),
                                                      MaterialButton(
                                                        child: Text(
                                                          AppLocalizations.of(context)!.deliver_time_period,
                                                          style: TextStyle(
                                                            fontFamily: 'Pacifico',
                                                            fontSize: 14.0,
                                                          ),
                                                        ),
                                                        onPressed: () async {
                                                          var value = await selectDate(context, AppLocalizations.of(context)!.from_the_specified_time);
                                                          _serviceDate = null;
                                                          _serviceDateTo = null;
                                                          _serviceDateFrom = value;
                                                          _continue = true;

                                                          showDialog(
                                                              context: context,
                                                              barrierDismissible: false,
                                                              builder: (context) => AlertDialog(
                                                                title: Text(' '),
                                                                content: Text(AppLocalizations.of(context)!.select_date_by_which_you_want_to_deliver),
                                                                actions: <Widget>[
                                                                  OutlinedButton(
                                                                    child: Text(AppLocalizations.of(context)!.resume),
                                                                    onPressed: () async {
                                                                      var serviceDateTo = await selectDate(context, AppLocalizations.of(context)!.before_the_specified_time);
                                                                      if (serviceDateTo !=null && value!.isBefore(serviceDateTo)) {
                                                                        _serviceDateTo = serviceDateTo;
                                                                        Navigator.pop(context);
                                                                        Navigator.pop(context);
                                                                      } else if (serviceDateTo !=null && value!.isAfter(serviceDateTo)) {
                                                                        showAlertDialog(context, AppLocalizations.of(context)!.an_error_occurred_incorrect_time_interval, "");
                                                                      }
                                                                    },
                                                                  ),
                                                                ],
                                                              )
                                                          );
                                                        },
                                                      ),
                                                      MaterialButton(
                                                        child: Text(
                                                          AppLocalizations.of(context)!.deliver_from_the_specified_time,
                                                          style: TextStyle(
                                                            fontFamily: 'Pacifico',
                                                            fontSize: 14.0,
                                                          ),
                                                        ),
                                                        onPressed: () async {
                                                          var serviceDateFrom = await selectDate(context, AppLocalizations.of(context)!.from_the_specified_time);
                                                          _serviceDate = null;
                                                          _serviceDateTo = null;
                                                          _serviceDateFrom = serviceDateFrom;
                                                          _continue = true;
                                                          Navigator.pop(context);
                                                        },
                                                      ),
                                                      MaterialButton(
                                                        child: Text(
                                                          AppLocalizations.of(context)!.deliver_before_the_specified_time,
                                                          style: TextStyle(
                                                            fontFamily: 'Pacifico',
                                                            fontSize: 14.0,
                                                          ),
                                                        ),
                                                        onPressed: () async {
                                                          var serviceDateTo = await selectDate(context, AppLocalizations.of(context)!.before_the_specified_time);
                                                          _serviceDate = null;
                                                          _serviceDateTo = serviceDateTo;
                                                          _serviceDateFrom = null;
                                                          _continue = true;
                                                          Navigator.pop(context);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );

                                          if (_continue) {
                                            try {

                                              final res = await geoCourierClient.post(
                                                'orders_sender/add_status_express',
                                                queryParameters: {
                                                  "orderId": item.orderId.toString(),
                                                  "serviceDateFrom": _serviceDateFrom ==null ? "" : _serviceDateFrom.toString(),
                                                  "serviceDateTo": _serviceDateTo ==null ? "" : _serviceDateTo.toString(),
                                                  "serviceDate": _serviceDate ==null ? "" : _serviceDate.toString(),
                                                },
                                              );

                                              if(res.statusCode ==200) {
                                                _pagingController.refresh();
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
                                        }
                                      }
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: MaterialButton(
                                    child: Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(' '),
                                            content: Text(AppLocalizations.of(context)!.do_you_really_want_to_delete_the_parcel),
                                            actions: <Widget>[
                                              OutlinedButton(
                                                child: Text(AppLocalizations.of(context)!.yes),
                                                onPressed: () async {

                                                  if (item.orderId ==null) {
                                                    return;
                                                  }

                                                  try {

                                                    final res = await geoCourierClient.post(
                                                      'orders_sender/remove_parcel',
                                                      queryParameters: {
                                                        "orderId": item.orderId.toString(),
                                                      },
                                                    );

                                                    if(res.statusCode ==200) {
                                                      Navigator.pop(context,false);
                                                      _pagingController.refresh();
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
                                ),
                                Expanded(
                                  child: MaterialButton(
                                    child: Icon(Icons.highlight_remove_rounded, color: Colors.red),
                                    onPressed: () async {
                                      showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(' '),
                                            content: Text(AppLocalizations.of(context)!.really_want_remove_parcel_from_order),
                                            actions: <Widget>[
                                              OutlinedButton(
                                                child: Text(AppLocalizations.of(context)!.yes),
                                                onPressed: () async {
                                                  try {

                                                    final res = await geoCourierClient.post(
                                                      'orders_sender/remove_order_from_job',
                                                      queryParameters: {
                                                        "orderId": item.orderId.toString(),
                                                      },
                                                    );

                                                    if(res.statusCode ==200) {
                                                      Navigator.pop(context,false);
                                                      _pagingController.refresh();
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
                                ),
                                Expanded(
                                  child: MaterialButton(
                                    child: Icon(Icons.send_rounded, color: Colors.green),
                                    onPressed: () {

                                      showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(' '),
                                            content: Text(AppLocalizations.of(context)!.really_want_transfer_parcel_another_order),
                                            actions: <Widget>[
                                              OutlinedButton(
                                                child: Text(AppLocalizations.of(context)!.yes),
                                                onPressed: ()  {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => OnHoldJobsPage(orderId: item.orderId, forReassigningJob: true, kGoogleApiKey: kGoogleApiKey)),
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
                                    },
                                  ),
                                ),
                              ],
                            )
                        ), 0.0
                    )
                  ]
                ],
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