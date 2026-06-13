import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_ready_provider.dart';
import '../../providers/event_type_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _prepareApp();
  }

  Future<void> _prepareApp() async {
    await Future.wait([
      Future<void>.delayed(const Duration(seconds: 5)),
      _loadEventTypes(),
    ]);

    if (!mounted) return;
    ref.read(appReadyProvider.notifier).state = true;
  }

  Future<void> _loadEventTypes() async {
    try {
      await ref
          .read(eventTypesProvider.future)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Let the app continue; the event-type screens will show the load error.
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Image(
          image: AssetImage('assets/icon.png'),
          width: 240,
          height: 240,
        ),
      ),
    );
  }
}
