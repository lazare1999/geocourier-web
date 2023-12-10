import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geo_couriers/app/commons/animation_controller_class.dart';
import 'package:geo_couriers/app/roles/sender/orders/parcels_orders/statistics_page.dart';
import 'package:geo_couriers/app/commons/info/info.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../main.dart';
import 'create_Job_page.dart';
import 'registered_orders/active_jobs_page.dart';
import 'registered_orders/on_hold_jobs_page.dart';

class OrdersNavigationPage extends StatefulWidget {

  final String? kGoogleApiKey;

  OrdersNavigationPage({required this.kGoogleApiKey});

  @override
  _OrdersNavigationPage createState() => _OrdersNavigationPage(kGoogleApiKey: kGoogleApiKey);
}

class _OrdersNavigationPage extends State<OrdersNavigationPage> {
  final String? kGoogleApiKey;

  _OrdersNavigationPage({this.kGoogleApiKey});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  var _activeJobs = "";
  int? _activeJobsInt = 0;

  var _onHoldJobs = "";
  int? _onHoldJobsInt = 0;

  Future<bool> _ordersNavigationPageLoad() async {
    try {

      final res = await geoCourierClient.post('orders_sender/get_jobs');

      if(res.statusCode ==200) {
        var body = res.data;

        _activeJobs = AppLocalizations.of(context)!.active + " " + body["activeJobs"].toString();
        _activeJobsInt = body["activeJobs"];

        _onHoldJobs = AppLocalizations.of(context)!.not_yet_placed + " " + body["onHoldJobs"].toString();
        _onHoldJobsInt = body["onHoldJobs"];

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
        future: _ordersNavigationPageLoad(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return RefreshIndicator(
              onRefresh: () => Future.sync(() => setState(() {}),),
              child: Scaffold(
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
                                  child: RichText(
                                    text: TextSpan(
                                      text: AppLocalizations.of(context)!.handed_over_jobs2,
                                      style: TextStyle(
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: AppLocalizations.of(context)!.when_client_himself_wrote_us_order,
                                            style: TextStyle(
                                                color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                                                fontWeight: FontWeight.normal
                                            )
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                          ),
                          ListTile(
                            title: Row(
                              children: <Widget>[
                                Flexible(
                                  child: RichText(
                                    text: TextSpan(
                                      text: AppLocalizations.of(context)!.active2,
                                      style: TextStyle(
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: AppLocalizations.of(context)!.and_non_standard,
                                            style: TextStyle(
                                                color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                                                fontWeight: FontWeight.normal
                                            )
                                        ),
                                        TextSpan(
                                            text: "\""+ AppLocalizations.of(context)!.not_yet_placed +"\"",
                                            style: TextStyle(
                                                color: Colors.deepOrange,
                                                fontWeight: FontWeight.bold
                                            )
                                        ),
                                        TextSpan(
                                            text: AppLocalizations.of(context)!.clicking_on_will_take_you_to_the_appropriate_section,
                                            style: TextStyle(
                                                color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                                                fontWeight: FontWeight.normal
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
                body: Center(
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ...[
                            Row(
                              children: <Widget>[
                                Expanded(
                                    child: Center(
                                      child: Text(
                                        AppLocalizations.of(context)!.registered_orders,
                                        style: TextStyle(
                                          fontSize: 18,
                                          // color: Colors.black,
                                          fontWeight: FontWeight.bold
                                        ),
                                      )
                                    )
                                ),
                              ],
                            ),
                            generateCard(ListTile(
                                title: Text(
                                  _activeJobs,
                                  textAlign: TextAlign.center,
                                  style: _activeJobsInt! >0 ? TextStyle(color: Colors.red) : TextStyle(),
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
                                  _onHoldJobs,
                                  textAlign: TextAlign.center,
                                  style: _onHoldJobsInt! >0 ? TextStyle(color: Colors.red) : TextStyle(),
                                ),
                                onTap: () {
                                  if (_onHoldJobsInt! >0) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => OnHoldJobsPage(orderId: -1, forReassigningJob: false, kGoogleApiKey: kGoogleApiKey)),
                                    );
                                  }
                                }
                            ), 0.0),
                            Row(
                              children: <Widget>[
                                Expanded(
                                    child: MaterialButton(
                                      height: 42,
                                      color: Colors.deepOrangeAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18.0),
                                      ),
                                      child: Text(AppLocalizations.of(context)!.parcels,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => CreateJobPage()),
                                        );
                                      },
                                    )
                                ),
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(
                                    child: MaterialButton(
                                      height: 42,
                                      color: Colors.deepOrangeAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18.0),
                                      ),
                                      child: Text(AppLocalizations.of(context)!.statistics,
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => StatisticsPage()),
                                        );
                                      },
                                    )
                                ),
                              ],
                            ),
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
            );
          } else {
            return AnimationControllerClass();
          }
        }
    );
  }

}