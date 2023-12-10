library contactus;

import 'package:flutter/material.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

///Class for adding contact details/profile details as a complete new page in your flutter app.
class ContactUs extends StatelessWidget {
  ///Logo of the Company/individual
  final ImageProvider? logo;

  ///Ability to add an image
  final Image? image;

  ///Phone Number of the company/individual
  final String? phoneNumber;

  ///Text for Phonenumber
  final String? phoneNumberText;

  ///Website of company/individual
  final String? website;

  ///Text for Website
  final String? websiteText;

  ///Email ID of company/individual
  final String? email;

  ///Text for Email
  final String? emailText;

  ///Facebook Handle of Company/Individual
  final String? facebookHandle;

  ///messenger Handle of Company/Individual
  final String? message;

  ///Name of the Company/individual
  final String? companyName;

  ///Font size of Company name
  final double? companyFontSize;

  ///TagLine of the Company or Position of the individual
  final String? tagLine;

  ///TextColor of the text which will be displayed on the card.
  final Color? textColor;

  ///Color of the Card.
  final Color? cardColor;

  ///Color of the company/individual name displayed.
  final Color? companyColor;

  ///Color of the tagLine of the Company/Individual to be displayed.
  final Color? taglineColor;

  ///Constructor which sets all the values.
  ContactUs(
      {
        this.companyName,
        this.textColor,
        this.cardColor,
        this.companyColor,
        this.taglineColor,
        this.email,
        this.emailText,
        this.logo,
        this.image,
        this.phoneNumber,
        this.phoneNumberText,
        this.website,
        this.websiteText,
        this.facebookHandle,
        this.message,
        this.tagLine,
        this.companyFontSize
      });

  showAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          elevation: 8.0,
          contentPadding: EdgeInsets.all(18.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
          content: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => launchUrl(Uri.parse('tel:' + phoneNumber!), mode: LaunchMode.externalApplication),
                  child: Container(
                    height: 50.0,
                    alignment: Alignment.center,
                    child: Text(AppLocalizations.of(context)!.call),
                  ),
                ),
                Divider(),
                InkWell(
                  onTap: () => launchUrl(Uri.parse('sms:' + phoneNumber!), mode: LaunchMode.externalApplication),
                  child: Container(
                    alignment: Alignment.center,
                    height: 50.0,
                    child: Text(AppLocalizations.of(context)!.message),
                  ),
                ),
                Divider(),
                InkWell(
                  onTap: () => launchUrl(Uri.parse('https://wa.me/' + phoneNumber!), mode: LaunchMode.externalApplication),
                  child: Container(
                    alignment: Alignment.center,
                    height: 50.0,
                    child: Text('WhatsApp'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Visibility(
              visible: logo != null,
              child: CircleAvatar(
                radius: 50.0,
                backgroundImage: logo,
              ),
            ),
            Visibility(
                visible: image != null, child: image ?? SizedBox.shrink()),
            Text(
              companyName!,
              style: TextStyle(
                fontFamily: 'Pacifico',
                fontSize: companyFontSize ?? 30.0,
                color: companyColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Visibility(
              visible: tagLine != null,
              child: Text(
                tagLine ?? "",
                style: TextStyle(
                  color: taglineColor,
                  fontSize: 20.0,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            SizedBox(
              height: 10.0,
            ),
            Visibility(
              visible: website != null,
              child: Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 25.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
                color: cardColor,
                child: ListTile(
                  leading: Icon(Icons.link),
                  title: Text(
                    websiteText ?? AppLocalizations.of(context)!.website,
                    style: TextStyle(
                      color: textColor,
                    ),
                  ),
                  onTap: () => launchUrl(Uri.parse(website!)),
                ),
              ),
            ),
            Visibility(
              visible: facebookHandle != null,
              child: Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 25.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
                color: cardColor,
                child: ListTile(
                  leading: Icon(Icons.facebook_outlined),
                  title: Text(
                    'Facebook',
                    style: TextStyle(
                      color: textColor,
                    ),
                  ),
                  onTap: () => launchUrl(Uri.parse('https://www.facebook.com/' + facebookHandle!), mode: LaunchMode.externalApplication),
                ),
              ),
            ),
            Visibility(
              visible: message != null,
              child: Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 25.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
                color: cardColor,
                child: ListTile(
                  leading: Icon(CustomIcons.fb_messenger),
                  title: Text(
                    'message us',
                    style: TextStyle(
                      color: textColor,
                    ),
                  ),
                  onTap: () => launchUrl(Uri.parse("http://" + message!), mode: LaunchMode.externalApplication),
                ),
              ),
            ),
            Visibility(
              visible: phoneNumber != null,
              child: Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 25.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
                color: cardColor,
                child: ListTile(
                  leading: Icon(Icons.phone),
                  title: Text(
                    phoneNumberText ?? AppLocalizations.of(context)!.phone,
                    style: TextStyle(
                      color: textColor,
                    ),
                  ),
                  onTap: () => showAlert(context),
                ),
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 25.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.0),
              ),
              color: cardColor,
              child: ListTile(
                leading: Icon(Icons.mail),
                title: Text(
                  emailText ?? AppLocalizations.of(context)!.mail,
                  style: TextStyle(
                    color: textColor,
                  ),
                ),
                onTap: () => launchUrl(Uri.parse('mailto:' + email!)),
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 25.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.0),
              ),
              color: cardColor,
              child: ListTile(
                leading: Icon(Icons.home),
                title: Text(
                  AppLocalizations.of(context)!.address,
                  style: TextStyle(
                    color: textColor,
                  ),
                ),
                onTap: () => showAlertDialog(context, "თბილისი...", AppLocalizations.of(context)!.address),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///Class for adding contact details of the developer in your bottomNavigationBar in your flutter app.
class ContactUsBottomAppBar extends StatelessWidget {
  ///Color of the text which will be displayed in the bottomNavigationBar
  final Color textColor;

  ///Color of the background of the bottomNavigationBar
  final Color backgroundColor;

  ///Email ID Of the company/developer on which, when clicked by the user, the respective mail app will be opened.
  final String email;

  ///Name of the company or the developer
  final String companyName;

  ///Size of the font in bottomNavigationBar
  final double fontSize;

  ContactUsBottomAppBar(
      {required this.textColor,
        required this.backgroundColor,
        required this.email,
        required this.companyName,
        this.fontSize = 15.0});
  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(
        'Want to contact?',
        textAlign: TextAlign.center,
        style: TextStyle(color: textColor, fontSize: fontSize),
      ),
      onPressed: () => launchUrl(Uri.parse('mailto:$email')),
    );
  }
}