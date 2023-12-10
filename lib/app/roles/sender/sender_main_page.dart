import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geo_couriers/app/commons/mini_menu/mini_menu.dart';
import 'package:geo_couriers/app/commons/info/info.dart';
import 'package:geo_couriers/app/main_menu.dart';
import 'package:geo_couriers/app/roles/sender/models/orders_couriers_info_model.dart';
import 'package:geo_couriers/app/roles/sender/orders/add_orders/add_order_page.dart';
import 'package:geo_couriers/app/roles/sender/orders/parcels_orders/orders_navigation_page.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class SenderMainPage extends StatefulWidget {

  final String? kGoogleApiKey;

  SenderMainPage({required this.kGoogleApiKey});
  
  @override
  _SenderMainPage createState() => _SenderMainPage(kGoogleApiKey: kGoogleApiKey);
}

class _SenderMainPage extends State<SenderMainPage> with SingleTickerProviderStateMixin {

  final String? kGoogleApiKey;

  _SenderMainPage({this.kGoogleApiKey});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  late AnimationController _controller;
  late Animation<double> _animation;

  bool dir = true;

  Future<bool> _onBackPressed() {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MainMenu()),
    ).then((x) => x ?? false);
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: Duration(microseconds: 400000));
    super.initState();
  }

  @override
  void dispose(){
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    _animation = Tween<double>(
        begin: dir ? 0 : 2,
        end: dir ? 2 : 4
    ).animate(_controller);

    return PopScope(
        canPop: true,
        onPopInvoked: (bool didPop) {
          _onBackPressed();
        },
        child: Scaffold(
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
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
            drawer: Drawer(
                child: MiniMenu()
            ),
            endDrawer: Drawer(
                child: Info(
                    safeAreaChild: ListView(
                      children: <Widget>[
                        ListTile(
                          title: Row(
                            children: <Widget>[
                              Icon(Icons.shopping_cart, color: Colors.deepOrange),
                              Flexible(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(AppLocalizations.of(context)!.go_to_parcels_orders_section),
                                  )
                              ),
                            ],
                          ),
                        ),
                        Divider(
                            color: Colors.black
                        ),
                        ListTile(
                          title: Row(
                            children: <Widget>[
                              Icon(Icons.add, color: Colors.deepOrange),
                              Flexible(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(AppLocalizations.of(context)!.add_new_parcel),
                                  )
                              ),
                            ],
                          ),
                        ),
                        Divider(
                            color: Colors.black
                        ),
                        ListTile(
                          title: Row(
                            children: <Widget>[
                              Icon(Icons.phone, color: Colors.deepOrange),
                              Flexible(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(AppLocalizations.of(context)!.call_courier),
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
            body: Center(
                child: RotationTransition(
                  turns: _animation,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: FloatingActionButton(
                        child: Image.asset('assets/icons/courier.png'),
                        onPressed: (){
                          _controller.forward(
                              from: 0
                          );
                          setState(() {dir = !dir;});
                        }
                    ),
                  )
                )
            ),
            floatingActionButton: Padding(
              padding: EdgeInsets.all(1),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 30.0,
                  ),
                  Expanded(
                    child: FloatingActionButton(
                      heroTag: "btn1",
                      child: Icon(Icons.shopping_cart),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OrdersNavigationPage(kGoogleApiKey: kGoogleApiKey)),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 5.0,
                  ),
                  Expanded(
                    child: FloatingActionButton(
                      heroTag: "btn2",
                      child: Icon(Icons.add),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddOrderPage(kGoogleApiKey: kGoogleApiKey)),
                        );
                        if(TimeOfDay.now().hour > 12) {
                          showAlertDialog(context, AppLocalizations.of(context)!.sender_main_page_toast, AppLocalizations.of(context)!.attention);
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 5.0,
                  ),
                  Expanded(
                    child: FloatingActionButton(
                      heroTag: "btn4",
                      child: Icon(Icons.phone),
                      onPressed: () async {
                        try {

                          final res = await geoCourierClient.post('orders_sender/orders_couriers_info');

                          if(res.statusCode ==200) {
                            List<OrdersCouriersInfoModel> _ordersInfo = List<OrdersCouriersInfoModel>.from(res.data.map((i) => OrdersCouriersInfoModel.fromJson(i)));
                            HashMap<int?, String> _addressMap = new HashMap<int?, String>();

                            for (var e in _ordersInfo) {
                              var la = double.parse(e.parcelAddressToBeDeliveredLatitude!);
                              var lo = double.parse(e.parcelAddressToBeDeliveredLongitude!);

                              var addressC = await getPlaceFormattedAddressViaCoordinates(la, lo, kGoogleApiKey, context);
                              if (addressC !=null) {
                                _addressMap[e.id] = addressC;
                              }
                            }

                            showModalBottomSheet<void>(
                              context: context,
                              builder: (BuildContext context) {
                                return Scrollbar(
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(_ordersInfo.length, (index) {
                                          var ordInfo = _ordersInfo[index];

                                          return generateCard(
                                              Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 10.0, right: 10.0, top: 2.0),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.max,
                                                    children: <Widget>[
                                                      Expanded(
                                                          flex: 6,
                                                          child: ListTile(
                                                              title: Text(_addressMap.isEmpty ? "" : _addressMap[ordInfo.id]!,
                                                                style: TextStyle(
                                                                  fontFamily: 'Pacifico',
                                                                  fontSize: 15.0,
                                                                ),
                                                              ),
                                                              onTap: () {
                                                              }
                                                          )
                                                      ),
                                                      Expanded(
                                                          flex: 1,
                                                          child: ListTile(
                                                              title: Icon(Icons.call, color: Colors.green),
                                                              onTap: () {
                                                                launchUrl(Uri.parse('tel:' + ordInfo.courierPhone.toString()));
                                                              }
                                                          )
                                                      ),
                                                    ],
                                                  )
                                              ), 10.0
                                          );
                                        })
                                    ),
                                  ),
                                );
                              },
                            );
                          }

                        } catch (e) {
                          if (e is DioException && e.response?.statusCode == 403) {
                            reloadApp(context);
                          } else {
                            showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
                          }
                          return;
                        }
                      },
                    ),
                  ),
                ],
              ),
            )
        )
    );
  }

}