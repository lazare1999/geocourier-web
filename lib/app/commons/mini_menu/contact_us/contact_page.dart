import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/commons/mini_menu/contact_us/contactus.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../main.dart';

class ContactPage extends StatefulWidget {
  @override
  _ContactPage createState() => _ContactPage();
}

class _ContactPage extends State<ContactPage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.contact),
      ),
      // backgroundColor: Colors.white70,
      body: Center(
        child: Container(
          alignment: Alignment.topCenter,
          width: kIsWeb ? MediaQuery.of(context).size.shortestSide * 0.85 : MediaQuery.of(context).size.width,
          child: ContactUs(
            // cardColor: Colors.transparent,
            email: dotenv.env['EMAIL']!,
            companyName: "",
            companyColor: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
            phoneNumber: dotenv.env['PHONE_NUMBER']!,
            facebookHandle: dotenv.env['FACEBOOK']!,
            message: dotenv.env['MESSENGER']!,
          ),
        ),
      )
    );
  }

}