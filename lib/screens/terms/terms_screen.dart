import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/terms_provider.dart';

class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "Here are the Terms and Conditions...\n\n"
                  "1. You agree to be nice.\n"
                  "2. You won’t misuse the app.\n"
                  "3. Etc…",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(termsAcceptedProvider.notifier).accept();
                context.go('/welcome'); // go straight to Welcome
              },
              child: const Text('Accept'),
            ),
          ],
        ),
      ),
    );
  }
}
