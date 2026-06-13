import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/terms_provider.dart';

class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  static const _termsText = '''
Find An Event - Terms and Conditions

Find An Event helps people discover music, open mic, jam, gig, and similar events. By using this app you agree to these terms.

1. Searching for events
Searching for events is free. You may browse and search event listings without paying a charge.

2. Registration and verification
Some features require you to register. When registration is required, you must provide accurate details and verify your account using an email address or phone number. You are responsible for keeping your login details secure.

3. Adding venues and events
Adding, updating, or managing venues and events requires registration and authorisation. A charge may apply for inputting venues, inputting events, or using event-management features. Any charge will be shown before you submit paid information.

4. Accuracy of listings
Venue and event details must be truthful, current, and not misleading. If you create or amend a listing, you are responsible for checking names, dates, times, addresses, contact details, prices, facilities, and other information before submitting it.

5. Approval and removal
We may review, approve, reject, amend, suspend, or remove venue and event listings where needed, including where information appears incorrect, duplicated, inappropriate, unauthorised, or out of date.

6. Changes and cancellations
Events can change or be cancelled. Users should check with the venue, host, or organiser before travelling or relying on a listing. Find An Event is not responsible for losses caused by changed, cancelled, inaccurate, or unavailable events.

7. Acceptable use
You must not misuse the app, attempt to access systems without permission, submit spam, impersonate another person or organisation, upload offensive or unlawful content, or use the app in a way that harms other users or the service.

8. Contact details and notifications
If you provide an email address or phone number, it may be used for verification, account messages, listing administration, and important service updates. In the future, event creation and amendment confirmations may be sent to the registered user who submitted the listing.

9. Fees and refunds
Where paid venue or event input services are introduced, the relevant price and payment terms will be provided at the point of purchase. Refund rules may depend on the service purchased and whether work has already started or the listing has already been submitted.

10. Service availability
We aim to keep the app available, but access may be interrupted for maintenance, updates, technical issues, or reasons outside our control.

11. Updates to these terms
These terms may be updated as the app develops, including when registration, paid listing features, and organiser accounts are added. Continued use of the app after updated terms are shown means you accept the updated terms.

These terms are intended as practical app wording and should be reviewed before public launch.
''';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _termsText,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(termsAcceptedProvider.notifier).accept();
                    context.go('/welcome');
                  },
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
