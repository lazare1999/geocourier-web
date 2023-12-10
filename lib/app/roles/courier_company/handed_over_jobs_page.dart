import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/commons/info/info.dart';
import 'package:geo_couriers/app/roles/sender/models/Jobs_model.dart';
import 'package:geo_couriers/app/roles/sender/orders/parcels_orders/registered_orders/parcels_list_by_job_page.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HandedOverJobsPage extends StatefulWidget {

  final String? kGoogleApiKey;

  HandedOverJobsPage({required this.kGoogleApiKey});

  @override
  _HandedOverJobsPage createState() => _HandedOverJobsPage(kGoogleApiKey: kGoogleApiKey);
}

class _HandedOverJobsPage extends State<HandedOverJobsPage> {

  final String? kGoogleApiKey;

  _HandedOverJobsPage({required this.kGoogleApiKey});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

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
        'orders_sender/get_handed_over_jobs',
        queryParameters: {
          "pageKey": pageKey.toString(),
          "pageSize": _pageSize.toString(),
        }
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
                        Flexible(
                          child: Text(AppLocalizations.of(context)!.handed_over_jobs_page_info_1)
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
                        Icon(Icons.check, color: Colors.green),
                        Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(left: 8.0),
                                child: Text(AppLocalizations.of(context)!.handed_over_jobs_page_info_2)
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
                        Icon(Icons.cancel_outlined, color: Colors.red),
                        Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(AppLocalizations.of(context)!.handed_over_jobs_page_info_3),
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
                            flex: 2,
                            child: ListTile(
                                title: Text(_jobName),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ParcelsListByJobPage(orderJobId: item.orderJobId, kGoogleApiKey: kGoogleApiKey, orderHasCourier: item.courierUserId !=null)),
                                  );
                                }
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
                                                  'orders_sender/accept_handed_over_job',
                                                  queryParameters: {
                                                    "orderJobId": item.orderJobId.toString(),
                                                  }
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
                                child: Icon(Icons.cancel_outlined, color: Colors.red),
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
                                                  'orders_sender/not_accept_handed_over_job',
                                                  queryParameters: {
                                                    "orderJobId": item.orderJobId.toString(),
                                                  }
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