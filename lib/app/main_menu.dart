import 'package:circular_menu/circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'commons/animation_controller_class.dart';
import 'commons/info/info.dart';
import 'commons/mini_menu/mini_menu.dart';

class MainMenu extends StatefulWidget {
  @override
  _MainMenu createState() => _MainMenu();
}

class _MainMenu extends State<MainMenu> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  bool _isToggled = false;

  Future<bool> _onBackPressed() async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(' '),
        content: Text(AppLocalizations.of(context)!.are_you_sure_want_to_exit),
        actions: <Widget>[
          OutlinedButton(
            child: Text(AppLocalizations.of(context)!.yes),
            onPressed: () async {
              await logout(context);
            }, //exit the app
          ),
          OutlinedButton(
            child: Text(AppLocalizations.of(context)!.no),
            onPressed: ()=> Navigator.pop(context,false),
          )
        ],
      ),
    )) ?? false;
  }

  Future<bool> _mainMenuPageLoad() async {

    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    var _isCourierCompany = _prefs.getBool("is_courier_company");

    if(_isCourierCompany !=null && _isCourierCompany ==true) {
      _isToggled = true;
    } else {
      _isToggled = false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: _mainMenuPageLoad(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return PopScope(
                canPop: true,
                onPopInvoked: (bool didPop) {
                  _onBackPressed();
                },
                child: Scaffold(
                  key: _scaffoldKey,
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
                                    Icon(CustomIcons.buyer, color: Colors.deepOrange),
                                    Flexible(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Text(AppLocalizations.of(context)!.buyer),
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
                                    Icon(CustomIcons.shop, color: Colors.deepOrange),
                                    Flexible(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Text(AppLocalizations.of(context)!.call_to_store),
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
                                    Icon(CustomIcons.courier, color: Colors.deepOrange),
                                    Flexible(
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Text(AppLocalizations.of(context)!.title),
                                        )
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          youtubeLink: "https://www.youtube.com/watch?v=Cb8gQVwByNM"
                      )
                  ),
                  body: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(CustomIcons.buyer, color: Colors.deepOrange),
                              Flexible(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(AppLocalizations.of(context)!.buyer),
                                  )
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(CustomIcons.shop, color: Colors.deepOrange),
                              Flexible(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(AppLocalizations.of(context)!.call_to_store),
                                  )
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: CircularMenu(
                              alignment: Alignment.center,
                              toggleButtonColor: Colors.deepOrange,
                              startingAngleInRadian: 100.0,
                              endingAngleInRadian: 100.0,
                              toggleButtonBoxShadow: [
                                BoxShadow(
                                  color: Colors.white,
                                  blurRadius: 0,
                                ),
                              ],
                              toggleButtonMargin: 50,
                              toggleButtonSize: 90,
                              toggleButtonOnPressed: ()=>setState(() {}),
                              items: [
                                CircularMenuItem(
                                    icon: CustomIcons.buyer,
                                    iconSize: 50,
                                    color: Colors.deepOrange,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white,
                                        blurRadius: 0,
                                      ),
                                    ],
                                    onTap: () {
                                      //მესამე პირი
                                      Navigator.of(context).pushNamed('/buyer');
                                    }),
                                CircularMenuItem(
                                    icon: CustomIcons.fb_messenger,
                                    iconSize: 50,
                                    color: Colors.purple,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white,
                                        blurRadius: 0,
                                      ),
                                    ],
                                    onTap: () {
                                      //მესენჯერი
                                      launchUrl(Uri.parse("http://" +dotenv.env['MESSENGER']!), mode: LaunchMode.externalApplication);
                                    }),
                                CircularMenuItem(
                                    icon: Icons.facebook_outlined,
                                    iconSize: 50,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white,
                                        blurRadius: 0,
                                      ),
                                    ],
                                    color: Colors.blue,
                                    //ჩემი სეისგურგი
                                    onTap: () => launchUrl(Uri.parse('https://www.facebook.com/' + dotenv.env['FACEBOOK']!), mode: LaunchMode.externalNonBrowserApplication)
                                ),
                                CircularMenuItem(
                                    icon: Icons.business_center_outlined,
                                    iconSize: 50,
                                    color: _isToggled ? Colors.deepOrange : Colors.grey,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white,
                                        blurRadius: 0,
                                      ),
                                    ],
                                    onTap: () {
                                      //საკურიერო კომპანია
                                      if (_isToggled) {
                                        Navigator.of(context).pushNamed('/courier_company');
                                      }
                                    }),
                                CircularMenuItem(
                                    icon: CustomIcons.courier,
                                    iconSize: 50,
                                    color: Colors.deepOrange,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white,
                                        blurRadius: 0,
                                      ),
                                    ],
                                    onTap: () {
                                      //კურიერის როლი
                                      Navigator.of(context).pushNamed('/courier');
                                    }),
                                CircularMenuItem(
                                    icon: CustomIcons.shop,
                                    iconSize: 50,
                                    color: Colors.deepOrange,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white,
                                        blurRadius: 0,
                                      ),
                                    ],
                                    onTap: () async {
                                      //ამანათების გამგზავნი
                                      Navigator.of(context).pushNamed('/sender');
                                    }),
                              ]
                          ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(CustomIcons.courier, color: Colors.deepOrange),
                              Flexible(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(AppLocalizations.of(context)!.title),
                                  )
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.business_center_outlined, color: Colors.deepOrange),
                              Flexible(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(AppLocalizations.of(context)!.courier_company),
                                  )
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
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