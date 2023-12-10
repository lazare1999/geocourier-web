
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geo_couriers/app/commons/animation_controller_class.dart';
import 'package:geo_couriers/app/commons/star_rating.dart';
import 'package:geo_couriers/app/roles/courier/orders_control_panel/handed_over_Jobs_to_courier_page.dart';
import 'package:geo_couriers/app/roles/sender/orders/parcels_orders/registered_orders/active_jobs_page.dart';
import 'package:geo_couriers/app/roles/sender/orders/parcels_orders/registered_orders/done_jobs_page.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class CourierOrdersControlPanel extends StatefulWidget {
  final String? kGoogleApiKey;

  CourierOrdersControlPanel({required this.kGoogleApiKey});

  @override
  _CourierOrdersControlPanel createState() => _CourierOrdersControlPanel(kGoogleApiKey: kGoogleApiKey);
}

class _CourierOrdersControlPanel extends State<CourierOrdersControlPanel> {

  final String? kGoogleApiKey;

  _CourierOrdersControlPanel({required this.kGoogleApiKey});

  var _rating;

  var _activeJobs = "";
  int? _activeJobsInt = 0;

  var _doneJobs = "";
  int? _doneJobsInt = 0;

  var _handedOverJobs = "";
  int? _handedOverJobsInt = 0;

  Future<bool> _courierOrdersControlPanelLoad() async {
    try {

      final res = await geoCourierClient.post('orders_courier/get_courier_jobs');

      if(res.statusCode ==200) {
        var body = res.data;
        _activeJobs = AppLocalizations.of(context)!.active + " " + body["activeJobs"].toString();
        _activeJobsInt = body["activeJobs"];

        _doneJobs = AppLocalizations.of(context)!.completed + " " + body["doneJobs"].toString();
        _doneJobsInt = body["doneJobs"];

        _handedOverJobs = AppLocalizations.of(context)!.handed_over_jobs + " " + body["handedOverJobs"].toString();
        _handedOverJobsInt = body["handedOverJobs"];

      }

    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        reloadApp(context);
      } else {
        showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
      }
      return false;
    }

    try {

      final res = await geoCourierClient.post('miniMenu/get_rating');

      if(res.statusCode ==200) {
        if (res.data == null) {
          return false;
        }
        _rating = res.data.toString();
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        reloadApp(context);
      } else {
        showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
      }
      return false;
    }

    return true;
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: _courierOrdersControlPanelLoad(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return RefreshIndicator(
                onRefresh: () => Future.sync(() => setState(() {}),),
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(AppLocalizations.of(context)!.parcels_orders),
                  ),
                  body: Center(
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ...[
                              generateCard(ListTile(
                                  title: Text(
                                    _activeJobs,
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () {
                                    if (_activeJobsInt! >0) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => ActiveJobsPage(forCourier: true, kGoogleApiKey: kGoogleApiKey)),
                                      );
                                    }
                                  }
                              ), 0.0),
                              generateCard(ListTile(
                                  title: Text(
                                    _doneJobs,
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () {
                                    if (_doneJobsInt! >0) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => DoneJobsPage(forCourier: true, kGoogleApiKey: kGoogleApiKey)),
                                      );
                                    }
                                  }
                              ), 0.0),
                              generateCard(ListTile(
                                  title: Text(
                                    _handedOverJobs,
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () {
                                    if (_handedOverJobsInt! >0) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => HandedOverJobsToCourierPage(kGoogleApiKey: kGoogleApiKey)),
                                      );
                                    }
                                  }
                              ), 0.0),
                              generateCard(ListTile(
                                title: StarRating(rating: _rating !=null ? double.parse(_rating) : 0),
                                onTap: () {
                                  showAlertDialog(context, AppLocalizations.of(context)!.my_rating, "");
                                } ,
                              ), 10.0),
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
                          child: Icon(Icons.autorenew),
                          onPressed: () {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                )
            );
          } else {
            return AnimationControllerClass();
          }
        }
    );
  }

}