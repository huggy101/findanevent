import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/terms_provider.dart';
import '../../widgets/search_settings_buttons.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const _MainActions(),
                            const Spacer(),
                            _BottomActions(ref: ref),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: SystemNavigator.pop,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainActions extends StatelessWidget {
  const _MainActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Text(
            'FIND A ...',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        const SearchSettingsButtons(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/add-venue'),
                icon: const Icon(Icons.add_business),
                label: const Text('Add Venue'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/add-event'),
                icon: const Icon(Icons.event),
                label: const Text('Add An Event'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => context.push('/events'),
          child: const Text('Find The Events'),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  final WidgetRef ref;

  const _BottomActions({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.push('/instructions'),
          icon: const Icon(Icons.help_outline),
          label: const Text('How To Use The App'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            ref.read(termsAcceptedProvider.notifier).resetForTesting();
            context.push('/terms');
          },
          child: const Text('Force Terms Again (Testing)'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.push('/login'),
          child: const Text('Login/Register - Needed For Updating Events'),
        ),
      ],
    );
  }
}
