import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/roles/sender/models/Jobs_model.dart';
import 'package:geo_couriers/app/roles/sender/orders/parcels_orders/registered_orders/parcels_list_by_job_page.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../main.dart';

class HandedOverJobsToCourierPage extends StatefulWidget {

  final String? kGoogleApiKey;

  HandedOverJobsToCourierPage({required this.kGoogleApiKey});

  @override
  _HandedOverJobsToCourierPage createState() => _HandedOverJobsToCourierPage(kGoogleApiKey: kGoogleApiKey);
}

class _HandedOverJobsToCourierPage extends State<HandedOverJobsToCourierPage> {

  final String? kGoogleApiKey;

  _HandedOverJobsToCourierPage({required this.kGoogleApiKey});

  static const _pageSize = 10;

  final PagingController<int, JobsModel> _pagingController = PagingController(firstPageKey: 0);

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
        'orders_courier/get_handed_over_jobs_courier',
        queryParameters: {
          "pageKey": pageKey.toString(),
          "pageSize": _pageSize.toString(),
        },
      );

      if(res.statusCode ==200) {
        List<JobsModel> newItems = List<JobsModel>.from(res.data.map((i) => JobsModel.fromJson(i)));

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
        // title: Text(AppLocalizations.of(context)!.handed_over_jobs),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh(),),
        child: PagedListView<int, JobsModel>.separated(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<JobsModel>(
            itemBuilder: (context, item, index) {
              var _jobName = "N" + item.orderJobId.toString();
              if (item.jobName !="" && item.jobName !=null) {
                _jobName += " - " + item.jobName!;
              }
              return generateCard(
                  Padding(
                      padding: EdgeInsets.only(
                          left: 25.0, right: 25.0, top: 2.0),
                      child: Row(
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
                                  try {

                                    final res = await geoCourierClient.post(
                                      'miniMenu/get_user_by_user_id',
                                      queryParameters: {
                                        "otherUserId": item.senderUserId.toString(),
                                      },
                                    );

                                    if(res.statusCode ==200) {
                                      var body = res.data;
                                      if (body == null) {
                                        return false;
                                      }

                                      String? _ans = "";

                                      var _nickname = body["nickname"] ==null ? "" : body["nickname"];
                                      if (_nickname =="") {

                                        var _firstName = body["firstName"] ==null ? "" : body["firstName"];
                                        var _lastName = body["lastName"] ==null ? "" : body["lastName"];
                                        var _mainNickname = body["mainNickname"] ==null ? "" : body["mainNickname"];

                                        _ans = _firstName + " " + _lastName + " " + _mainNickname;
                                      } else {
                                        _ans = _nickname;
                                      }

                                      showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                              content: Container(
                                                child: Form(
                                                  child: Scrollbar(
                                                    child: SingleChildScrollView(
                                                      padding: EdgeInsets.all(16),
                                                      child: Column(
                                                        children: <Widget>[
                                                          Column(
                                                            children: <Widget>[
                                                              Center(child: Text(
                                                                AppLocalizations.of(context)!.order_has_been_sent_from,
                                                                style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.blueGrey
                                                                ),
                                                              )),
                                                              SizedBox(
                                                                height: 10.0,
                                                              ),
                                                              Center(child: Text(_ans!)),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                          )
                                      );
                                    }

                                  } catch (e) {
                                    if (e is DioException && e.response?.statusCode == 403) {
                                      reloadApp(context);
                                    } else {
                                      _pagingController.error = e;
                                    }
                                    return false;
                                  }
                                }
                              },
                              child: Icon(Icons.info, color: Colors.blueGrey),
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
                              child: ListTile(
                                  title: Text(item.orderCount.toString()),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ParcelsListByJobPage(orderJobId: item.orderJobId, kGoogleApiKey: kGoogleApiKey, orderHasCourier: item.courierUserId !=null)),
                                    );
                                  }
                              )
                          ),
                          Expanded(
                              flex: 3,
                              child: ListTile(
                                title: Text(_jobName),
                              )
                          ),
                          Expanded(
                              child: MaterialButton(
                                child: Icon(Icons.check, color: Colors.green),
                                onPressed: () async {
                                  showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(' '),
                                        content: Text(AppLocalizations.of(context)!.really_want_take_order),
                                        actions: <Widget>[
                                          OutlinedButton(
                                            child: Text(AppLocalizations.of(context)!.yes),
                                            onPressed: () async {
                                              try {

                                                final res = await geoCourierClient.post(
                                                  'orders_courier/courier_accept_handed_over_job',
                                                  queryParameters: {
                                                    "orderJobId": item.orderJobId.toString(),
                                                  },
                                                );

                                                if(res.statusCode ==200) {
                                                  _pagingController.refresh();
                                                  Navigator.pop(context,false);

                                                  switch (res.data) {
                                                    case "VIP_STATUS_EXPIRED" : showAlertDialog.call(context, AppLocalizations.of(context)!.vip_status_expired, ""); break;
                                                    case "MUST_PAY_DEBT" : showAlertDialog.call(context, AppLocalizations.of(context)!.must_pay_debt, ""); break;
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
                              )
                          ),
                          Expanded(
                              child: MaterialButton(
                                child: Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () async {
                                  showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(' '),
                                        content: Text(AppLocalizations.of(context)!.really_want_not_take_order),
                                        actions: <Widget>[
                                          OutlinedButton(
                                            child: Text(AppLocalizations.of(context)!.yes),
                                            onPressed: () async {
                                              try {

                                                final res = await geoCourierClient.post(
                                                  'orders_courier/courier_not_accept_handed_over_job',
                                                  queryParameters: {
                                                    "orderJobId": item.orderJobId.toString(),
                                                  },
                                                );

                                                if(res.statusCode ==200) {
                                                  _pagingController.refresh();
                                                  Navigator.pop(context,false);

                                                  switch (res.data) {
                                                    case "VIP_STATUS_EXPIRED" : showAlertDialog.call(context, AppLocalizations.of(context)!.vip_status_expired, ""); break;
                                                    case "MUST_PAY_DEBT" : showAlertDialog.call(context, AppLocalizations.of(context)!.must_pay_debt, ""); break;
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
                              )
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