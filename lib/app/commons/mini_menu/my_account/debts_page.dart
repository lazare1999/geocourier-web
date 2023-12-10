import 'dart:async';

import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/commons/info/info.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'models/debts.dart';

class DebtsPage extends StatefulWidget {

  final bool? card;
  final bool? deposit;

  DebtsPage({required this.card, required this.deposit});

  @override
  _DebtsPage createState() => _DebtsPage(card: card, deposit: deposit);
}

class _DebtsPage extends State<DebtsPage> {

  final bool? card;
  final bool? deposit;

  _DebtsPage({required this.card, required this.deposit});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  static const _pageSize = 10;

  final PagingController<int, Debts> _pagingController = PagingController(firstPageKey: 0);

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
        'balance/get_card_debts',
        queryParameters: {
          "pageKey": pageKey,
          "pageSize": _pageSize,
          "card": card,
          "deposit": deposit,
        },
      );

      if(res.statusCode ==200) {
        List<Debts> newItems = List<Debts>.from(res.data.map((i) => Debts.fromJson(i)));

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

    String _payDebtText = "";
    if (deposit!) {
      _payDebtText = AppLocalizations.of(context)!.payment_of_debt_on_deposit;
    } else if (card!) {
      _payDebtText = AppLocalizations.of(context)!.payment_of_debt_on_card;
    }

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
                
              ],
            ),
            youtubeLink: "https://www.youtube.com/watch?v=Cb8gQVwByNM"
          )
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh(),),
        child: PagedListView<int, Debts>.separated(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<Debts>(
            itemBuilder: (context, item, index) {

              return generateCard(
                  Padding(
                      padding: EdgeInsets.only(
                          left: 25.0, right: 25.0, top: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          card! ? Expanded(
                            child: Text("ვალი ბარათზე " + item.cardDebt.toString())
                          ) : Visibility(
                            visible: false, child: Container(),
                          ),
                          deposit! ? Expanded(
                              child: Text("ვალი დეპოზიტზე " + item.cardDebt.toString())
                          ) : Visibility(
                            visible: false, child: Container(),
                          ),
                          Expanded(
                              child: Text("დაემატა " + item.addDate.toString())
                          ),
                          Expanded(
                              child: Text(item.paid! ? "გადახდილია" : "გადასახდელია")
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
            ArgonTimerButton(
              height: 50,
              width: MediaQuery.of(context).size.width * 0.55,
              minWidth: MediaQuery.of(context).size.width * 0.5,
              highlightColor: Colors.transparent,
              highlightElevation: 0,
              roundLoadingShape: false,
              onTap: (startTimer, btnState) async {
                if (btnState == ButtonState.Idle) {
                  startTimer(5);

                  if(deposit!) {

                    try {

                      final res = await geoCourierClient.post(
                        'balance/pay_deposit_debt',
                      );

                      switch (res.data) {
                        case "UNEXPECTED_ERROR" : showAlertDialog.call(context, AppLocalizations.of(context)!.an_error_occurred, ""); break;
                        case "YOU_DID_NOT_HAVE_DEPOSIT_DEBTS" : showAlertDialog.call(context, AppLocalizations.of(context)!.you_have_no_debt_on_the_deposit, ""); break;
                        case "DEPOSIT_BALANCE_IS_NOT_ENOUGH" : showAlertDialog.call(context, AppLocalizations.of(context)!.there_is_insufficient_amount_on_the_deposit, ""); break;
                        case "DEBT_IS_PAID" : showAlertDialog.call(context, AppLocalizations.of(context)!.the_debt_is_paid, ""); break;
                        default : showAlertDialog.call(context, AppLocalizations.of(context)!.an_error_occurred, "");
                      }


                    } catch (e) {
                      if (e is DioException && e.response?.statusCode == 403) {
                        reloadApp(context);
                      } else {
                        showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
                      }
                      return;
                    }

                  } else if (card!) {
                    //  TODO : ვალის გადახდა ბარათით
                    await geoCourierClient.post('balance/pay_card_debt');
                  }

                }
              },
              child: Text(_payDebtText,
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
          ],
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