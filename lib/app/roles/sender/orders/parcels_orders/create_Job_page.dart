import 'dart:async';
import 'dart:collection';

import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/roles/sender/models/create_job_parcels_list_model.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../main.dart';
import '../../../../commons/models/parcels_model.dart';

class CreateJobPage extends StatefulWidget {
  @override
  _CreateJobPage createState() => _CreateJobPage();
}


class _CreateJobPage extends State<CreateJobPage> {

  static const _pageSize = 10;

  final PagingController<int, Parcels> _pagingController = PagingController(firstPageKey: 0);
  HashMap<int, bool?> _checkBoxValuesMap = new HashMap<int, bool?>();
  List<CreateJobParcelsListModel> _parcels = List<CreateJobParcelsListModel>.empty(growable: true);

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
        'orders_sender/get_active_parcels_not_in_job',
        queryParameters: {
          "pageKey": pageKey.toString(),
          "pageSize": _pageSize.toString(),
        },
      );

      if(res.statusCode ==200) {
        List<Parcels> newItems = List<Parcels>.from(res.data.map((i) => Parcels.fromJson(i)));

        int j=0;
        if (_checkBoxValuesMap.isNotEmpty) {
          j = _checkBoxValuesMap.length;
        }
        for(int i=0; i < newItems.length; i++) {
          _checkBoxValuesMap[j] = false;
          var _model = new CreateJobParcelsListModel();
          _model.updateCreateJobParcelsListModel(newItems[i], i);
          _parcels.add(_model);
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
      appBar: AppBar(
        title: Text(""),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => {
          _pagingController.refresh(),
          _checkBoxValuesMap.clear(),
          _parcels.clear(),
        }),
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
                        Flexible(
                          child: Center(
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
                                    showParcelInfoDialog(item, context, dotenv.env['GOOGLE_API_KEY']!);
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
                              )
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
                                Flexible(
                                  child: CheckboxListTile(
                                    controlAffinity: ListTileControlAffinity.leading,
                                    value: _checkBoxValuesMap[index],
                                    onChanged: (newValue) {
                                      setState(() {
                                        _checkBoxValuesMap.update(index, (value) => newValue);
                                      });
                                    },
                                  ),
                                ),
                                MaterialButton(
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
                                                    _checkBoxValuesMap.clear();
                                                    _parcels.clear();
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
            ArgonTimerButton(
              height: 50,
              width: MediaQuery.of(context).size.width * 0.6,
              minWidth: MediaQuery.of(context).size.width * 0.55,
              highlightColor: Colors.transparent,
              highlightElevation: 0,
              roundLoadingShape: false,
              onTap: (startTimer, btnState) async {
                if (btnState == ButtonState.Idle) {
                  startTimer(2);

                  List<int?> _checkedParcels = List<int?>.empty(growable: true);
                  var _active = true;
                  var _hold = false;

                  var _continue = true;
                  await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title: Text(' '),
                        content: Text(AppLocalizations.of(context)!.register_order_question),
                        actions: <Widget>[
                          OutlinedButton(
                            child: Text(AppLocalizations.of(context)!.yes),
                            onPressed: () async {
                              _checkBoxValuesMap.forEach((key, value) {
                                if (value!) {
                                  _checkedParcels.add(_parcels.where((c) => c.id == key).first.orderId);
                                }
                              });
                              Navigator.pop(context,false);
                            }, //exit the app
                          ),
                          OutlinedButton(
                            child: Text(AppLocalizations.of(context)!.no),
                            onPressed: () async {
                              Navigator.pop(context,false);
                              _continue = false;
                            }, //
                          )
                        ],
                      )
                  );

                  if (_continue) {
                    await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(' '),
                          content: Text(AppLocalizations.of(context)!.create_active_job_or_hold),
                          actions: <Widget>[
                            OutlinedButton(
                              child: Text(AppLocalizations.of(context)!.yes),
                              onPressed: ()=> Navigator.pop(context,false),
                            ),
                            OutlinedButton(
                              child: Text(AppLocalizations.of(context)!.no),
                              onPressed: () async {
                                _active = false;
                                _hold = true;
                                Navigator.pop(context,false);
                              }, //
                            )
                          ],
                        )
                    );
                    try {

                      final res = await geoCourierClient.post(
                        'orders_sender/create_job',
                        queryParameters: {
                          "checkedParcels": _checkedParcels.toString(),
                          "active": _active.toString(),
                          "hold": _hold.toString(),
                        },
                      );

                      if(res.statusCode ==200) {
                        _pagingController.refresh();
                        _checkBoxValuesMap.clear();
                        _parcels.clear();
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
              },
              child: Text(
                AppLocalizations.of(context)!.place_order,
                style: TextStyle(
                    color: Colors.white
                ),
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
          ],
        ),
      ),

    );
  }


}