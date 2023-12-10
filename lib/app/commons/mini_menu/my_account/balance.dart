import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/app/commons/animation_controller_class.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../globals.dart';
import 'debts_page.dart';
import 'models/balance_model.dart';

class Balance extends StatefulWidget {
  @override
  _Balance createState() => _Balance();
}


class _Balance extends State<Balance> {

  BalanceModel _model = BalanceModel();
  DateTime _selectedDateFrom = DateTime.now().subtract(const Duration(days: 1));
  DateTime _selectedDateTo = DateTime.now();
  final _formatter = new DateFormat('dd-MMM-yy');
  String _deposit = "????";

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {

    final DateTime? _picked = await showDatePicker(
        context: context,
        initialEntryMode: DatePickerEntryMode.calendar,
        initialDate: isFromDate ? _selectedDateFrom : _selectedDateTo,
        firstDate: DateTime(2021, 1),
        lastDate: DateTime(3000)
    );

    var _selectedDate = isFromDate ? _selectedDateFrom : _selectedDateTo;

    if (_picked != null && _picked != _selectedDate)
      setState(() {
        isFromDate ? _selectedDateFrom = _picked : _selectedDateTo = _picked;
      });
  }

  Future<bool> _statisticsPageLoad() async {

    try {

      final res = await geoCourierClient.post(
        'balance/get_deposit',
      );

      _deposit = res.data !=null ? res.data : "????";

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
                  leading: Builder(
                    builder: (BuildContext context) {
                      return IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () { Navigator.pop(context,false); },
                      );
                    },
                  ),
                  title: ListTile(
                      title: Text(
                        _formatter.format(_selectedDateFrom) + " - " + _formatter.format(_selectedDateTo),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(' '),
                              content: Text("აიღჩიეთ თარიღები",
                                textAlign: TextAlign.center,
                              ),
                              actionsAlignment: MainAxisAlignment.center,
                              actions: <Widget>[
                                OutlinedButton(
                                  child: Text("დან"),
                                  onPressed: () async {
                                    await _selectDate(context, true);
                                  }, //exit the app
                                ),
                                OutlinedButton(
                                  child: Text("მდე"),
                                  onPressed: () async {
                                    await _selectDate(context, false);
                                  }, //exit the app
                                ),
                              ],
                            )
                        );
                      }
                  ),
                ),
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...[
                        SizedBox(height: 10,),
                        Text(
                          AppLocalizations.of(context)!.deposit,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.deepOrange
                          )
                        ),
                        ListTile(
                          title: Text(
                            _deposit,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 50
                            ),
                          ),
                          onTap: () {

                            showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(' '),
                                  content: Text(AppLocalizations.of(context)!.deposit,
                                    textAlign: TextAlign.center,
                                  ),
                                  actionsAlignment: MainAxisAlignment.center,
                                  actions: <Widget>[
                                    OutlinedButton(
                                      child: Text("თანხის გატანა"),
                                      onPressed: () async {
                                        // TODO : შეამოწმე ამ კურიერის მიერ შესრულებული ამანათების ვალები ყველა გადახდილია თუ არა
                                        //  და ასევე შეამოწმე ამ გამგზავნის მიერ შექმნილი ყველა ამანათის ვალები გადახდილია თუ არა
                                        //  deposit_cash_flow-ში შეიტანე ინფო


                                      }, //exit the app
                                    ),
                                    OutlinedButton(
                                      child: Text("თანხის შეტანა"),
                                      onPressed: () async {
                                        // TODO : ბარათიდან დეპოზიტზე თანხის შეტანაა გასაკეთებელი
                                        //  deposit_cash_flow-ში შეიტანე ინფო


                                      }, //exit the app
                                    ),
                                  ],
                                )
                            );

                          },
                        ),
                        SizedBox(height: 10,),
                        generateCard(ListTile(
                          title: Text(
                            AppLocalizations.of(context)!.courier,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold
                            ),
                          )
                        ), 0.0),
                        ListTile(
                            title: Text(
                              _model.parcelsAsCourier != null ?
                              AppLocalizations.of(context)!.order_count + ": " + _model.parcelsAsCourier! :
                              AppLocalizations.of(context)!.order_count,
                              textAlign: TextAlign.center,
                            )
                        ),
                        ListTile(
                          title: Text(
                            _model.serviceParcelPriceCourier != null ?
                            AppLocalizations.of(context)!.cost_of_parcels + ": " + _model.serviceParcelPriceCourier! :
                            AppLocalizations.of(context)!.cost_of_parcels,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        ListTile(
                          title: Text(
                            _model.servicePrice != null ?
                            AppLocalizations.of(context)!.courier_fee + _model.servicePrice! :
                            AppLocalizations.of(context)!.courier_fee,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        generateCard(ListTile(
                            title: Text(
                              AppLocalizations.of(context)!.sender,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold
                              ),
                            )
                        ), 0.0),
                        ListTile(
                          title: Text(
                            _model.parcelsAsSender != null ?
                            AppLocalizations.of(context)!.order_count + ": " + _model.parcelsAsSender! :
                            AppLocalizations.of(context)!.order_count,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        ListTile(
                          title: Text(
                            _model.serviceParcelPriceSender != null ?
                            AppLocalizations.of(context)!.cost_of_parcels + ": " + _model.serviceParcelPriceSender! :
                            AppLocalizations.of(context)!.cost_of_parcels,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 20,),
                        ListTile(
                          title: Text(
                            _model.ourShare != null ?
                            AppLocalizations.of(context)!.courier_commission_fee + ": " + _model.ourShare! :
                            AppLocalizations.of(context)!.courier_commission_fee,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        SizedBox(height: 30,),
                        ListTile(
                            title: Text(
                              _model.cardDebt != null ?
                              AppLocalizations.of(context)!.debt_on_the_card + ": " + _model.cardDebt! :
                              AppLocalizations.of(context)!.debt_on_the_card,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DebtsPage(deposit: false, card: true)),
                              );
                            }
                        ),
                        ListTile(
                            title: Text(
                              _model.depositDebt != null ?
                              AppLocalizations.of(context)!.debt_on_the_deposit + ": " + _model.depositDebt! :
                              AppLocalizations.of(context)!.debt_on_the_deposit,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DebtsPage(deposit: true, card: false)),
                              );
                            }
                        ),
                      ].expand((widget) => [widget])
                    ],
                  ),
                ),
                floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                        child: Icon(Icons.refresh),
                        onPressed: () async {

                          try {

                            final res = await geoCourierClient.post(
                              'balance/get_balance_statistics',
                              queryParameters: {
                                "selectedDateFrom": _selectedDateFrom,
                                "selectedDateTo": _selectedDateTo,
                              },
                            );

                            setState(() {
                              _model.updateBalanceModel(res.data);
                            });

                          } catch (e) {
                            if (e is DioException && e.response?.statusCode == 403) {
                              reloadApp(context);
                            } else {
                              showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
                            }
                          }

                        },
                      ),
                    ],
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