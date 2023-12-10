import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:flutter/services.dart';
import 'package:geo_couriers/app/authenticate/login/login_page.dart';
import 'package:geo_couriers/app/authenticate/register/privacy_and_policy/terms_of_use.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

part 'register_page.g.dart';


@JsonSerializable()
class FormData {
  String? firstName;
  String? lastName;
  String? nickname;
  String? phoneNumber;
  String? password;

  FormData({
    this.firstName,
    this.lastName,
    this.nickname,
    this.phoneNumber,
    this.password,
  });

  factory FormData.fromJson(Map<String, dynamic> json) =>
      _$FormDataFromJson(json);

  Map<String, dynamic> toJson() => _$FormDataToJson(this);
}


class RegisterPage extends StatefulWidget {

  @override
  _RegisterPage createState() => _RegisterPage();
}

class _RegisterPage extends State<RegisterPage> {

  FormData formData = FormData();
  var _countryPhoneCode = "+995";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.register),
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
                      TextFormField(
                          style: TextStyle(
                              fontWeight: FontWeight.bold
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            labelText: AppLocalizations.of(context)!.name,
                          ),
                          onChanged: (value) {
                            formData.firstName = value;
                          }
                      ),
                      TextFormField(
                          style: TextStyle(
                              fontWeight: FontWeight.bold
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            labelText: AppLocalizations.of(context)!.last_name,
                          ),
                          onChanged: (value) {
                            formData.lastName = value;
                          }
                      ),
                      TextFormField(
                          style: TextStyle(
                              fontWeight: FontWeight.bold
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            labelText: AppLocalizations.of(context)!.company_name,
                          ),
                          onChanged: (value) {
                            formData.nickname = value;
                          }
                      ),
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
                              decoration: InputDecoration(
                                filled: true,
                                labelText: AppLocalizations.of(context)!.code,
                              ),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold
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
                                    await generateTemporaryCodeForRegister(context, formData.phoneNumber);
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

                            if (data.firstName == null) {data.firstName = "";}
                            if (data.lastName == null) {data.lastName = "";}
                            if (data.nickname == null) {data.nickname = "";}
                            if (data.phoneNumber == null) {data.phoneNumber = "";}
                            if (data.password == null) {data.password = "";}

                            if (data.nickname =="" && (data.firstName =="" || data.lastName =="")) {
                              showAlertDialog.call(context, AppLocalizations.of(context)!.fill_fields_register_page, AppLocalizations.of(context)!.notification);
                              return;
                            }

                            if (data.phoneNumber!.isEmpty || data.password!.isEmpty) {
                              showAlertDialog.call(context, AppLocalizations.of(context)!.enter_data, AppLocalizations.of(context)!.notification);
                            } else if (data.phoneNumber!.isNotEmpty && data.password!.isNotEmpty) {
                              var result = await register(context, formData.phoneNumber, formData.firstName, formData.lastName, formData.nickname, formData.password);

                              switch (result) {
                                case "temporary_code_empty" : showAlertDialog.call(context, AppLocalizations.of(context)!.temporary_code_empty, ""); break;
                                case "phone_number_empty" : showAlertDialog.call(context, AppLocalizations.of(context)!.phone_number_empty, ""); break;
                                case "temporary_code_not_exists" : showAlertDialog.call(context, AppLocalizations.of(context)!.temporary_code_not_exists, ""); break;
                                case "user_already_defined" : showAlertDialog.call(context, AppLocalizations.of(context)!.user_already_defined, ""); break;
                                case "temporary_code_incorrect" : showAlertDialog.call(context, AppLocalizations.of(context)!.temporary_code_incorrect, ""); break;
                                case "fill_blanks" : showAlertDialog.call(context, AppLocalizations.of(context)!.fill_fields_register_page, ""); break;
                                case "success" : Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => LoginPage()),
                                );
                                showToast(context, new Duration(seconds: 5), AppLocalizations.of(context)!.registration_was_successful); break;
                                default : showAlertDialog.call(context, AppLocalizations.of(context)!.an_error_occurred, "");
                              }

                            }
                          }
                        },
                        child: Text(
                          AppLocalizations.of(context)!.register,
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
                      TermsOfUse(),
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
      )
    );
  }
}

