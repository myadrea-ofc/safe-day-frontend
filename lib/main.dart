import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:safety_apps/drawer/access_permission.dart';
import 'package:safety_apps/drawer/excel_access_request.dart';
import 'package:safety_apps/drawer/lpi_result_page.dart';
import 'package:safety_apps/firebase/firebase_notification_service.dart';
import 'package:safety_apps/firebase/local_notification.dart';
import 'package:safety_apps/network/global_offline.dart';
import 'package:safety_apps/pages/event/hses_buletin.dart';
import 'package:safety_apps/pages/event/hses_daily_plant.dart';
import 'package:safety_apps/pages/splash_page.dart';
import 'package:safety_apps/service/device_id_service.dart';
import 'package:safety_apps/service/pending/pending_submission_service.dart';

import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await LocalNotificationService.init();

    if (!LocalNotificationService.isNotificationPayload(message) &&
        LocalNotificationService.hasDisplayContent(message)) {
      await LocalNotificationService.show(message);
    }
  }

  debugPrint("📦 BACKGROUND MESSAGE DATA: ${message.data}");
  debugPrint("📦 BACKGROUND MESSAGE TITLE: ${message.notification?.title}");
  debugPrint("📦 BACKGROUND MESSAGE BODY: ${message.notification?.body}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await LocalNotificationService.init();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  await PendingSubmissionService.init();

  // WAJIB: generate device_id sebelum SplashPage membaca storage
  await DeviceIdService.getOrCreateDeviceId();

  runApp(const GlobalOfflineListener(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _firebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _initFirebaseNotification();
  }

  Future<void> _initFirebaseNotification() async {
    if (_firebaseInitialized) return;
    _firebaseInitialized = true;

    if (kIsWeb) {
      debugPrint("Firebase notification skipped on web");
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      await FirebaseNotificationService.init();
      FirebaseNotificationService.listeners();

      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FirebaseNotificationService.handleNavigationFromMessage(message);
        });
      }
    } catch (e) {
      debugPrint("Firebase notification init skipped/error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Safe Day',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
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
      home: const SplashPage(),
      onGenerateRoute: (settings) {
        final args = settings.arguments is Map<String, dynamic>
            ? settings.arguments as Map<String, dynamic>
            : <String, dynamic>{};

        switch (settings.name) {
          case "/daily-plan":
            return MaterialPageRoute(
              builder: (_) =>
                  HSESDailyPlanPage(openDetailId: args["open_detail_id"]),
            );

          case "/buletin":
            final openId = args["open_detail_id"];
            return MaterialPageRoute(
              builder: (_) => HSESBuletinPage(
                openDetailId: openId is int
                    ? openId
                    : int.tryParse((openId ?? "").toString()),
              ),
            );

          case "/lpi-results":
            final openId = args["open_detail_id"];
            return MaterialPageRoute(
              builder: (_) => LPIResultPage(
                openDetailId: openId is int
                    ? openId
                    : int.tryParse((openId ?? "").toString()),
              ),
            );

          case "/excel-access-requests":
            return MaterialPageRoute(
              builder: (_) => ExcelAccessRequestPage(
                feature: (args["feature"] ?? "").toString(),
              ),
            );

          case "/excel-access-permission":
            return MaterialPageRoute(
              builder: (_) => AccessPermissionPage(
                feature: (args["feature"] ?? "").toString(),
              ),
            );

          default:
            return MaterialPageRoute(builder: (_) => const SplashPage());
        }
      },
    );
  }
}
