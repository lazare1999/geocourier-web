import 'package:flutter/material.dart';
import 'package:geo_couriers/main.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

ListView languageChangeListView(context) {
  return ListView(
    // Important: Remove any padding from the ListView.
    padding: EdgeInsets.zero,
    children: <Widget>[
      ListTile(
        title: Text(
          AppLocalizations.of(context)!.georgian,
          textAlign: TextAlign.center,
        ),
        onTap: () async {
          MyApp.of(context)!.setLocale(Locale.fromSubtags(languageCode: 'ka'));
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString("locale", 'ka');
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: Text(
          AppLocalizations.of(context)!.english,
          textAlign: TextAlign.center,
        ),
        onTap: () async {
          MyApp.of(context)!.setLocale(Locale.fromSubtags(languageCode: 'en'));
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString("locale", 'en');
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: Text(
          AppLocalizations.of(context)!.russian,
          textAlign: TextAlign.center,
        ),
        onTap: () async {
          MyApp.of(context)!.setLocale(Locale.fromSubtags(languageCode: 'ru'));
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString("locale", 'ru');
          Navigator.pop(context);
        },
      )
    ],
  );
}