import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import your providers
import 'providers/terms_provider.dart';

// Import your screens
import 'screens/welcome/welcome_screen.dart';
import 'screens/welcome/select_event_type_screen.dart';
import 'screens/welcome/where_are_you_screen.dart';
import 'screens/welcome/change_start_date_screen.dart';
import 'screens/welcome/proximity_screen.dart';
import 'screens/list_of_events/list_of_events_screen.dart';
import 'screens/terms/terms_screen.dart';
// import 'screens/login/login_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build router depending on terms acceptance
    final termsAccepted = ref.watch(termsAcceptedProvider);

    final router = GoRouter(
      initialLocation: '/welcome',
      routes: [
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
          path: '/terms',
          builder: (context, state) => const TermsScreen(),
        ),
        // GoRoute(
        //   path: '/login',
        //   builder: (context, state) => const LoginScreen(),
        // ),
      ],
      redirect: (context, state) {
        final isGoingToTerms = state.fullPath == '/terms';

        // If not accepted and not already on /terms, send them there
        if (!termsAccepted && !isGoingToTerms) {
          return '/terms';
        }

        // If already accepted and trying to go to /terms, send home
        if (termsAccepted && isGoingToTerms) {
          return '/welcome';
        }

        return null; // no redirect
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
