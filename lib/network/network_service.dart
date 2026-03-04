import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/foundation.dart';

class NetworkService {
  static final _connectivity = Connectivity();
  static final _internetChecker = InternetConnectionChecker.createInstance();

  static StreamSubscription? _subscription;

  static void startListening({
    required VoidCallback onOffline,
    required VoidCallback onOnline,
  }) {
    _subscription = _connectivity.onConnectivityChanged.listen((_) async {
      final hasInternet = await _internetChecker.hasConnection;

      if (!hasInternet) {
        onOffline();
      } else {
        onOnline();
      }
    });
  }

  static void stopListening() {
    _subscription?.cancel();
  }

  static Future<bool> isOffline() async {
    return !(await _internetChecker.hasConnection);
  }
}
