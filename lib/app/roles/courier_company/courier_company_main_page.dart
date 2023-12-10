import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/app/commons/animation_controller_class.dart';
import 'package:geo_couriers/app/commons/mini_menu/mini_menu.dart';
import 'package:geo_couriers/app/roles/sender/orders/parcels_orders/registered_orders/active_jobs_page.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../globals.dart';
import '../../main_menu.dart';
import 'distributable_jobs_page.dart';

class CourierCompanyMainPage extends StatefulWidget {

  final String? kGoogleApiKey;

  CourierCompanyMainPage({required this.kGoogleApiKey});

  @override
  _CourierCompanyMainPage createState() => _CourierCompanyMainPage(kGoogleApiKey: kGoogleApiKey);
}

class _CourierCompanyMainPage extends State<CourierCompanyMainPage> {
  final String? kGoogleApiKey;

  _CourierCompanyMainPage({this.kGoogleApiKey});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  var _activeJobs = "";
  int? _activeJobsInt = 0;

  var _distributable = "";
  int? _distributableInt = 0;

  Future<bool> _ordersNavigationPageLoad() async {
    try {

      final res = await geoCourierClient.post('courier_company/get_courier_company_numbers');

      var body = res.data;

      _activeJobsInt = body["activeJobs"];
      _activeJobs = AppLocalizations.of(context)!.distributed + ":" + " " + _activeJobsInt.toString();


      _distributableInt = body["distributable"];
      _distributable = AppLocalizations.of(context)!.distributable + ":" + " " + _distributableInt.toString();



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

  Future<bool> _onBackPressed() {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MainMenu()),
    ).then((x) => x ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: _ordersNavigationPageLoad(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return PopScope(
                canPop: true,
                onPopInvoked: (bool didPop) {
                  _onBackPressed();
                },
                child: RefreshIndicator(
                    onRefresh: () => Future.sync(() => setState(() {}),),
                    child: Scaffold(
                      key: _scaffoldKey,
                      appBar: AppBar(),
                      drawer: Drawer(
                          child: MiniMenu()
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
                                        style: _activeJobsInt! >0 ? TextStyle(color: Colors.green) : TextStyle(),
                                      ),
                                      onTap: () {
                                        if (_activeJobsInt! >0) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => ActiveJobsPage(forCourier: false, kGoogleApiKey: kGoogleApiKey)),
                                          );
                                        }
                                      }
                                  ), 0.0),
                                  generateCard(ListTile(
                                      title: Text(
                                        _distributable,
                                        textAlign: TextAlign.center,
                                        style: _distributableInt! >0 ? TextStyle(color: Colors.red) : TextStyle(),
                                      ),
                                      onTap: () {
                                        if (_distributableInt! >0) {

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => DistributableJobsPage(kGoogleApiKey: kGoogleApiKey)),
                                          );

                                        }
                                      }
                                  ), 0.0)
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
                                setState(() {

                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                )
            );
          } else {
            return AnimationControllerClass();
          }
        }
    );
  }

}