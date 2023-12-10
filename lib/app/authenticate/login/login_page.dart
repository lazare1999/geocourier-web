import 'dart:io';

import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:country_code_picker/country_code_picker.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../main.dart';
import '../register/register_page.dart';

part 'login_page.g.dart';


@JsonSerializable()
class FormData {
  String? phoneNumber;
  String? password;

  FormData({
    this.phoneNumber,
    this.password,
  });

  factory FormData.fromJson(Map<String, dynamic> json) =>
      _$FormDataFromJson(json);

  Map<String, dynamic> toJson() => _$FormDataToJson(this);
}


class LoginPage extends StatefulWidget {
  @override
  _LoginPage createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {

  @override
  void initState() {
    navigateToLastPage(context);
    super.initState();
    _updateLocale();
    _checkPermission();
  }

  Future<Null> _updateLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.get("locale") !=null) {
      MyApp.of(context)!.setLocale(Locale.fromSubtags(languageCode: prefs.get("locale") as String));
    }
  }

  Future<Null> _checkPermission() async {
    if (await Permission.location.request().isPermanentlyDenied) {
      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(' '),
            content: Text(AppLocalizations.of(context)!.you_declined_to_share_a_location),
            actions: <Widget>[
              OutlinedButton(
                  child: Text(AppLocalizations.of(context)!.okay),
                  onPressed: ()=> exit(0)
              )
            ],
          )
      );
    }
  }

  FormData formData = FormData();
  var _countryPhoneCode = "+995";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.login),
      ),
      floatingActionButton: FabCircularMenu(
          ringDiameter: kIsWeb ? MediaQuery.of(context).size.width * 0.3 : MediaQuery.of(context).size.width,
          fabOpenIcon: Icon(Icons.language, color: Colors.black,),
          fabColor: Colors.white,
          children: <Widget>[
            IconButton(icon: Image.asset('assets/images/flags/ge.png', width: 30, height: 30,), onPressed: () async {
              MyApp.of(context)!.setLocale(Locale.fromSubtags(languageCode: 'ka'));
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString("locale", 'ka');
            }),
            IconButton(icon: Image.asset('assets/images/flags/gb.png', width: 30, height: 30,), onPressed: () async {
              MyApp.of(context)!.setLocale(Locale.fromSubtags(languageCode: 'en'));
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString("locale", 'en');
            }),
            IconButton(icon: Image.asset('assets/images/flags/rus.png', width: 30, height: 30,), onPressed: () async {
              MyApp.of(context)!.setLocale(Locale.fromSubtags(languageCode: 'ru'));
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString("locale", 'ru');
            })
          ]
        ),
      body: Center(
        child: Container(
          alignment: Alignment.topCenter,
          width: kIsWeb ? MediaQuery.of(context).size.shortestSide * 0.85 : MediaQuery.of(context).size.width,
          child: Form(
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: CountryCodePicker(
                              onChanged: (value) {
                                formData.phoneNumber = formData.phoneNumber!.substring(_countryPhoneCode.length);
                                _countryPhoneCode = value.dialCode!;
                                formData.phoneNumber = _countryPhoneCode + formData.phoneNumber!;
                              },
                              initialSelection: 'GE',
                              showCountryOnly: false,
                              showOnlyCountryWhenClosed: false,
                              alignLeft: false,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              style: TextStyle(
                                  fontWeight: FontWeight.bold
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                labelText: AppLocalizations.of(context)!.phone,
                              ),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                formData.phoneNumber = _countryPhoneCode + value;
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              style: TextStyle(
                                  fontWeight: FontWeight.bold
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                labelText: AppLocalizations.of(context)!.code,
                              ),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                formData.password = value;
                              },
                            ),
                          ),
                          const SizedBox(width: 5,),
                          Expanded(
                            child: ArgonTimerButton(
                              height: 50,
                              width: MediaQuery.of(context).size.width * 0.30,
                              minWidth: MediaQuery.of(context).size.width * 0.20,
                              highlightColor: Colors.transparent,
                              highlightElevation: 0,
                              roundLoadingShape: false,
                              onTap: (startTimer, btnState) async {
                                formData.phoneNumber ??= "";
                                if (formData.phoneNumber!.isEmpty) {
                                  showAlertDialog.call(context, AppLocalizations.of(context)!.enter_mobile_number, AppLocalizations.of(context)!.notification);
                                } else {
                                  if (btnState == ButtonState.Idle) {
                                    startTimer(20);
                                    await generateTemporaryCodeForLogin(context, formData.phoneNumber);
                                  }
                                }
                              },
                              child: Text(
                                AppLocalizations.of(context)!.get_code,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15
                                ),
                              ),
                              loader: (timeLeft) {
                                return Text(
                                  AppLocalizations.of(context)!.please_wait + " | $timeLeft",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15
                                  ),
                                );
                              },
                              borderRadius: 18.0,
                              color: Colors.deepOrange,
                              elevation: 0,
                            ),
                          )
                        ],
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
                            var data =formData;

                            if (data.phoneNumber == null) {data.phoneNumber = "";}
                            if (data.password == null) {data.password = "";}

                            if (data.phoneNumber!.isEmpty || data.password!.isEmpty) {
                              showAlertDialog.call(context, AppLocalizations.of(context)!.enter_data, AppLocalizations.of(context)!.notification);
                            } else if (data.phoneNumber!.isNotEmpty && data.password!.isNotEmpty) {
                              var result = await authenticate(context, formData.phoneNumber, formData.password);

                              if (result) {
                                Navigator.of(context).pushNamed('/main_menu');
                                showToast(context, new Duration(seconds: 5), AppLocalizations.of(context)!.instruction);
                              } else {
                                showAlertDialog.call(context, AppLocalizations.of(context)!.enter_the_correct_data, "");
                              }
                            }
                          }
                        },
                        child: Text(
                          AppLocalizations.of(context)!.login,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15
                          ),
                        ),
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
                      ),
                      MaterialButton(
                        child: Text(
                          AppLocalizations.of(context)!.register,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 20, decoration: TextDecoration.underline,),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterPage()),
                          );
                        },
                      )
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
      ),
    );
  }
}

