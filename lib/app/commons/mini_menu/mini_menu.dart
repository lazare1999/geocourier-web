import 'package:accordion/accordion.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/commons/mini_menu/contact_us/contact_page.dart';
import 'package:geo_couriers/app/commons/mini_menu/my_account/account_page.dart';
import 'package:geo_couriers/app/commons/mini_menu/profile/profile_page.dart';
import 'package:geo_couriers/app/commons/mini_menu/users_info/all_users_page.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../globals.dart';
import '../../../main.dart';
import 'notifications/notification_page.dart';

class MiniMenu extends StatelessWidget {

  Widget _createFooterItem({IconData? icon, required String text, GestureTapCallback? onTap, required context}){
    return ListTile(
      title: Row(
        children: <Widget>[
          Icon(icon, color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black),
          Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(" "+text, style: TextStyle(fontWeight: FontWeight.bold),),
          )
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyApp.of(context)!.isDarkModeEnabled ? Color(0xFF15202B) : Colors.white,
      body: ListView(
        padding: EdgeInsets.only(left: 1.0, right: 8.0, top: 20.0, bottom: 0.0),
        children: <Widget>[
          _createFooterItem(
              icon: Icons.account_balance,
              text: AppLocalizations.of(context)!.my_account,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountPage()),
                );
              }, context: context),
          _createFooterItem(
              icon: Icons.account_box,
              text: AppLocalizations.of(context)!.profile,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              }, context: context),
          _createFooterItem(
              icon: Icons.people,
              text: AppLocalizations.of(context)!.users,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AllUsersPage()),
                );
              }, context: context),
          _createFooterItem(
              icon: Icons.notifications,
              text: AppLocalizations.of(context)!.notification,
              onTap: () async {

                try {

                  final r = await geoCourierClient.post('get_current_user_id');

                  List _topics = [];

                  _topics.clear();
                  _topics.add(r.data.toString());

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationPage(topics: _topics,)),
                  );

                } catch (e) {
                  if (e is DioException && e.response?.statusCode == 403) {
                    reloadApp(context);
                  }
                  return;
                }


              }, context: context),
          _createFooterItem(
              icon: MyApp.of(context)!.isDarkModeEnabled ? Icons.light_mode : Icons.dark_mode,
              text: MyApp.of(context)!.isDarkModeEnabled ? AppLocalizations.of(context)!.light_mode : AppLocalizations.of(context)!.dark_mode,
              onTap: () {
                MyApp.of(context)!.onStateChanged(!MyApp.of(context)!.isDarkModeEnabled);
              }, context: context),
          Accordion(
            paddingListHorizontal: 1,
            paddingListTop: 5,
            children: [
              AccordionSection(
                  leftIcon: const Icon(Icons.language),
                  headerBackgroundColor: MyApp.of(context)!.isDarkModeEnabled ? Color(0xFF15202B) : Colors.white,
                  headerBackgroundColorOpened: Colors.deepOrange,
                  header: Text(AppLocalizations.of(context)!.language, style: TextStyle(fontWeight: FontWeight.bold),),
                  content: Wrap(
                    // runSpacing: 20.0,
                    children: [
                      IconButton(icon: Image.asset('assets/images/flags/gb.png', width: 100, height: 100,), onPressed: () async {
                        MyApp.of(context)!.setLocale(Locale.fromSubtags(languageCode: 'en'));
                        final SharedPreferences prefs = await SharedPreferences.getInstance();
                        prefs.setString("locale", 'en');
                      }),
                      IconButton(icon: Image.asset('assets/images/flags/rus.png', width: 100, height: 100,), onPressed: () async {
                        MyApp.of(context)!.setLocale(Locale.fromSubtags(languageCode: 'ru'));
                        final SharedPreferences prefs = await SharedPreferences.getInstance();
                        prefs.setString("locale", 'ru');
                      }),
                      IconButton(icon: Image.asset('assets/images/flags/ge.png', width: 100, height: 100,), onPressed: () async {
                        MyApp.of(context)!.setLocale(Locale.fromSubtags(languageCode: 'ka'));
                        final SharedPreferences prefs = await SharedPreferences.getInstance();
                        prefs.setString("locale", 'ka');
                      }),
                    ],
                  )
              ),
            ],
          ), // Add this to force the bottom items to the lowest point
        ],
      ),
      persistentFooterButtons: [
        Column(
          children: <Widget>[
            _createFooterItem(
                icon: CustomIcons.fb_messenger,
                text: AppLocalizations.of(context)!.message_us,
                onTap: () {
                  launchUrl(Uri.parse("http://" +dotenv.env['MESSENGER']!), mode: LaunchMode.externalApplication);
                }, context: context),
            _createFooterItem(
                icon: Icons.email,
                text: AppLocalizations.of(context)!.contact,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContactPage()),
                  );
                }, context: context),
            _createFooterItem(
                icon: Icons.arrow_back,
                text: AppLocalizations.of(context)!.choose_role,
                onTap: () {
                  Navigator.of(context).pushNamed('/main_menu');
                }, context: context),
            _createFooterItem(
                icon: Icons.logout,
                text: AppLocalizations.of(context)!.exit,
                onTap: () async {
                  showDialog(
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
                      )
                  );
                }, context: context),
          ],
        ),
      ]
    );

  }

}