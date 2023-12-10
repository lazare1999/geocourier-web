import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/commons/animation_controller_class.dart';
import 'package:geo_couriers/app/roles/sender/models/parcel_and_orders_info_model.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPage createState() => _StatisticsPage();
}


class _StatisticsPage extends State<StatisticsPage> {
  ParcelAndOrdersInfoModel _model = ParcelAndOrdersInfoModel();

  Future<bool> _statisticsPageLoad() async {
    _model.todayParcels = "";
    _model.inActiveParcels = "";
    _model.parcelsWithOutJob = "";
    _model.madeParcels = "";
    _model.activeParcels = "";
    _model.allParcels = "";
    _model.todayJobs = "";
    _model.activeJobs = "";
    _model.onHoldJobs = "";
    _model.doneJobs = "";
    _model.allJobs = "";

    try {

      final res = await geoCourierClient.post('orders_sender/get_parcel_and_job_info');

      if(res.statusCode ==200) {
        _model.updateParcelAndOrdersInfo(res.data);
        _model.todayParcels = AppLocalizations.of(context)!.today + " " + _model.todayParcels!;
        _model.inActiveParcels = AppLocalizations.of(context)!.waiting_for_the_courier + " " + _model.inActiveParcels!;
        _model.parcelsWithOutJob = AppLocalizations.of(context)!.parcels_that_have_not_been_placed_as_an_order + " " + _model.parcelsWithOutJob!;
        _model.madeParcels = AppLocalizations.of(context)!.delivered + " " + _model.madeParcels!;
        _model.activeParcels = AppLocalizations.of(context)!.in_time_delivery + " " + _model.activeParcels!;
        _model.allParcels = AppLocalizations.of(context)!.all + " " + _model.allParcels!;
        _model.todayJobs = AppLocalizations.of(context)!.today + " " + _model.todayJobs!;
        _model.activeJobs = AppLocalizations.of(context)!.active + " " + _model.activeJobs!;
        _model.onHoldJobs = AppLocalizations.of(context)!.order_not_yet_placed + " " + _model.onHoldJobs!;
        _model.doneJobs = AppLocalizations.of(context)!.completed + " " + _model.doneJobs!;
        _model.allJobs = AppLocalizations.of(context)!.all + " " + _model.allJobs!;
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
        future: _statisticsPageLoad(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return RefreshIndicator(
              onRefresh: () => Future.sync(() => setState(() {}),),
              child: Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.statistics),
                ),
                floatingActionButton: FloatingActionButton(
                  heroTag: "btn1",
                  child: Icon(CustomIcons.fb_messenger),
                  onPressed: () {
                    launchUrl(Uri.parse("http://" +dotenv.env['MESSENGER']!), mode: LaunchMode.externalApplication);
                  },
                ),
                body: Form(
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(3),
                      child: Column(
                        children: [
                          ...[
                            SizedBox(),
                            generateCard(ListTile(
                                title: Text(
                                  AppLocalizations.of(context)!.parcels,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18
                                  ),
                                ),
                                onTap: () {
                                  setState(() {});
                                }
                            ), 0.0),
                            generateCard(ListTile(
                              title: Text(
                                _model.todayParcels!,
                                textAlign: TextAlign.center,
                              ),
                            ), 0.0),
                            generateCard(ListTile(
                              title: Text(
                                _model.inActiveParcels!,
                                textAlign: TextAlign.center,
                              ),
                            ), 0.0),
                            generateCard(ListTile(
                              title: Text(
                                _model.parcelsWithOutJob!,
                                textAlign: TextAlign.center,
                              ),
                            ), 0.0),
                            generateCard(ListTile(
                              title: Text(
                                _model.madeParcels!,
                                textAlign: TextAlign.center,
                              ),
                            ), 0.0),
                            generateCard(ListTile(
                              title: Text(
                                _model.activeParcels!,
                                textAlign: TextAlign.center,
                              ),
                            ), 0.0),
                            generateCard(ListTile(
                              title: Text(
                                _model.allParcels!,
                                textAlign: TextAlign.center,
                              ),
                            ), 0.0),
                            SizedBox(
                              height: 10,
                            ),
                            generateCard(ListTile(
                                title: Text(
                                  AppLocalizations.of(context)!.orders,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18
                                  ),
                                ),
                                onTap: () {
                                  setState(() {});
                                }
                            ), 0.0),
                            generateCard(ListTile(
                              title: Text(
                                _model.todayJobs!,
                                textAlign: TextAlign.center,
                              ),
                            ), 0.0),
                            generateCard(ListTile(
                              title: Text(
                                _model.activeJobs!,
                                textAlign: TextAlign.center,
                              ),
                            ), 0.0),
                            generateCard(ListTile(
                              title: Text(
                                _model.onHoldJobs!,
                                textAlign: TextAlign.center,
                              ),
                            ), 0.0),
                            generateCard(ListTile(
                              title: Text(
                                _model.doneJobs!,
                                textAlign: TextAlign.center,
                              ),
                            ), 0.0),
                            generateCard(ListTile(
                              title: Text(
                                _model.allJobs!,
                                textAlign: TextAlign.center,
                              ),
                            ), 0.0),
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
            );
          } else {
            return AnimationControllerClass();
          }
        }
    );
  }


}