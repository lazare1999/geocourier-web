import 'dart:async';
import 'dart:collection';

import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../custom/custom_icons.dart';
import '../../../main.dart';
import '../../commons/models/parcels_model.dart';
import '../sender/models/create_job_parcels_list_model.dart';
import 'hand_over_parcels_to_courier_users_page.dart';

class DistributableJobsPage extends StatefulWidget {
  final String? kGoogleApiKey;

  DistributableJobsPage({required this.kGoogleApiKey});

  @override
  _DistributableJobsPage createState() => _DistributableJobsPage(kGoogleApiKey: kGoogleApiKey);
}

class _DistributableJobsPage extends State<DistributableJobsPage> {

  final String? kGoogleApiKey;

  _DistributableJobsPage({required this.kGoogleApiKey});

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
        'courier_company/get_active_parcels_not_in_job_for_courier_company',
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
                                Flexible(
                                  flex: 2,
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
                                      )
                                  )
                                )
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
                  startTimer(5);

                  List<int?> _checkedParcels = List<int?>.empty(growable: true);
                  _checkBoxValuesMap.forEach((key, value) {
                    if (value!) {
                      _checkedParcels.add(_parcels.where((c) => c.id == key).first.orderId);
                    }
                  });

                  if (_checkedParcels.isEmpty) {
                    showAlertDialog(context, AppLocalizations.of(context)!.mark_the_parcels, "");
                    return;
                  }

                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title: Text(' '),
                        content: Text(AppLocalizations.of(context)!.register_order_question),
                        actions: <Widget>[
                          OutlinedButton(
                            child: Text(AppLocalizations.of(context)!.yes),
                            onPressed: () {
                              Navigator.pop(context,false);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => HandOverParcelsToCourierUsersPage(checkedParcels: _checkedParcels, pagingController: _pagingController)),
                              );
                            }, //exit the app
                          ),
                          OutlinedButton(
                            child: Text(AppLocalizations.of(context)!.no),
                            onPressed: () {
                              Navigator.pop(context,false);
                            }, //
                          )
                        ],
                      )
                  );

                }
              },
              child: Text(
                AppLocalizations.of(context)!.hand_over_to_courier,
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