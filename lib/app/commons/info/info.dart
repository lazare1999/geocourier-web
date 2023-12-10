import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../main.dart';

class Info extends StatelessWidget {

  final ListView? safeAreaChild;
  final String? youtubeLink;

  Info({required this.safeAreaChild, required this.youtubeLink});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(" "),
        leading: Container()
      ),
      backgroundColor: MyApp.of(context)!.isDarkModeEnabled ? Color(0xFF15202B) : Colors.white,
      body: safeAreaChild!,
      persistentFooterButtons: [
        Column(
          children: <Widget>[
            ListTile(
              title: Row(
                children: <Widget>[
                  Container(
                    width: 30.0,
                    height: 30.0,
                    child: Image.asset('assets/images/youtube_text.png'),
                  ),
                  Flexible(
                      child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: " ",
                            style: Theme.of(context).textTheme.bodyLarge,
                            children: [
                              TextSpan(
                                //TODO : youtube ინსტრუქცია მომავალში
                                text: AppLocalizations.of(context)!.video_instruction,
                                recognizer: TapGestureRecognizer()..onTap = () {
                                  launchUrl(Uri.parse(youtubeLink!), mode: LaunchMode.externalApplication);
                                },
                              )
                            ],
                          ),
                        ),
                      )
                  ),

                ],
              ),
            ),
            ListTile(
              title: Text(
                AppLocalizations.of(context)!.order_contains_one_or_several_parcels,
                style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold
                ),
              ),

            )
          ],
        ),


      ],
    );

  }

}