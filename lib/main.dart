import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Providers
import 'providers/terms_provider.dart';
import 'providers/app_ready_provider.dart';

// Screens
import 'screens/splash/splash_screen.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/welcome/select_event_type_screen.dart';
import 'screens/welcome/where_are_you_screen.dart';
import 'screens/welcome/change_start_date_screen.dart';
import 'screens/welcome/proximity_screen.dart';
import 'screens/list_of_events/list_of_events_screen.dart';
import 'screens/manage/add_venue_screen.dart';
import 'screens/terms/terms_screen.dart';

// Services
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseService.init();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAccepted = ref.watch(termsAcceptedProvider);
    final appReady = ref.watch(appReadyProvider);

    final router = GoRouter(
      initialLocation: '/splash',

      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/select',
          builder: (context, state) => const SelectEventTypeScreen(),
        ),
        GoRoute(
          path: '/where',
          builder: (context, state) => const WhereAreYouScreen(),
        ),
        GoRoute(
          path: '/change-date',
          builder: (context, state) => const ChangeStartDateScreen(),
        ),
        GoRoute(
          path: '/proximity',
          builder: (context, state) => const ProximityScreen(),
        ),
        GoRoute(
          path: '/events',
          builder: (context, state) => const ListOfEventsScreen(),
        ),
        GoRoute(
          path: '/add-venue',
          builder: (context, state) => const AddVenueScreen(),
        ),
        GoRoute(
          path: '/terms',
          builder: (context, state) => const TermsScreen(),
        ),
      ],

      redirect: (context, state) {
        final location = state.matchedLocation;
        final isSplash = location == '/splash';
        final isTerms = location == '/terms';

        // 🌿 BLOCK EVERYTHING UNTIL SPLASH FINISHES
        if (!appReady) {
          return isSplash ? null : '/splash';
        }

        // 🌙 AFTER SPLASH → ENSURE WE LEAVE IT
        if (isSplash) {
          return '/welcome';
        }

        // 🌙 TERMS LOGIC AFTER BOOT
        if (!termsAccepted && !isTerms) return '/terms';
        if (termsAccepted && isTerms) return '/welcome';

        return null;
      },
    );

    return MaterialApp.router(
      title: 'Find An Event',
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
