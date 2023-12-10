import 'dart:async';

import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/commons/info/info.dart';
import 'package:geo_couriers/app/roles/sender/models/add_order_page_model.dart';
import 'package:geo_couriers/app/roles/sender/orders/add_orders/takeaway_address_google_map.dart';
import 'package:geo_couriers/app/roles/sender/orders/parcels_orders/create_Job_page.dart';
import 'package:geo_couriers/app/commons/animation_controller_class.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../main.dart';
import 'delivery_address_google_map.dart';
import 'hand_over_parcel_to_courier_users_page.dart';

class AddOrderPage extends StatefulWidget {
  final String? kGoogleApiKey;

  AddOrderPage({required this.kGoogleApiKey});

  @override
  _AddOrderPage createState() => _AddOrderPage(kGoogleApiKey: kGoogleApiKey);
}

class _AddOrderPage extends State<AddOrderPage> {

  final String? kGoogleApiKey;

  _AddOrderPage({this.kGoogleApiKey});

  var _addOrderPageModel = AddOrderPageModel();
  var _countryPhoneCode = "+995";

  var _markerValue1;
  var _markerValue2;
  
  bool _isCheckedTakeWayAddress = false;
  bool _showCheckedTakeWayAddress = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  Future<bool> _addOrderPageLoad() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if(prefs.getBool("show_checked_take_way_address") == true) {
      _showCheckedTakeWayAddress = true;
    } else {
      _showCheckedTakeWayAddress = false;
    }


    if (prefs.getDouble('parcel_pickup_address_latitude') !=null &&
        prefs.getDouble('parcel_pickup_address_longitude') !=null &&
        prefs.getString('pickup_admin_area') !=null && prefs.getString('pickup_admin_area')!.isNotEmpty &&
        prefs.getString('pickup_country_code') !=null && prefs.getString('pickup_country_code')!.isNotEmpty
    ) {
      _isCheckedTakeWayAddress = true;
    } else {
      _isCheckedTakeWayAddress = false;
    }



    if (_addOrderPageModel.express ==null) {
      _addOrderPageModel.express = false;
    }

    try {

      final res = await geoCourierClient.post('orders_sender/user_orders_count');

      if(res.statusCode ==200) {
        int parcelNo = res.data + 1;
        _addOrderPageModel.serviceParcelIdentifiable = AppLocalizations.of(context)!.parcel + " " + parcelNo.toString();
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

  Future<void> _updateAddOrderPageModel(AddOrderPageModel model) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (model.pickupAdminArea !=null &&
        model.pickupCountryCode !=null &&
        model.parcelPickupAddressLatitude !=null &&
        model.parcelPickupAddressLongitude !=null) {
      prefs.remove("show_checked_take_way_address");
      prefs.setBool("show_checked_take_way_address", true);
    }

    setState(() {
      _addOrderPageModel = model;
    });
  }

  Future<void> _updateMarker1(LatLng m) async {
    setState(() {
      _markerValue1 = m;
    });
  }

  Future<void> _updateMarker2(LatLng m) async {
    setState(() {
      _markerValue2 = m;
    });
  }

  Future<bool> _onBackPressed() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();



    if(prefs.getBool("show_checked_take_way_address") == true &&
        _isCheckedTakeWayAddress ==false
    ) {
      prefs.remove("show_checked_take_way_address");
    }


    return true;
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: true,
        onPopInvoked: (bool didPop) {
          _onBackPressed();
        },
        child: FutureBuilder<bool>(
            future: _addOrderPageLoad(),
            builder: (context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData) {
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
                                ListTile(
                                  title: Row(
                                    children: <Widget>[
                                      Flexible(
                                          child: Text(AppLocalizations.of(context)!.add_order_page_info_1)
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
                                      Icon(Icons.check_box_outline_blank),
                                      Flexible(
                                          child: Text(AppLocalizations.of(context)!.add_order_page_info_2)
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            youtubeLink: "https://www.youtube.com/watch?v=Cb8gQVwByNM"
                        )
                    ),
                    body: Form(
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(3),
                          child: Column(
                            children: [
                              ...[
                                SizedBox(),
                                generateCard(Center(
                                    child: DropdownButton(
                                        hint: Text(AppLocalizations.of(context)!.parcel_type),
                                        value: _addOrderPageModel.parcelType == null ? 0 : _addOrderPageModel.parcelType,
                                        items: {
                                          0 : AppLocalizations.of(context)!.small_parcel,
                                          1 : AppLocalizations.of(context)!.oversized_cargo,
                                          2 : AppLocalizations.of(context)!.food
                                        }.map((value, description) {
                                          return MapEntry(
                                              value,
                                              DropdownMenuItem<int>(
                                                value: value,
                                                child: Text(description),
                                              ));
                                        }).values.toList(),
                                        onChanged: (dynamic newValue) {
                                          setState(() {
                                            _addOrderPageModel.parcelType = newValue;
                                          });
                                        }
                                    )
                                ), 0.0),
                                generateCard(ListTile(
                                  title: Text(AppLocalizations.of(context)!.express, textAlign: TextAlign.center, style: TextStyle(
                                    fontFamily: 'Pacifico',
                                    // color: _addOrderPageModel.express! ? Colors.deepOrangeAccent : Colors.black,
                                    fontWeight: _addOrderPageModel.express! ? FontWeight.bold : FontWeight.normal,
                                  )),
                                  onTap: () {
                                    var newValue = _addOrderPageModel.express == null || !_addOrderPageModel.express! ? true : false;
                                    setState(() {
                                      _addOrderPageModel.express = newValue;
                                      if (newValue) {
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
                                                      child: Text(
                                                        AppLocalizations.of(context)!.deliver_in_exact_time,
                                                        style: TextStyle(
                                                          fontFamily: 'Pacifico',
                                                          fontSize: 14.0,
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        var value = await selectDate(context, " ");
                                                        _addOrderPageModel.serviceDateFrom =null;
                                                        _addOrderPageModel.serviceDateTo =null;
                                                        _addOrderPageModel.serviceDate = value;
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    MaterialButton(
                                                      child: Text(
                                                        AppLocalizations.of(context)!.deliver_time_period,
                                                        style: TextStyle(
                                                          fontFamily: 'Pacifico',
                                                          fontSize: 14.0,
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        var value = await selectDate(context, AppLocalizations.of(context)!.from_the_specified_time);
                                                        _addOrderPageModel.serviceDate = null;
                                                        _addOrderPageModel.serviceDateTo = null;
                                                        _addOrderPageModel.serviceDateFrom = value;

                                                        if (value !=null) {
                                                          showDialog(
                                                              context: context,
                                                              barrierDismissible: false,
                                                              builder: (context) => AlertDialog(
                                                                title: Text(' '),
                                                                content: Text(AppLocalizations.of(context)!.select_date_by_which_you_want_to_deliver),
                                                                actions: <Widget>[
                                                                  OutlinedButton(
                                                                    child: Text(AppLocalizations.of(context)!.resume),
                                                                    onPressed: () async {
                                                                      var serviceDateTo = await selectDate(context, AppLocalizations.of(context)!.before_the_specified_time);
                                                                      if (serviceDateTo !=null && value.isBefore(serviceDateTo)) {
                                                                        _addOrderPageModel.serviceDateTo = serviceDateTo;
                                                                        Navigator.pop(context);
                                                                        Navigator.pop(context);
                                                                      } else if (serviceDateTo !=null && value.isAfter(serviceDateTo)) {
                                                                        showAlertDialog(context, AppLocalizations.of(context)!.an_error_occurred_incorrect_time_interval, "");
                                                                      }
                                                                    },
                                                                  ),
                                                                ],
                                                              )
                                                          );
                                                        }

                                                      },
                                                    ),
                                                    MaterialButton(
                                                      child: Text(
                                                        AppLocalizations.of(context)!.deliver_from_the_specified_time,
                                                        style: TextStyle(
                                                          fontFamily: 'Pacifico',
                                                          fontSize: 14.0,
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        var serviceDateFrom = await selectDate(context, AppLocalizations.of(context)!.from_the_specified_time);
                                                        _addOrderPageModel.serviceDate = null;
                                                        _addOrderPageModel.serviceDateTo = null;
                                                        _addOrderPageModel.serviceDateFrom = serviceDateFrom;
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    MaterialButton(
                                                      child: Text(
                                                        AppLocalizations.of(context)!.deliver_before_the_specified_time,
                                                        style: TextStyle(
                                                          fontFamily: 'Pacifico',
                                                          fontSize: 14.0,
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        var serviceDateTo = await selectDate(context, AppLocalizations.of(context)!.before_the_specified_time);
                                                        _addOrderPageModel.serviceDate = null;
                                                        _addOrderPageModel.serviceDateTo = serviceDateTo;
                                                        _addOrderPageModel.serviceDateFrom = null;
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      } else {
                                        _addOrderPageModel.serviceDate = null;
                                        _addOrderPageModel.serviceDateTo = null;
                                        _addOrderPageModel.serviceDateFrom = null;
                                      }
                                    });
                                  } ,
                                ), 0.0),


                                Card(
                                  clipBehavior: Clip.antiAlias,
                                  margin: EdgeInsets.symmetric(
                                    vertical: 0.0,
                                    horizontal: 25.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50.0),
                                  ),
                                  // color: Colors.white,
                                  child: Padding(
                                      padding: EdgeInsets.only(
                                          left: 25.0, right: 25.0, top: 2.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: <Widget>[
                                          _showCheckedTakeWayAddress ? Flexible(
                                            child: Checkbox(
                                              // checkColor: Colors.white,
                                              value: _isCheckedTakeWayAddress,
                                              onChanged: (bool? value) async {

                                                if(_addOrderPageModel.parcelPickupAddressLatitude ==null ||
                                                _addOrderPageModel.parcelPickupAddressLongitude ==null ||
                                                _addOrderPageModel.pickupAdminArea ==null ||
                                                _addOrderPageModel.pickupCountryCode ==null) {
                                                  return;
                                                }

                                                final SharedPreferences prefs = await SharedPreferences.getInstance();

                                                if(value == true) {
                                                  prefs.setDouble('parcel_pickup_address_latitude', _addOrderPageModel.parcelPickupAddressLatitude!);
                                                  prefs.setDouble('parcel_pickup_address_longitude', _addOrderPageModel.parcelPickupAddressLongitude!);
                                                  prefs.setString('pickup_admin_area', _addOrderPageModel.pickupAdminArea.toString());
                                                  prefs.setString('pickup_country_code', _addOrderPageModel.pickupCountryCode.toString());
                                                  prefs.setBool("show_checked_take_way_address", value!);
                                                } else {
                                                  prefs.remove('parcel_pickup_address_latitude');
                                                  prefs.remove('parcel_pickup_address_longitude');
                                                  prefs.remove('pickup_admin_area');
                                                  prefs.remove('pickup_country_code');
                                                  prefs.remove('show_checked_take_way_address');
                                                }

                                                setState(() {
                                                  _isCheckedTakeWayAddress = value!;
                                                });
                                              },
                                            ),
                                          ): Visibility(
                                            visible: false, child: Container(),
                                          ),
                                          Flexible(
                                              flex: 4,
                                              child: ListTile(
                                                title: Text(
                                                  AppLocalizations.of(context)!.takeaway_address,
                                                  textAlign: TextAlign.center,
                                                ),
                                                onTap: () async {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => TakeawayAddressGoogleMap(markerValue2: _markerValue2, updateAddOrderPageModel: _updateAddOrderPageModel, markerValue1: _markerValue1, addOrderPageModel: _addOrderPageModel, kGoogleApiKey: kGoogleApiKey, updateMarker1: _updateMarker1)),
                                                  );
                                                } ,
                                              )
                                          ),
                                        ],
                                      )),
                                ),

                                generateCard(ListTile(
                                  title: Text(
                                    AppLocalizations.of(context)!.delivery_address,
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => DeliveryAddressGoogleMap(markerValue2: _markerValue2, updateAddOrderPageModel: _updateAddOrderPageModel, markerValue1: _markerValue1, addOrderPageModel: _addOrderPageModel, kGoogleApiKey: kGoogleApiKey, updateMarker2: _updateMarker2)),
                                    );
                                  } ,
                                ), 0.0),
                                generateCard(ListTile(
                                  title: Text(
                                    AppLocalizations.of(context)!.payment_method,
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () {
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
                                                Text(
                                                  AppLocalizations.of(context)!.i_will_pay_for_courier_services,
                                                  style: TextStyle(
                                                    fontFamily: 'Pacifico',
                                                    color: Colors.deepOrange,
                                                    fontWeight: FontWeight.bold,
                                                  ),

                                                ),
                                                MaterialButton(
                                                  child: Text(
                                                    AppLocalizations.of(context)!.by_card,
                                                    style: TextStyle(
                                                      fontFamily: 'Pacifico',
                                                      fontSize: 15.0,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    _addOrderPageModel.servicePaymentType =0;
                                                    Navigator.pop(context);
                                                    showAlertDialog(context, AppLocalizations.of(context)!.the_service_fee_will_be_deducted_from_bank_card, "");
                                                  },
                                                ),
                                                MaterialButton(
                                                  child: Text(
                                                    AppLocalizations.of(context)!.by_delivery_time,
                                                    style: TextStyle(
                                                      fontFamily: 'Pacifico',
                                                      fontSize: 15.0,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    _addOrderPageModel.servicePaymentType =1;
                                                    Navigator.pop(context);
                                                    showDialog(
                                                        context: context,
                                                        barrierDismissible: false,
                                                        builder: (context) => AlertDialog(
                                                          title: Text(' '),
                                                          content: Text(AppLocalizations.of(context)!.by_delivery_time),
                                                          actions: <Widget>[
                                                            OutlinedButton(
                                                              child: Text(AppLocalizations.of(context)!.the_client_will_pay_full_amount),
                                                              onPressed: () {
                                                                setState(() {
                                                                  _addOrderPageModel.courierHasParcelMoney = true;
                                                                });
                                                                Navigator.pop(context,false);
                                                              },
                                                            ),
                                                            OutlinedButton(
                                                              child: Text(AppLocalizations.of(context)!.the_client_will_pay_only_the_courier_fee),
                                                              onPressed: () {
                                                                setState(() {
                                                                  _addOrderPageModel.courierHasParcelMoney = false;
                                                                });
                                                                Navigator.pop(context,false);
                                                              },
                                                            )
                                                          ],
                                                        )
                                                    );
                                                  },
                                                ),
                                                MaterialButton(
                                                  child: Text(
                                                    AppLocalizations.of(context)!.when_taking_the_parcel,
                                                    style: TextStyle(
                                                      fontFamily: 'Pacifico',
                                                      fontSize: 15.0,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    _addOrderPageModel.servicePaymentType =2;
                                                    Navigator.pop(context);
                                                    showDialog(
                                                        context: context,
                                                        barrierDismissible: false,
                                                        builder: (context) => AlertDialog(
                                                          title: Text(' '),
                                                          content: Text(AppLocalizations.of(context)!.when_taking_the_parcel),
                                                          actions: <Widget>[
                                                            OutlinedButton(
                                                              child: Text(AppLocalizations.of(context)!.the_client_will_hand_over_the_cost_of_the_parcel_to_the_courier_and_i_will_pay_the_courier_fee),
                                                              onPressed: () {
                                                                setState(() {
                                                                  _addOrderPageModel.courierHasParcelMoney = true;
                                                                });
                                                                Navigator.pop(context,false);
                                                              },
                                                            ),
                                                            OutlinedButton(
                                                              child: Text(AppLocalizations.of(context)!.i_will_pay_only_the_courier_fee),
                                                              onPressed: () {
                                                                setState(() {
                                                                  _addOrderPageModel.courierHasParcelMoney = false;
                                                                });
                                                                Navigator.pop(context,false);
                                                              },
                                                            )
                                                          ],
                                                        )
                                                    );
                                                  },
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  } ,
                                ), 0.0),
                                Padding(
                                    padding: EdgeInsets.only(
                                        left: 20.0, right: 20.0, top: 2.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: <Widget>[
                                        Flexible(
                                          child:TextFormField(
                                            decoration: InputDecoration(
                                              filled: true,
                                              labelText: AppLocalizations.of(context)!.client_name,
                                            ),
                                            onChanged: (value) {
                                              if (value.isNotEmpty) {
                                                _addOrderPageModel.clientName = value;
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                                Padding(
                                    padding: EdgeInsets.only(
                                        left: 20.0, right: 20.0, top: 2.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: <Widget>[
                                        Flexible(
                                          child:TextFormField(
                                            initialValue: _addOrderPageModel.serviceParcelIdentifiable,
                                            decoration: InputDecoration(
                                              filled: true,
                                              labelText: AppLocalizations.of(context)!.parcel_identifier,
                                            ),
                                            onChanged: (value) {
                                              _addOrderPageModel.serviceParcelIdentifiable = value;
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                                Padding(
                                    padding: EdgeInsets.only(
                                        left: 20.0, right: 20.0, top: 2.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: <Widget>[
                                        Flexible(
                                          child:TextFormField(
                                            decoration: InputDecoration(
                                              filled: true,
                                              labelText: AppLocalizations.of(context)!.comment,
                                            ),
                                            onChanged: (value) {
                                              _addOrderPageModel.orderComment = value;
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                                Padding(
                                    padding: EdgeInsets.only(
                                        left: 20.0, right: 20.0, top: 2.0, bottom: _addOrderPageModel.courierHasParcelMoney != null && _addOrderPageModel.courierHasParcelMoney! ? 0.0 : 40.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: <Widget>[
                                        Expanded(
                                          child: CountryCodePicker(
                                            onChanged: (value) {
                                              _addOrderPageModel.viewerPhone = _addOrderPageModel.viewerPhone!.substring(_countryPhoneCode.length);
                                              _countryPhoneCode = value.dialCode!;
                                              _addOrderPageModel.viewerPhone = _countryPhoneCode + _addOrderPageModel.viewerPhone!;
                                            },
                                            initialSelection: 'GE',
                                            showCountryOnly: false,
                                            showOnlyCountryWhenClosed: false,
                                            alignLeft: false,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child:TextFormField(
                                            decoration: InputDecoration(
                                              filled: true,
                                              labelText: AppLocalizations.of(context)!.client_phone,
                                            ),
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              _addOrderPageModel.viewerPhone = _countryPhoneCode + value;
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                                Visibility(
                                    visible: _addOrderPageModel.courierHasParcelMoney != null && _addOrderPageModel.courierHasParcelMoney! ? true : false,
                                    child: Padding(
                                        padding: EdgeInsets.only(
                                            left: 20.0, right: 20.0, top: 2.0, bottom: 60),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: <Widget>[
                                            Flexible(
                                              child: TextFormField(
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  labelText: AppLocalizations.of(context)!.the_cost_of_the_parcel,
                                                ),
                                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'(^\d*\.?\d*)'))],
                                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                onChanged: (value) {
                                                  _addOrderPageModel.serviceParcelPrice = value;
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                    )
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
                            width: MediaQuery.of(context).size.width * 0.45,
                            minWidth: MediaQuery.of(context).size.width * 0.30,
                            highlightColor: Colors.transparent,
                            highlightElevation: 0,
                            roundLoadingShape: false,
                            onTap: (startTimer, btnState) async {
                              if (btnState == ButtonState.Idle) {
                                startTimer(5);
                                //ასაღები მისამართის კოორდინატები
                                final SharedPreferences prefs = await SharedPreferences.getInstance();

                                if (prefs.getDouble('parcel_pickup_address_latitude') !=null &&
                                    prefs.getDouble('parcel_pickup_address_longitude') !=null &&
                                    prefs.getString('pickup_admin_area') !=null && prefs.getString('pickup_admin_area')!.isNotEmpty &&
                                    prefs.getString('pickup_country_code') !=null && prefs.getString('pickup_country_code')!.isNotEmpty
                                ) {
                                  _addOrderPageModel.pickupAdminArea = prefs.getString('pickup_admin_area');
                                  _addOrderPageModel.pickupCountryCode = prefs.getString('pickup_country_code');
                                  _addOrderPageModel.parcelPickupAddressLatitude = prefs.getDouble('parcel_pickup_address_latitude');
                                  _addOrderPageModel.parcelPickupAddressLongitude = prefs.getDouble('parcel_pickup_address_longitude');
                                }

                                if (_addOrderPageModel.pickupAdminArea ==null ||
                                    _addOrderPageModel.pickupCountryCode ==null ||
                                    _addOrderPageModel.parcelPickupAddressLatitude ==null ||
                                    _addOrderPageModel.parcelPickupAddressLongitude ==null) {

                                  Position position = await Geolocator.getCurrentPosition();
                                  LatLng _cameraPos = LatLng(position.latitude, position.longitude);
                                  LatLng _markerPos = _cameraPos;

                                  _addOrderPageModel.parcelPickupAddressLatitude = _markerPos.latitude;
                                  _addOrderPageModel.parcelPickupAddressLongitude = _markerPos.longitude;

                                  if (kIsWeb) {
                                    var addressComponents = await getPlaceViaCoordinates(_markerPos.latitude, _markerPos.longitude, kGoogleApiKey, context);
                                    if (addressComponents !=null) {
                                      _addOrderPageModel.pickupCountryCode = addressComponents.firstWhere((entry) => entry['types'].contains('country'))['short_name'];
                                      _addOrderPageModel.pickupAdminArea =  addressComponents.firstWhere((entry) => entry['types'].contains('administrative_area_level_1'))['long_name'];
                                    }
                                  } else {
                                    var address = await placemarkFromCoordinates(_markerPos.latitude, _markerPos.longitude);
                                    if (address.length > 0) {
                                      _addOrderPageModel.pickupAdminArea = address[0].administrativeArea;
                                      _addOrderPageModel.pickupCountryCode = address[0].isoCountryCode;
                                    }
                                  }

                                }
                                //ასაღები მისამართის კოორდინატები

                                //ჩასაბარებელი მისამართის კოორდინატები
                                if (_addOrderPageModel.toBeDeliveredAdminArea ==null ||
                                    _addOrderPageModel.toBeDeliveredCountryCode ==null ||
                                    _addOrderPageModel.parcelAddressToBeDeliveredLatitude ==null ||
                                    _addOrderPageModel.parcelAddressToBeDeliveredLongitude ==null) {
                                  showAlertDialog(context, AppLocalizations.of(context)!.enter_delivery_address, "");
                                  return;
                                }
                                //ჩასაბარებელი მისამართის კოორდინატები


                                if(_addOrderPageModel.toBeDeliveredAdminArea != _addOrderPageModel.pickupAdminArea ||
                                    _addOrderPageModel.toBeDeliveredCountryCode != _addOrderPageModel.pickupCountryCode) {

                                  var _totalDistance = await getDistanceMatrix(_addOrderPageModel.parcelPickupAddressLatitude!,
                                      _addOrderPageModel.parcelPickupAddressLongitude!, _addOrderPageModel.parcelAddressToBeDeliveredLatitude!,
                                      _addOrderPageModel.parcelAddressToBeDeliveredLongitude!, kGoogleApiKey, context);

                                  _addOrderPageModel.totalDistance = _totalDistance!.elements[0].distance.value /1000;
                                }

                                try {

                                  final res = await geoCourierClient.post(
                                    'orders_sender/get_service_price',
                                    queryParameters: {
                                      "totalDistance": _addOrderPageModel.totalDistance ==null ? "0.0" : _addOrderPageModel.totalDistance.toString(),
                                      "express": _addOrderPageModel.express.toString(),
                                      "pickupAdminArea": _addOrderPageModel.pickupAdminArea,
                                      "pickupCountryCode": _addOrderPageModel.pickupCountryCode,
                                      "toBeDeliveredAdminArea": _addOrderPageModel.toBeDeliveredAdminArea,
                                      "toBeDeliveredCountryCode": _addOrderPageModel.toBeDeliveredCountryCode,
                                      "parcelType": _addOrderPageModel.parcelType == null ? "0" : _addOrderPageModel.parcelType.toString(),
                                    },
                                  );

                                  if(res.statusCode ==200) {
                                    _addOrderPageModel.servicePrice = res.data.toString();
                                  }

                                } catch (e) {
                                  if (e is DioException && e.response?.statusCode == 403) {
                                    reloadApp(context);
                                  } else {
                                    showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
                                  }
                                  return;
                                }

                                if (_addOrderPageModel.servicePrice ==null) {
                                  showAlertDialog(context, AppLocalizations.of(context)!.an_error_occurred, "");
                                  return;
                                }

                                showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(' '),
                                      content: Text(AppLocalizations.of(context)!.tariff + ' - '+ _addOrderPageModel.servicePrice! +'. ' + AppLocalizations.of(context)!.do_you_really_want_to_register_a_parcel),
                                      actions: <Widget>[
                                        OutlinedButton(
                                          child: Text(AppLocalizations.of(context)!.yes),
                                          onPressed: () async {

                                            if(_addOrderPageModel.servicePaymentType ==null) {
                                              showAlertDialog(context, AppLocalizations.of(context)!.specify_the_payment_method, "");
                                              return;
                                            }

                                            //ამანათის ღირებულება
                                            if (_addOrderPageModel.courierHasParcelMoney ==null) {
                                              _addOrderPageModel.courierHasParcelMoney = false;
                                            }

                                            if (_addOrderPageModel.courierHasParcelMoney!) {
                                              if (_addOrderPageModel.serviceParcelPrice ==null) {
                                                _addOrderPageModel.serviceParcelPrice = "";
                                              }
                                              if(_addOrderPageModel.serviceParcelPrice!.isEmpty) {
                                                showAlertDialog(context, AppLocalizations.of(context)!.indicate_the_value_of_the_parcel, "");
                                                return;
                                              }
                                            }
                                            //ამანათის ღირებულება

                                            //ამანათის მაიდენტიფიცირებელი
                                            if (_addOrderPageModel.serviceParcelIdentifiable ==null) {
                                              _addOrderPageModel.serviceParcelIdentifiable = "";
                                            }
                                            if(_addOrderPageModel.serviceParcelIdentifiable!.isEmpty) {
                                              showAlertDialog(context, AppLocalizations.of(context)!.enter_the_parcel_identifier, "");
                                              return;
                                            }
                                            //ამანათის მაიდენტიფიცირებელი

                                            //კლიენტის სახელი
                                            if (_addOrderPageModel.clientName ==null) {
                                              _addOrderPageModel.clientName = "";
                                            }
                                            if(_addOrderPageModel.clientName!.isEmpty) {
                                              showAlertDialog(context, AppLocalizations.of(context)!.enter_client_name, "");
                                              return;
                                            }
                                            //კლიენტის სახელი


                                            //ექსპრეს თარიღების ვალიდაცია
                                            if(_addOrderPageModel.express!
                                                && _addOrderPageModel.serviceDate ==null
                                                && _addOrderPageModel.serviceDateTo ==null
                                                && _addOrderPageModel.serviceDateFrom ==null
                                            ) {
                                              showAlertDialog(context, AppLocalizations.of(context)!.you_do_not_have_a_filled_date_field, "");
                                              return;
                                            }

                                            if(_addOrderPageModel.express! && _addOrderPageModel.serviceDate !=null) {
                                              if (_addOrderPageModel.serviceDate!.isBefore(DateTime.now())) {
                                                showAlertDialog(context, AppLocalizations.of(context)!.enter_the_correct_date_dates, "");
                                                return;
                                              }
                                            }
                                            if(_addOrderPageModel.express! && _addOrderPageModel.serviceDateTo !=null) {
                                              if (_addOrderPageModel.serviceDateTo!.isBefore(DateTime.now())) {
                                                showAlertDialog(context, AppLocalizations.of(context)!.enter_the_correct_date_dates, "");
                                                return;
                                              }
                                            }
                                            if(_addOrderPageModel.express! && _addOrderPageModel.serviceDateFrom !=null) {
                                              if (_addOrderPageModel.serviceDateFrom!.isBefore(DateTime.now())) {
                                                showAlertDialog(context, AppLocalizations.of(context)!.enter_the_correct_date_dates, "");
                                                return;
                                              }
                                            }
                                            //ექსპრეს თარიღების ვალიდაცია

                                            //კლიენტის ტელეფონი ვალიდაცია
                                            if(_addOrderPageModel.viewerPhone ==null || _addOrderPageModel.viewerPhone!.isEmpty) {
                                              showAlertDialog(context, AppLocalizations.of(context)!.enter_the_client_phone_number, "");
                                              return;
                                            }
                                            //კლიენტის ტელეფონი ვალიდაცია

                                            try {

                                              final res = await geoCourierClient.post(
                                                'orders_sender/place_an_order',
                                                queryParameters: _addOrderPageModel.toMap(),
                                              );

                                              final SharedPreferences prefs = await SharedPreferences.getInstance();
                                              String? lastRoute = prefs.getString('last_route');
                                              if(lastRoute ==null) {
                                                return;
                                              }
                                              if (lastRoute.isNotEmpty && lastRoute != '/') {
                                                Navigator.of(context).pushNamed(lastRoute);
                                              }

                                              switch (res.data) {
                                                case "VIP_STATUS_EXPIRED" : showAlertDialog.call(context, AppLocalizations.of(context)!.vip_status_expired, ""); break;
                                                case "MUST_PAY_DEBT" : showAlertDialog.call(context, AppLocalizations.of(context)!.must_pay_debt, ""); break;
                                                default : showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: Text(AppLocalizations.of(context)!.want_place_order),
                                                      content: Text(AppLocalizations.of(context)!.add_order_page_alert,
                                                        style: TextStyle(
                                                            fontSize: 10.0,
                                                            color: Colors.red
                                                        ),
                                                      ),
                                                      actions: <Widget>[
                                                        FloatingActionButton(
                                                          heroTag: "btn2",
                                                          child: Icon(Icons.business_center_outlined),
                                                          onPressed: () {

                                                            showDialog(
                                                                context: context,
                                                                builder: (context) => AlertDialog(
                                                                  title: Text(' '),
                                                                  content: Text(AppLocalizations.of(context)!.hand_over_one_order_to_fav_courier_company_question),
                                                                  actions: <Widget>[
                                                                    OutlinedButton(
                                                                      child: Text(AppLocalizations.of(context)!.yes),
                                                                      onPressed: () async {
                                                                        Navigator.pop(context);
                                                                        Navigator.pop(context);
                                                                        try {
                                                                          await geoCourierClient.post(
                                                                            'orders_sender/hand_over_one_order_to_fav_courier_company',
                                                                            queryParameters: {
                                                                              "orderId": res.data,
                                                                            },
                                                                          );

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
                                                                      onPressed: () {
                                                                        Navigator.pop(context);
                                                                      },
                                                                    )
                                                                  ],
                                                                )
                                                            );
                                                          },
                                                        ),
                                                        FloatingActionButton(
                                                          heroTag: "btn3",
                                                          child: Icon(CustomIcons.courier),
                                                          onPressed: () {

                                                            showDialog(
                                                                context: context,
                                                                builder: (context) => AlertDialog(
                                                                  title: Text(' '),
                                                                  content: Text(AppLocalizations.of(context)!.hand_over_one_order_to_courier),
                                                                  actions: <Widget>[
                                                                    OutlinedButton(
                                                                      child: Text(AppLocalizations.of(context)!.yes),
                                                                      onPressed: () {
                                                                        Navigator.pop(context);
                                                                        Navigator.pop(context);
                                                                        Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(builder: (context) => HandOverParcelToCourierUsersPage(orderId: res.data)),
                                                                        );
                                                                      }, //exit the app
                                                                    ),
                                                                    OutlinedButton(
                                                                      child: Text(AppLocalizations.of(context)!.no),
                                                                      onPressed: () {
                                                                        Navigator.pop(context);
                                                                      },
                                                                    )
                                                                  ],
                                                                )
                                                            );
                                                          },
                                                        ),
                                                        FloatingActionButton(
                                                            heroTag: "btn4",
                                                            child: Text(AppLocalizations.of(context)!.yes, style: TextStyle(color: Colors.white)),
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(builder: (context) => CreateJobPage()),
                                                              );
                                                            }
                                                        ),
                                                        FloatingActionButton(
                                                            heroTag: "btn5",
                                                            child: Text(AppLocalizations.of(context)!.no, style: TextStyle(color: Colors.white)),
                                                            onPressed: () {
                                                              Navigator.pop(context);
                                                            }
                                                        ),
                                                      ],
                                                    )
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
                                        OutlinedButton(
                                          child: Text(AppLocalizations.of(context)!.no),
                                          onPressed: ()=> Navigator.pop(context,false),
                                        )
                                      ],
                                    )
                                );
                              }
                            },
                            child: Icon(Icons.upload_rounded, color: Colors.white,),
                            loader: (timeLeft) {
                              return Text(
                                AppLocalizations.of(context)!.please_wait + " | $timeLeft",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15
                                ),
                              );
                            },
                            borderRadius: 18.0,
                            color: Colors.deepOrange,
                            elevation: 0,
                          )
                        ],
                      ),
                    )
                );
              } else {
                return AnimationControllerClass();
              }
            }
        )
    );
  }


}