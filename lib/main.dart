import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safety_apps/drawer/lpi_result_page.dart';
import 'package:safety_apps/firebase/firebase_notification_service.dart';
import 'package:safety_apps/firebase/local_notification.dart';
import 'package:safety_apps/network/global_offline.dart';
import 'package:safety_apps/pages/event/hses_buletin.dart';
import 'package:safety_apps/pages/event/hses_daily_plant.dart';
import 'package:safety_apps/pages/splash_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// ================= BACKGROUND HANDLER =================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await LocalNotificationService.init();

  await LocalNotificationService.show(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await LocalNotificationService.init();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const GlobalOfflineListener(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  /// ================= INIT FCM =================
  Future<void> _initFirebase() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await FirebaseNotificationService.init();
    FirebaseNotificationService.listeners();

    /// Handle jika app dibuka dari TERMINATED
    final message = await FirebaseMessaging.instance.getInitialMessage();

    if (message != null) {
      FirebaseNotificationService.handleNavigationFromMessage(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Safe Day',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryTextTheme: GoogleFonts.poppinsTextTheme(),
        fontFamily: GoogleFonts.poppins().fontFamily,
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      home: SplashPage(),
      onGenerateRoute: (settings) {
        if (settings.name == "/daily-plan") {
          final args = settings.arguments as Map<String, dynamic>?;

          return MaterialPageRoute(
            builder: (_) =>
                HSESDailyPlanPage(openDetailId: args?["open_detail_id"]),
          );
        }

        if (settings.name == "/buletin") {
          final args = settings.arguments as Map<String, dynamic>?;
          final openId = args?["open_detail_id"];

          return MaterialPageRoute(
            builder: (_) => HSESBuletinPage(
              openDetailId: openId is int
                  ? openId
                  : int.tryParse((openId ?? "").toString()),
            ),
          );
        }

        if (settings.name == "/lpi-results") {
          final args = settings.arguments as Map<String, dynamic>?;
          final openId = args?["open_detail_id"];

          return MaterialPageRoute(
            builder: (_) => LPIResultPage(
              openDetailId: openId is int
                  ? openId
                  : int.tryParse((openId ?? "").toString()),
            ),
          );
        }

        return null;
      },
    );
  }
}
