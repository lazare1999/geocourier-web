import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:geo_couriers/app/authenticate/login/login_page.dart';
import 'package:geo_couriers/app/main_menu.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geo_couriers/app/roles/buyer/buyer_main_page.dart';
import 'package:geo_couriers/app/roles/courier/main/courier_main_page.dart';
import 'package:geo_couriers/app/roles/courier_company/courier_company_main_page.dart';
import 'package:geo_couriers/app/roles/sender/sender_main_page.dart';
import 'package:geo_couriers/utils/create_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_route_observer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';

import 'utils/notification_utils.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");

  var title = message.data['title'];
  var body = message.data['body'];

  notify(title, body);
}

String? token;
List subscribed = [];

void main() async {

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await dotenv.load(fileName: ".env");
  if (!kIsWeb) {

    await Permission.location.request();

    await Permission.notification.request();

    WidgetsFlutterBinding.ensureInitialized();

    AwesomeNotifications().initialize(
        'resource://drawable/app_icon',
        [
          NotificationChannel(
            channelGroupKey: 'basic_tests',
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            defaultColor: Colors.deepOrange,
            ledColor: Colors.white,
            playSound: true,
            importance: NotificationImportance.High,
          )
        ],
        channelGroups: [
          NotificationChannelGroup(channelGroupName: 'Basic tests', channelGroupKey: 'basic_tests')
        ]
    );
  }

  await populateIcons();

  if(kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyCr5Sn7_JOkibgCjIFPEaHEJqsjJiwrzHg",
        authDomain: "geocourier-89986.firebaseapp.com",
        appId: "1:744694669633:web:0a2e2c579f2e6afffe81c0",
        messagingSenderId: "744694669633",
        projectId: "geocourier-89986",
        storageBucket: "geocourier-89986.appspot.com",
      ),
    );
  } else {
    await Firebase.initializeApp(
      name: 'courier',
      options: FirebaseOptions(
        apiKey: "AIzaSyCr5Sn7_JOkibgCjIFPEaHEJqsjJiwrzHg",
        authDomain: "geocourier-89986.firebaseapp.com",
        appId: "1:744694669633:web:0a2e2c579f2e6afffe81c0",
        messagingSenderId: "744694669633",
        projectId: "geocourier-89986",
        storageBucket: "geocourier-89986.appspot.com",
      ),
    );
  }


  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.setAutoInitEnabled(true);

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: true,
    criticalAlert: false,
    provisional: false,
    sound: true
  );

  print('User granted permission: ${settings.authorizationStatus}');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {

    var title = message.data['title'];
    var body = message.data['body'];

    notify(title, body);

  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    var title = message.data['title'];
    var body = message.data['body'];

    notify(title, body);

  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
      RestartWidget(
        child: MyApp(kGoogleApiKey: dotenv.env['GOOGLE_API_KEY'],)
      )
  );
}

class RestartWidget extends StatefulWidget {
  RestartWidget({this.child});

  final Widget? child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()!.restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child!,
    );
  }
}

class MyApp extends StatefulWidget {
  final String? kGoogleApiKey;

  MyApp({required this.kGoogleApiKey});

  @override
  _MyAppState createState() => _MyAppState(kGoogleApiKey: kGoogleApiKey);

  static _MyAppState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  final String? kGoogleApiKey;

  _MyAppState({required this.kGoogleApiKey});

  Locale _locale = Locale.fromSubtags(languageCode: 'ka');

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  void initState() {
    super.initState();
    initialization();
    if (!kIsWeb) {
      initiateNotificationPage(context);
    }

    FirebaseMessaging.instance.getToken().then((value) {
      token = value;
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      token = newToken;
    });

    getTopics();

  }

  void initialization() async {

    FlutterNativeSplash.remove();

    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    if(_prefs.getBool("isDarkModeEnabled") !=null) {
      isDarkModeEnabled = _prefs.getBool("isDarkModeEnabled")!;
    }

  }

  bool isDarkModeEnabled = false;

  void onStateChanged(bool isDarkModeEnabled) async {

    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    _prefs.setBool("isDarkModeEnabled", isDarkModeEnabled);

    setState(() {
      this.isDarkModeEnabled = isDarkModeEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.title,
      // title: 'კურიერი',
      navigatorObservers: <NavigatorObserver>[
        MyRouteObserver(), // this will listen all changes
      ],
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: AppBarTheme(color: const Color(0xFF253341)),
        scaffoldBackgroundColor: const Color(0xFF15202B),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white
        )
      ),
      themeMode: isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', ''), // ინგლისური
        Locale('ka', ''), // ქართული
        Locale('ru', ''), // რუსული
      ],
      locale: _locale,
      routes: {
        '/': (context) {
          return LoginPage();
        },
        '/sender': (context) {
          return SenderMainPage(kGoogleApiKey: kGoogleApiKey,);
        },
        '/courier': (context) {
          return CourierMainPage(kGoogleApiKey: kGoogleApiKey,);
        },
        '/courier_company': (context) {
          return CourierCompanyMainPage(kGoogleApiKey: kGoogleApiKey,);
        },
        '/buyer': (context) {
          return BuyerMainPage(kGoogleApiKey: kGoogleApiKey,);
        },
        '/main_menu': (context) {
          return MainMenu();
        }
      },
    );
  }

  getTopics() async {
    await FirebaseFirestore.instance
        .collection('topics')
        .get()
        .then((value) => value.docs.forEach((element) {
      if (token == element.id) {
        subscribed = element.data().keys.toList();
      }
    }));

    setState(() {
      subscribed = subscribed;
    });
  }

}
