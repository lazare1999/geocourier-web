library my_prj.authenticate_utils;

import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/authenticate/models/authentication_response.dart';
import 'package:geo_couriers/app/sqflite/services/profile_service.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../main.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

AuthenticationResponse auth = AuthenticationResponse();
var _profileService = ProfileService();

//ტოკენის მოპოვება
Future<String?> getJwtViaRefreshToken() async {
  try {
    final res = await defaultDio.post(
      dotenv.env['GEO_COURIERS_API_BASE_URL']! + 'jwt_via_refresh_token',
      queryParameters: {
        "refreshToken": auth.refreshToken,
      },
    );

    if(res.statusCode !=200) {
      return null;
    }

    await updateRefreshTokenLocal(res.data);
    return res.data["jwt"];
  } catch (e) {
    return null;
  }
}

Future<String?> getJwtViaRefreshTokenFromSharedRefs() async {

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  var refreshToken = prefs.get("refresh_token");
  int? refreshTokenExpiresIn = prefs.get("refresh_token_expires_in") as int?;

  if (refreshToken ==null || refreshTokenExpiresIn ==null) {
    return null;
  }

  var expiresAt = DateTime.fromMillisecondsSinceEpoch(refreshTokenExpiresIn);
  if (DateTime.now().isAfter(expiresAt)) {
    return null;
  }

  try {
    final res = await defaultDio.post(
      dotenv.env['GEO_COURIERS_API_BASE_URL']! + 'jwt_via_refresh_token',
      queryParameters: {
        "refreshToken": refreshToken,
      },
    );

    if(res.statusCode !=200) {
      return null;
    }

    await updateRefreshTokenLocal(res.data);
    return res.data["jwt"];
  } catch (e) {
    return null;
  }
}

Future<String?> getAccessToken() async {

  if (auth.jwt !=null && DateTime.now().isBefore(auth.expiresAt!)) {
    return auth.jwt;
  }

  if (auth.refreshToken !=null && DateTime.now().isBefore(auth.refreshExpiresAt!)) {
    return await getJwtViaRefreshToken();
  }

  return await getJwtViaRefreshTokenFromSharedRefs();
}
//ტოკენის მოპოვება

//ავტორიზაცია
Future<bool> authenticate(context, String? username, String? password) async {

  if (username ==null || password ==null) {
    return false;
  }

  try {

    final res = await defaultDio.post(
      dotenv.env['GEO_COURIERS_API_BASE_URL']! + 'authenticate',
      queryParameters: {
        "username": username,
        "password": password,
      },
    );

    if(res.statusCode ==200) {
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      _prefs.setString("phone", username);
      await updateRefreshTokenLocal(res.data);
      return true;
    }

  } catch (e) {
    return false;
  }

  return false;
}

Future<void> updateRefreshTokenLocal(res) async {
  auth.update(res);

  final SharedPreferences _prefs = await SharedPreferences.getInstance();
  _prefs.setString("refresh_token", auth.refreshToken!);
  _prefs.setInt("refresh_token_expires_in", auth.refreshExpiresIn!);

}
//ავტორიზაცია

//რეგისტრაცია
Future<String> register(context, String? phoneNumber, String? firstName, String? lastName, String? nickname, String? code) async {
  try {

    final res = await defaultDio.post(
      dotenv.env['GEO_COURIERS_API_BASE_URL']! + 'register',
      queryParameters: {
        "phoneNumber": phoneNumber,
        "firstName": firstName,
        "lastName": lastName,
        "nickname": nickname,
        "code": code,
      },
    );

    return res.data;
  } catch (e) {
    return e.toString();
  }
}

//დროებითი კოდები
Future<void> generateTemporaryCodeForLogin(context, String? username) async {
  try {

    await defaultDio.post(
      dotenv.env['GEO_COURIERS_API_BASE_URL']! + 'generate_temp_code_for_login',
      queryParameters: {
        "username": username,
      },
    );

  } catch (e) {
    showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
  }
}

Future<void> generateTemporaryCodeForRegister(context, String? username) async {
  try {

    await defaultDio.post(
      dotenv.env['GEO_COURIERS_API_BASE_URL']! + 'generate_temp_code_for_register',
      queryParameters: {
        "username": username,
      },
    );

  } catch (e) {
    showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
  }
}
//დროებითი კოდები


Future<void> _restart(context) async {
  final SharedPreferences _prefs = await SharedPreferences.getInstance();
  _prefs.clear();

  if (!kIsWeb) {
    await _profileService.deleteAll();
  }

  RestartWidget.restartApp(context);
}

Future<void> logout(context) async {

  try {

    await geoCourierClient.post('logout_from_system');

    await _restart(context);
  } catch (e) {
    if (e is DioException && e.response?.statusCode == 403) {
      await _restart(context);
    }
    return;
  }
}

Future<void> reloadApp(context) async {

  final SharedPreferences _prefs = await SharedPreferences.getInstance();
  var _phone = _prefs.getString("phone");
  var _password;

  if (_phone == null || _phone.isEmpty) {
    await _restart(context);
    return;
  }

  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.session_time_expired),
        content: Container(
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
                            child: TextFormField(
                              decoration: InputDecoration(
                                filled: true,
                                labelText: AppLocalizations.of(context)!.code,
                              ),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _password = value;
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
                                _phone ??= "";
                                if (_phone!.isEmpty) {
                                  showAlertDialog.call(context, AppLocalizations.of(context)!.enter_mobile_number, AppLocalizations.of(context)!.notification);
                                } else {
                                  if (btnState == ButtonState.Idle) {
                                    startTimer(20);
                                    await generateTemporaryCodeForLogin(context, _phone);
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
        actions: <Widget>[
          OutlinedButton(
            child: Text(AppLocalizations.of(context)!.re_login),
            onPressed: () async {
              if(!await authenticate(context, _phone, _password)) {
                await reloadApp(context);
              } else {
                navigateToLastPage(context);
                showToast(context, new Duration(seconds: 5), AppLocalizations.of(context)!.instruction_pointer);
              }
              Navigator.pop(context,false);
            }, //exit the app
          ),
          OutlinedButton(
            child: Text(AppLocalizations.of(context)!.exit),
            onPressed: () async {
              await _restart(context);
            },
          )
        ],
      )
  );

}
