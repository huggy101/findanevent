import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import your screens
import 'screens/welcome/welcome_screen.dart';
import 'screens/welcome/select_event_type_screen.dart';
import 'screens/welcome/where_are_you_screen.dart';
import 'screens/welcome/change_start_date_screen.dart';
import 'screens/list_of_events/list_of_events_screen.dart';
// import 'screens/login/login_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter _router = GoRouter(
      initialLocation: '/', // First screen
      routes: [
        GoRoute(
          path: '/',
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
          path: '/events',
          builder: (context, state) => const ListOfEventsScreen(),
        ),
        // GoRoute(
        //   path: '/login',
        //   builder: (context, state) => const LoginScreen(),
        // ),
      ],
    );

    return MaterialApp.router(
      title: 'Find An Event',
      routerConfig: _router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
