import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/commons/animation_controller_class.dart';
import 'package:geo_couriers/app/commons/mini_menu/my_account/balance.dart';
import 'package:geo_couriers/custom/custom_icons.dart';
import 'package:geo_couriers/app/authenticate/utils/authenticate_utils.dart';
import 'package:geo_couriers/globals.dart';
import 'package:geo_couriers/utils/lazo_utils.dart';
import 'package:geo_couriers/app/commons/star_rating.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';


class AccountPage extends StatefulWidget {
  @override
  _AccountPage createState() => _AccountPage();
}

class _AccountPage extends State<AccountPage> {
  var _rating;

  //სერვერიდან მოაქვს user-ის შეფასება
  Future<bool> updateRatingFromServerAccountPage() async {
    
    try {
      final res = await geoCourierClient.post('miniMenu/get_rating');

      if(res.statusCode ==200) {
        if (res.data == null) {
          return false;
        }
        _rating = res.data.toString();
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 403) {
        reloadApp(context);
      } else {
        showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
      }
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: updateRatingFromServerAccountPage(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.my_account),
              ),
              // backgroundColor: Colors.white70,
              floatingActionButton: FloatingActionButton(
                heroTag: "btn1",
                child: Icon(CustomIcons.fb_messenger),
                onPressed: () {
                  launchUrl(Uri.parse("http://" +dotenv.env['MESSENGER']!), mode: LaunchMode.externalApplication);
                },
              ),
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
                          // generateCard(ListTile(
                          //   title: Text(
                          //     AppLocalizations.of(context)!.bank_account,
                          //     textAlign: TextAlign.center,
                          //   ),
                          //   onTap: () {
                          //     // Navigator.push(
                          //     //   context,
                          //     //   MaterialPageRoute(builder: (context) => BankAccount()),
                          //     // );
                          //   } ,
                          // ), 10.0),
                          generateCard(ListTile(
                            title: Text(
                              AppLocalizations.of(context)!.balance,
                              textAlign: TextAlign.center,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => Balance()),
                              );
                            } ,
                          ), 10.0),
                          generateCard(ListTile(
                            title: StarRating(rating: _rating !=null ? double.parse(_rating) : 0),
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