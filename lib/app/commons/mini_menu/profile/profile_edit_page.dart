import 'dart:async';

import 'package:dio/dio.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/sqflite/models/profile_model.dart';
import 'package:geo_couriers/app/sqflite/services/profile_service.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/app/commons/animation_controller_class.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPage createState() => _ProfileEditPage();
}

class _ProfileEditPage extends State<ProfileEditPage> {
  ProfileModel _pEditModel = ProfileModel();
  ProfileModel _pEditModelOld = ProfileModel();
  ProfileService _profileService = ProfileService();

  Future<bool> updateProfileEdit() async {
    List<ProfileModel> profileDataList = List<ProfileModel>.empty(growable: true);

    if (kIsWeb) {
      try {

        final res = await geoCourierClient.post('miniMenu/get_profile_data');

        if(res.statusCode ==200) {
          var _profileModel = ProfileModel();
          _profileModel.updateProfile(res.data);
          profileDataList.add(_profileModel);
        }
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 403) {
          reloadApp(context);
        } else {
          showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
        }
        return false;
      }
    } else {
      profileDataList = await _profileService.getProfileData();
    }

    var pData0 = profileDataList.isNotEmpty ? profileDataList[0] : ProfileModel();
    _pEditModel.id = pData0.id ==null ? 0 : pData0.id;
    _pEditModel.firstName = pData0.firstName ==null ? "" : pData0.firstName;
    _pEditModel.lastName = pData0.lastName ==null ? "" : pData0.lastName;
    _pEditModel.nickname = pData0.nickname ==null ? "" : pData0.nickname;
    _pEditModel.email = pData0.email ==null ? "" : pData0.email;
    _pEditModel.phoneNumber = pData0.phoneNumber ==null ? "" : pData0.phoneNumber;
    _pEditModel.rating = pData0.rating ==null ? "" : pData0.rating;

    _pEditModelOld.firstName = pData0.firstName;
    _pEditModelOld.lastName = pData0.lastName;
    _pEditModelOld.nickname = pData0.nickname;
    _pEditModelOld.email = pData0.email;
    _pEditModelOld.phoneNumber = pData0.phoneNumber;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: updateProfileEdit(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.edit),
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
                      child: Icon(Icons.upload_rounded),
                      onPressed: () async {

                        if (
                            _pEditModelOld.firstName == _pEditModel.firstName &&
                            _pEditModelOld.lastName == _pEditModel.lastName &&
                            _pEditModelOld.nickname == _pEditModel.nickname &&
                            _pEditModelOld.email == _pEditModel.email
                        ) {
                          showAlertDialog(context, AppLocalizations.of(context)!.same_data, "");
                          return;
                        }

                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(' '),
                              content: Text(AppLocalizations.of(context)!.are_you_sure_want_to_edit),
                              actions: <Widget>[
                                OutlinedButton(
                                  child: Text(AppLocalizations.of(context)!.yes),
                                  onPressed: () async {
                                    if(_pEditModel.email !=null && !EmailValidator.validate(_pEditModel.email!)) {
                                      showAlertDialog(context, AppLocalizations.of(context)!.mail_incorrect, "");
                                      return;
                                    }

                                    try {

                                      final res = await geoCourierClient.post(
                                          'miniMenu/update_profile',
                                          queryParameters: _pEditModel.toMap()
                                      );


                                      if(res.statusCode !=200) {
                                        showAlertDialog(context, AppLocalizations.of(context)!.could_not_edit, "");
                                        return;
                                      }

                                      if (!kIsWeb) {
                                        await _profileService.deleteAll();
                                        await _profileService.insert(_pEditModel);
                                      }

                                      final SharedPreferences prefs = await SharedPreferences.getInstance();
                                      String? lastRoute = prefs.getString('last_route');
                                      if(lastRoute ==null) {
                                        return;
                                      }
                                      if (lastRoute.isNotEmpty && lastRoute != '/') {
                                        Navigator.of(context).pushNamed(lastRoute);
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
                      },
                    ),
                  ],
                ),
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
                                decoration: InputDecoration(
                                  filled: true,
                                  labelText: AppLocalizations.of(context)!.company_name,
                                ),
                                initialValue: _pEditModel.nickname,
                                onChanged: (value) {
                                  _pEditModel.nickname = value;
                                },
                              ),
                              TextFormField(
                                decoration: InputDecoration(
                                  filled: true,
                                  labelText: AppLocalizations.of(context)!.name,
                                ),
                                initialValue: _pEditModel.firstName,
                                onChanged: (value) {
                                  _pEditModel.firstName = value;
                                },
                              ),
                              TextFormField(
                                decoration: InputDecoration(
                                  filled: true,
                                  labelText: AppLocalizations.of(context)!.last_name,
                                ),
                                initialValue: _pEditModel.lastName,
                                onChanged: (value) {
                                  _pEditModel.lastName = value;
                                },
                              ),
                              TextFormField(
                                decoration: InputDecoration(
                                  filled: true,
                                  labelText: AppLocalizations.of(context)!.mail,
                                ),
                                initialValue: _pEditModel.email,
                                onChanged: (value) {
                                  _pEditModel.email = value;
                                },
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
              )
            );
          } else {
            return AnimationControllerClass();
          }
        }
    );
  }


}