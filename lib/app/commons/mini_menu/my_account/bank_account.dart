import 'package:argon_buttons_flutter/argon_buttons_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:geo_couriers/globals.dart';

import '../../../../main.dart';
import '../../../../utils/lazo_utils.dart';
import '../../../authenticate/utils/authenticate_utils.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../animation_controller_class.dart';
import 'models/user_cards.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BankAccount extends StatefulWidget {
  @override
  _BankAccount createState() => _BankAccount();
}

class _BankAccount extends State<BankAccount> {
  String _cardNumber = '';
  String _expiryDate = '';
  String _cardHolderName = '';
  String _cvvCode = '';
  bool _isCvvFocused = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _bankAccountPageLoad() async {

    try {

      final res = await geoCourierClient.post(
        'balance/get_user_card_credentials',
      );

      List<UserCards> cards = List<UserCards>.from(res.data.map((i) => UserCards.fromJson(i)));

      if (cards.isEmpty)
        return true;

      var card = cards[0];
      _cardNumber = card.cardNumber!;
      _expiryDate = card.validThru!;
      _cardHolderName = card.cardHolder!;
      _cvvCode = card.cvv!;

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
        future: _bankAccountPageLoad(),
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(),
              resizeToAvoidBottomInset: false,
              body: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * (kIsWeb ? 0.5 : 1.0),
                  child: SafeArea(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(
                          height: 30,
                        ),
                        CreditCardWidget(
                            cardNumber: _cardNumber,
                            expiryDate: _expiryDate,
                            cardHolderName: _cardHolderName,
                            cvvCode: _cvvCode,
                            showBackView: _isCvvFocused,
                            obscureCardNumber: true,
                            obscureCardCvv: true,
                            isHolderNameVisible: true,
                            cardBgColor: Colors.deepOrange,
                            isSwipeGestureEnabled: true,
                            onCreditCardWidgetChange: (CreditCardBrand creditCardBrand) {}
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: <Widget>[
                                CreditCardForm(
                                  formKey: _formKey,
                                  obscureCvv: true,
                                  obscureNumber: true,
                                  cardNumber: _cardNumber,
                                  cvvCode: _cvvCode,
                                  isHolderNameVisible: true,
                                  isCardNumberVisible: true,
                                  isExpiryDateVisible: true,
                                  cardHolderName: _cardHolderName,
                                  expiryDate: _expiryDate,
                                  onCreditCardModelChange: onCreditCardModelChange,
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                ArgonTimerButton(
                                  height: 50,
                                  width: MediaQuery.of(context).size.width * 0.6,
                                  minWidth: MediaQuery.of(context).size.width * 0.5,
                                  highlightColor: Colors.transparent,
                                  highlightElevation: 0,
                                  roundLoadingShape: false,
                                  onTap: (startTimer, btnState) async {
                                    if (btnState == ButtonState.Idle) {
                                      startTimer(5);
                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }

                                      try {
                                        await geoCourierClient.post(
                                          'balance/set_card_credentials',
                                          queryParameters: {
                                            "cardNumber": _cardNumber,
                                            "expiryDate": _expiryDate,
                                            "cardHolderName": _cardHolderName,
                                            "cvvCode": _cvvCode,
                                          },
                                        );
                                      } catch (e) {
                                        if (e is DioException && e.response?.statusCode == 403) {
                                          reloadApp(context);
                                        } else {
                                          showAlertDialog(context, "", AppLocalizations.of(context)!.the_connection_to_the_server_was_lost);
                                        }
                                      }
                                    }
                                  },
                                  child: Icon(Icons.upload, color: Colors.white,),
                                  loader: (timeLeft) {
                                    return Text(
                                      AppLocalizations.of(context)!.please_wait + " | $timeLeft",
                                      style: TextStyle(
                                          color: MyApp.of(context)!.isDarkModeEnabled ? Colors.white : Colors.black,
                                          fontSize: 15
                                      ),
                                    );
                                  },
                                  borderRadius: 18.0,
                                  color: Colors.deepOrange,
                                  elevation: 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  void onCreditCardModelChange(CreditCardModel? creditCardModel) {
    setState(() {
      _cardNumber = creditCardModel!.cardNumber;
      _expiryDate = creditCardModel.expiryDate;
      _cardHolderName = creditCardModel.cardHolderName.toUpperCase();
      _cvvCode = creditCardModel.cvvCode;
      _isCvvFocused = creditCardModel.isCvvFocused;
    });
  }
}