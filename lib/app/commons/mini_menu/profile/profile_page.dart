import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/commons/mini_menu/profile/profile_edit_page.dart';
import 'package:geo_couriers/app/commons/mini_menu/profile/choose_fav_courier_company_users_page.dart';
import 'package:geo_couriers/app/sqflite/models/profile_model.dart';
import 'package:geo_couriers/app/sqflite/services/profile_service.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/app/commons/animation_controller_class.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:geo_couriers/app/commons/star_rating.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../main.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePage createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> {
  ProfileModel _pModel = ProfileModel();
  ProfileService _profileService = ProfileService();
  var firstLastName = "";

  bool _isToggled = false;
  bool _userHasFavCourierCompany = false;

  //სერვერიდან მოაქვს user-ის მონაცემები
  Future<void> _updateProfileModelFromServer() async {

    try {

      final res = await geoCourierClient.post('miniMenu/get_profile_data');

      if(res.statusCode ==200) {
        var _profileModel = ProfileModel();
        _profileModel.updateProfile(res.data);

        if (!kIsWeb) {
          await _profileService.deleteAll();
          await _profileService.insert(_profileModel);
          var profileData = await _profileService.getProfileData();
          await _setProfileModel(profileData);
        } else {
          List<ProfileModel> newData = List<ProfileModel>.empty(growable: true);
          newData.add(_profileModel);
          await _setProfileModel(newData);
        }
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        reloadApp(context);
      } else {
        showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
      }
      return;
    }
  }

  //სერვერიდან მოაქვს user-ის შეფასება
  Future<void> _updateRatingFromServer() async {
    try {

      final res = await geoCourierClient.post('miniMenu/get_rating');

      if(res.statusCode ==200) {
        if (res.data == null) {
          return;
        }
        _pModel.rating = res.data.toString();
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        reloadApp(context);
      } else {
        showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
      }
      return;
    }
  }

  //ჩასეტავს მონაცემებს pModel-ში
  Future<void> _setProfileModel(List<ProfileModel> pData) async {
    var pData0 = pData.isNotEmpty ? pData[0] : ProfileModel();
    _pModel.firstName = pData0.firstName;
    _pModel.lastName = pData0.lastName;
    _pModel.nickname = pData0.nickname;
    _pModel.email = pData0.email;
    _pModel.phoneNumber = pData0.phoneNumber;
    _pModel.rating = pData0.rating;
    firstLastName = (_pModel.firstName ==null ? "" : _pModel.firstName)! + " " + (_pModel.lastName ==null ? "" : _pModel.lastName!);
  }


  //სერვერიდან მოაქვს ფავორიტი საკურიერო კომპანია
  Future<void> _favCourierCompanyIdFromServer() async {
    try {

      final res = await geoCourierClient.post('miniMenu/get_fav_courier_company_id');

      if (res.data == null || res.data =="") {
        return;
      }
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      _prefs.setInt("fav_courier_company_id", res.data);
      _userHasFavCourierCompany = true;

    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        reloadApp(context);
      } else {
        showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
      }
      return;
    }
  }

  Future<bool> _updateProfile() async {
    List<ProfileModel>? profileDataList;

    if (!kIsWeb) {
      profileDataList = await _profileService.getProfileData();
    }

    if(profileDataList == null || profileDataList.isEmpty) {
      await _updateProfileModelFromServer();
    } else {
      await _updateRatingFromServer();
      await _setProfileModel(profileDataList);
    }


    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    var _isCourierCompany = _prefs.getBool("is_courier_company");
    if(_isCourierCompany != null) {
      _isToggled = _isCourierCompany;
    }

    var _favCourierCompanyId = _prefs.getInt("fav_courier_company_id");
    if(_favCourierCompanyId == null) {
      await _favCourierCompanyIdFromServer();
    } else {
      _userHasFavCourierCompany = true;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: _updateProfile(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.profile),
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
                      child: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfileEditPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // backgroundColor: Colors.white70,
              body: Center(
                child: Container(
                  alignment: Alignment.topCenter,
                  width: kIsWeb ? MediaQuery.of(context).size.shortestSide * 0.85 : MediaQuery.of(context).size.width,
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            height: 20.0,
                          ),
                          generateCard(
                              Container(
                                child: Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: TextFormField(
                                      readOnly: true,
                                      initialValue: _pModel.nickname,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context)!.company_name,
                                      ),
                                    )
                                ),
                              ), 10.0
                          ),
                          generateCard(
                              Container(
                                child: Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: TextFormField(
                                      readOnly: true,
                                      initialValue: firstLastName,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context)!.full_name,
                                      ),
                                    )
                                ),
                              ), 10.0
                          ),
                          generateCard(
                              Container(
                                child: Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: TextFormField(
                                      readOnly: true,
                                      initialValue: _pModel.email,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(hintText: AppLocalizations.of(context)!.mail),
                                    )
                                ),
                              ), 10.0
                          ),
                          generateCard(
                              Container(
                                child: Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: TextFormField(
                                      readOnly: true,
                                      initialValue: _pModel.phoneNumber,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(hintText: AppLocalizations.of(context)!.tel_number),
                                    )
                                ),
                              ), 10.0
                          ),
                          generateCard(ListTile(
                            title: Text(
                                AppLocalizations.of(context)!.choose_partner_courier_company,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _userHasFavCourierCompany ? Colors.deepOrange : MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                                )
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ChooseFavCourierCompanyUsersPage()),
                              );
                            } ,
                          ), 10.0),
                          generateCard(ListTile(
                            title: Text(
                                AppLocalizations.of(context)!.courier_company,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isToggled ? Colors.green : MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                                )
                            ),
                            onTap: () async {
                              final SharedPreferences _prefs = await SharedPreferences.getInstance();
                              if(_prefs.getBool("is_courier_company") != null) {
                                _prefs.remove("is_courier_company");
                              }
                              _prefs.setBool("is_courier_company", !_isToggled);

                              setState(() {
                                _isToggled = !_isToggled;
                              });

                            } ,
                          ), 10.0),
                          generateCard(ListTile(
                            title: StarRating(rating: _pModel.rating !=null ? double.parse(_pModel.rating!) : 0),
                            onTap: () {
                              showAlertDialog(context, AppLocalizations.of(context)!.my_rating, "");
                            } ,
                          ), 10.0),
                        ],
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