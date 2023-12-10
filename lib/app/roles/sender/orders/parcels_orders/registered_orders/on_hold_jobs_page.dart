import 'dart:async';
import 'dart:collection';

import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/roles/sender/models/Jobs_model.dart';
import 'package:geo_couriers/app/roles/sender/orders/parcels_orders/registered_orders/hand_over_job_to_courier_users_page.dart';
import 'package:geo_couriers/app/roles/sender/orders/parcels_orders/registered_orders/on_hold_jobs_page_detailed.dart';
import 'package:geo_couriers/app/commons/info/info.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnHoldJobsPage extends StatefulWidget {

  final int? orderId;
  final bool forReassigningJob;
  final String? kGoogleApiKey;

  OnHoldJobsPage({this.orderId, required this.forReassigningJob, required this.kGoogleApiKey});

  @override
  _OnHoldJobsPage createState() => _OnHoldJobsPage(orderId: orderId, forReassigningJob: forReassigningJob, kGoogleApiKey: kGoogleApiKey);
}

class _OnHoldJobsPage extends State<OnHoldJobsPage> {
  final int? orderId;
  final bool forReassigningJob;
  final String? kGoogleApiKey;

  _OnHoldJobsPage({this.orderId, required this.forReassigningJob, this.kGoogleApiKey});

  static const _pageSize = 10;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  final PagingController<int, JobsModel> _pagingController = PagingController(firstPageKey: 0);

  HashMap<int, bool?> _checkBoxValuesMap = new HashMap<int, bool?>();

  List<JobsModel> _jobs = List<JobsModel>.empty(growable: true);

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
        'orders_sender/get_on_hold_jobs',
        queryParameters: {
          "pageKey": pageKey,
          "pageSize": _pageSize,
        },
      );

      if(res.statusCode ==200) {
        List<JobsModel> newItems = List<JobsModel>.from(res.data.map((i) => JobsModel.fromJson(i)));

        int j=0;
        if (_checkBoxValuesMap.isNotEmpty) {
          j = _checkBoxValuesMap.length;
        }
        for(int i=0; i < newItems.length; i++) {
          _checkBoxValuesMap[j] = false;
          var _model = new JobsModel();
          _model.update(newItems[i], i);
          _jobs.add(_model);
          j++;
        }

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
                forReassigningJob ? Container() : ListTile(
                  title: Row(
                    children: <Widget>[
                      Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: 20.0),
                            child: Text(AppLocalizations.of(context)!.throw_to_perform_info),
                          )
                      ),
                    ],
                  ),
                ),
                Divider(
                    color: Colors.black
                ),
                forReassigningJob ? Container() : ListTile(
                  title: Row(
                    children: <Widget>[
                      SizedBox(width: 5,),
                      Image.asset('assets/images/box.png', width: 40, height: 40,),
                      Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: 6.0),
                            child: Text(AppLocalizations.of(context)!.order_menu_info),
                          )
                      ),
                    ],
                  ),
                ),
                Divider(
                    color: Colors.black
                ),
                forReassigningJob ? Container() : ListTile(
                  title: Row(
                    children: <Widget>[
                      SizedBox(width: 5,),
                      Icon(Icons.remove_circle_outline, color: Colors.red),
                      Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: 20.0),
                            child: Text(AppLocalizations.of(context)!.remove_order_info),
                          )
                      ),
                    ],
                  ),
                ),
                Divider(
                    color: Colors.black
                ),
                forReassigningJob ? Container() : ListTile(
                  title: Row(
                    children: <Widget>[
                      SizedBox(width: 5,),
                      Icon(Icons.edit, color: Colors.deepOrange),
                      Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: 20.0),
                            child: Text(AppLocalizations.of(context)!.rename_order_info),
                          )
                      ),
                    ],
                  ),
                )
              ],
            ),
            youtubeLink: "https://www.youtube.com/watch?v=Cb8gQVwByNM"
          )
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => {
          _pagingController.refresh(),
          _checkBoxValuesMap.clear(),
        }),

        child: PagedListView<int, JobsModel>.separated(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<JobsModel>(
            itemBuilder: (context, item, index) {

              var _jobName = "";



              _jobName += "N" + item.orderJobId.toString();
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
                              child: MaterialButton(
                                  child: Text(_jobName),
                                  onPressed: () async {

                                    if (forReassigningJob) {

                                      try {

                                        final res = await geoCourierClient.post(
                                          'orders_sender/sent_order_to_another_job',
                                          queryParameters: {
                                            "orderId": orderId.toString(),
                                            "newJobId": item.orderJobId.toString(),
                                          },
                                        );

                                        if(res.statusCode ==200) {
                                          Navigator.pop(context,false);
                                          Navigator.pop(context,false);
                                          Navigator.pop(context,false);
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
                                      showModalBottomSheet<void>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Container(
                                            height: 200,
                                            // color: Colors.white,
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  MaterialButton(
                                                    child: Text(AppLocalizations.of(context)!.activate_order),
                                                    onPressed: () {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) => AlertDialog(
                                                            title: Text(' '),
                                                            content: Text(AppLocalizations.of(context)!.do_you_really_want_activate_job),
                                                            actions: <Widget>[
                                                              OutlinedButton(
                                                                child: Text(AppLocalizations.of(context)!.yes),
                                                                onPressed: () async {
                                                                  try {

                                                                    final res = await geoCourierClient.post(
                                                                      'orders_sender/activate_job',
                                                                      queryParameters: {
                                                                        "orderJobId": item.orderJobId.toString(),
                                                                      },
                                                                    );

                                                                    if(res.statusCode ==200) {
                                                                      _pagingController.refresh();
                                                                      Navigator.pop(context,false);
                                                                      Navigator.pop(context,false);
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
                                                  ),
                                                  MaterialButton(
                                                    child: Text(AppLocalizations.of(context)!.hand_over_to_specific_courier),
                                                    onPressed: () {
                                                      if (item.orderJobId !=null) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(builder: (context) => HandOverJobToCourierUsersPage(item.orderJobId)),
                                                        );
                                                      }
                                                    },
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  }
                              ),
                            )
                        ),
                      ],
                    ),
                    generateCard(
                        Padding(
                            padding: EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                forReassigningJob ? Container() : Expanded(
                                  child: Checkbox(
                                    value: _checkBoxValuesMap[index],
                                    onChanged: (newValue) {
                                      setState(() {
                                        _checkBoxValuesMap.update(index, (value) => newValue);
                                      });
                                    },
                                  ),
                                ),
                                forReassigningJob ? Container() : Expanded(
                                  child: MaterialButton(
                                      child: Image.asset('assets/images/box.png', width: 40, height: 40,),
                                      onPressed: () {
                                        if (item.orderJobId !=null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => OnHoldJobsPageDetailed(orderJobId: item.orderJobId, kGoogleApiKey: kGoogleApiKey)),
                                          );
                                        }
                                      }
                                  ),
                                ),
                                forReassigningJob ? Container() : Expanded(
                                    child: MaterialButton(
                                      child: Icon(Icons.remove_circle_outline, color: Colors.red),
                                      onPressed: () async {
                                        showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(' '),
                                              content: Text(AppLocalizations.of(context)!.do_you_really_want_to_delete_job),
                                              actions: <Widget>[
                                                OutlinedButton(
                                                  child: Text(AppLocalizations.of(context)!.yes),
                                                  onPressed: () async {
                                                    try {

                                                      final res = await geoCourierClient.post(
                                                          'orders_sender/remove_job',
                                                          queryParameters: {
                                                            "orderJobId": item.orderJobId.toString(),
                                                          }
                                                      );

                                                      if(res.statusCode ==200) {
                                                        _checkBoxValuesMap.clear();
                                                        _pagingController.refresh();
                                                        Navigator.pop(context,false);
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
                                forReassigningJob ? Container() : Expanded(
                                    child: MaterialButton(
                                      child: Icon(Icons.edit, color: Colors.deepOrange),
                                      onPressed: () async {
                                        var _jobName = item.jobName;
                                        showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              content: Container(
                                                child: Form(
                                                  child: Scrollbar(
                                                    child: SingleChildScrollView(
                                                      padding: EdgeInsets.all(16),
                                                      child: Column(
                                                        children: [
                                                          ...[
                                                            TextFormField(
                                                              decoration: InputDecoration(
                                                                filled: true,
                                                                labelText: AppLocalizations.of(context)!.order_name,
                                                              ),
                                                              initialValue: item.jobName,
                                                              onChanged: (value) {
                                                                _jobName = value;
                                                              },
                                                            ),
                                                            MaterialButton(
                                                                color: Colors.deepOrange,
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(18.0),
                                                                ),
                                                                child: Text(
                                                                  AppLocalizations.of(context)!.save,
                                                                  style: TextStyle(color: Colors.white),
                                                                ),
                                                                onPressed: () async {
                                                                  try {

                                                                    final res = await geoCourierClient.post(
                                                                      'orders_sender/update_job_name',
                                                                      queryParameters: {
                                                                        "orderJobId": item.orderJobId.toString(),
                                                                        "jobName": _jobName.toString(),
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
                                                                }
                                                            )
                                                          ].expand(
                                                                (widget) => [
                                                              widget,
                                                              SizedBox(
                                                                height: 25,
                                                              )
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                        );
                                      },
                                    )
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
      floatingActionButton: forReassigningJob ? Container() : ArgonTimerButton(
        height: 50,
        width: MediaQuery.of(context).size.width * 0.55,
        minWidth: MediaQuery.of(context).size.width * 0.5,
        highlightColor: Colors.transparent,
        highlightElevation: 0,
        roundLoadingShape: false,
        onTap: (startTimer, btnState) async {
          if (btnState == ButtonState.Idle) {
            startTimer(2);

            List<int?> _checkedJobs = List<int?>.empty(growable: true);

            _checkBoxValuesMap.forEach((key, value) {
              if (value!) {
                _checkedJobs.add(_jobs.where((c) => c.id == key).first.orderJobId);
              }
            });
            
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(' '),
                  content: Text(AppLocalizations.of(context)!.hand_over_job_question),
                  actions: <Widget>[
                    OutlinedButton(
                      child: Text(AppLocalizations.of(context)!.yes),
                      onPressed: () async {

                        try {

                          final res = await geoCourierClient.post(
                              'orders_sender/hand_over_jobs_to_fav_courier_company',
                              queryParameters: {
                                "checkedJobs": _checkedJobs.toString(),
                              }
                          );

                          if (res.data == "choose_fav_courier_company") {
                            Navigator.pop(context, false);
                            showAlertDialog(context, AppLocalizations.of(context)!.choose_fav_courier_company, "");
                            return;
                          } else if (res.data == "check_jobs") {
                            Navigator.pop(context, false);
                            showAlertDialog(context, AppLocalizations.of(context)!.check_jobs, "");
                            return;
                          }

                          _pagingController.refresh();
                          _checkBoxValuesMap.clear();
                          Navigator.pop(context, false);

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
          }
        },
        child: Text(AppLocalizations.of(context)!.hand_over_to_courier_company,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white)
        ),
        loader: (timeLeft) {
          return Text(
            AppLocalizations.of(context)!.please_wait + " | $timeLeft",
            style: TextStyle(
                color: Colors.white
            ),
          );
        },
        borderRadius: 18.0,
        color: Colors.deepOrange,
        elevation: 0,
      )
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}