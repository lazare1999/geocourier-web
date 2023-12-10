import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void notify(title, body) async {

  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final preferred = widgetsBinding.platformDispatcher.locales;
  const supported = AppLocalizations.supportedLocales;
  final locale = basicLocaleListResolution(preferred, supported);
  AppLocalizations t = await AppLocalizations.delegate.load(locale);


  switch (body) {
    case "COURIER_APPROVED_JOB" : body = t.courier_approved_job; break;
    case "JOBS_DONE" : body = t.jobs_done; break;
    case "HAND_OVER_JOB" : body = t.hand_over_job; break;
    case "PARCEL_UNSUCCESSFUL" : body = t.parcel_unsuccessful; break;
    case "COURIER_TOOK_PARCEL" : body = t.courier_took_parcel; break;
  }



  AwesomeNotifications().createNotification(
    content: NotificationContent(
        id: 1,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        criticalAlert: true
    ),
  );
}

void scheduledNotification() async {
  String timezone = await AwesomeNotifications().getLocalTimeZoneIdentifier(); //get time zone you are in
  AwesomeNotifications().createNotification(
    content: NotificationContent(
        id: 1,
        channelKey: 'key1',
        title: 'This is Notification title',
        body: 'This is Body of Noti',
        bigPicture: '/assets/icons/courier.png',
        notificationLayout: NotificationLayout.BigPicture
    ),
    schedule: NotificationInterval(interval: 2,timeZone: timezone, repeats: true),
  );
}

Future<void> initiateNotificationPage(context) async {

  //TODO : გამოსვლისას ერორიაქ
  // if(await AwesomeNotifications().actionStream.isEmpty) {
  //   AwesomeNotifications().actionStream.listen((payload) {
  //
  //   });
  // }

}

