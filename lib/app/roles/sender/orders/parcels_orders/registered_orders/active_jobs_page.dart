import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/roles/sender/models/Jobs_model.dart';
import 'package:geo_couriers/app/roles/sender/orders/parcels_orders/registered_orders/parcels_list_by_job_page.dart';
import 'package:geo_couriers/app/commons/info/info.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../../../main.dart';

class ActiveJobsPage extends StatefulWidget {
  final bool forCourier;
  final String? kGoogleApiKey;

  ActiveJobsPage({required this.forCourier, required this.kGoogleApiKey});
  
  @override
  _ActiveJobsPage createState() => _ActiveJobsPage(forCourier: forCourier, kGoogleApiKey: kGoogleApiKey);
}

class _ActiveJobsPage extends State<ActiveJobsPage> {
  final bool forCourier;
  final String? kGoogleApiKey;

  _ActiveJobsPage({required this.forCourier, required this.kGoogleApiKey});

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

      var url ='';
      if (forCourier) {
        url = 'orders_courier/get_active_courier_jobs';
      } else {
        url = 'orders_sender/get_active_jobs';
      }

      final res = await geoCourierClient.post(
        url,
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
                forCourier ? Container() : ListTile(
                  title: Row(
                    children: <Widget>[
                      Image.asset('assets/icons/courier.png', width: 40, height: 40,),
                      Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(AppLocalizations.of(context)!.order_serving_courier_info),
                          )
                      ),
                    ],
                  ),
                ),
                forCourier ? Container() : Divider(
                    color: Colors.black
                ),
                ListTile(
                  title: Row(
                    children: <Widget>[
                      Image.asset('assets/images/box.png', width: 40, height: 40,),
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text(AppLocalizations.of(context)!.order_menu_detailed_info),
                        )
                      ),
                    ],
                  ),
                ),
                Divider(
                    color: Colors.black
                ),
                forCourier ? Container() : ListTile(
                  title: Row(
                    children: <Widget>[
                      SizedBox(width: 5,),
                      Icon(Icons.cancel_outlined, color: Colors.red),
                      SizedBox(width: 20,),
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            children: <TextSpan>[
                              TextSpan(
                                text: AppLocalizations.of(context)!.stop_order_info,
                                style: TextStyle(
                                    color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.normal
                                )
                              ),
                              TextSpan(
                                text: AppLocalizations.of(context)!.order_not_yet_placed_info,
                                style: TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold
                                )
                              ),
                            ],
                          ),
                        ),
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

              return Column(
                children: [
                  ...[
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Expanded(
                            child: Center(
                              child: Text(_jobName),
                            )
                        ),
                      ],
                    ),
                    generateCard(
                        Padding(
                            padding: EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
                            child: Column(
                              children: [
                                ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: <Widget>[
                                      forCourier ? Container() : item.courierUserId ==null ? Container() : Expanded(
                                        child: MaterialButton(
                                          child: Image.asset('assets/icons/courier.png', width: 30, height: 30,),
                                          onPressed: () {
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: MaterialButton(
                                            child: Image.asset('assets/images/box.png', width: 40, height: 40,),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => ParcelsListByJobPage(orderJobId: item.orderJobId, kGoogleApiKey: kGoogleApiKey, orderHasCourier: item.courierUserId !=null)),
                                              );
                                            }
                                        ),
                                      ),
                                      forCourier ? Container() : Expanded(
                                          child: MaterialButton(
                                            child: Icon(Icons.cancel_outlined, color: Colors.red),
                                            onPressed: () async {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: Text(' '),
                                                    content: Text(AppLocalizations.of(context)!.do_you_really_want_hold_job),
                                                    actions: <Widget>[
                                                      OutlinedButton(
                                                        child: Text(AppLocalizations.of(context)!.yes),
                                                        onPressed: () async {
                                                          try {

                                                            final res = await geoCourierClient.post(
                                                              'orders_sender/hold_job',
                                                              queryParameters: {
                                                                "orderJobId": item.orderJobId.toString(),
                                                              },
                                                            );

                                                            if(res.statusCode ==200) {
                                                              _pagingController.refresh();
                                                              Navigator.pop(context,false);

                                                              switch (res.data) {
                                                                case "job_can_not_be_hold" : showAlertDialog.call(context, AppLocalizations.of(context)!.job_can_not_be_hold, ""); break;
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
                                  ),
                                ]
                              ],
                            )
                        ), 10.0
                    ),
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