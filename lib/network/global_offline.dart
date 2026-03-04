import 'package:flutter/material.dart';
import 'package:safety_apps/network/network_service.dart';
import '../main.dart';

class GlobalOfflineListener extends StatefulWidget {
  final Widget child;
  const GlobalOfflineListener({super.key, required this.child});

  @override
  State<GlobalOfflineListener> createState() => _GlobalOfflineListenerState();
}

class _GlobalOfflineListenerState extends State<GlobalOfflineListener>
    with WidgetsBindingObserver {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _checkInitialConnection();

    NetworkService.startListening(
      onOffline: _showOffline,
      onOnline: _hideOffline,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NetworkService.stopListening();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {}
  }

  Future<void> _checkInitialConnection() async {
    final isOffline = await NetworkService.isOffline();
    if (isOffline) {
      _showOffline();
    } else {
      _hideOffline();
    }
  }

  void _showOffline() {
    if (_dialogShown) return;
    _dialogShown = true;

    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (_) => const _OfflineDialog(),
    );
  }

  void _hideOffline() {
    if (_dialogShown) {
      navigatorKey.currentState?.pop();
      _dialogShown = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _OfflineDialog extends StatelessWidget {
  const _OfflineDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  color: theme.colorScheme.error,
                  size: 28,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Koneksi Terputus',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Tidak ada koneksi internet.\n'
                'Periksa WiFi atau data seluler Anda.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
