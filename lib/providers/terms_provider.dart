import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final termsAcceptedProvider =
    StateNotifierProvider<TermsNotifier, bool>((ref) => TermsNotifier());

class TermsNotifier extends StateNotifier<bool> {
  TermsNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('termsAccepted') ?? false;
  }

  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('termsAccepted', true);
    state = true;
  }

  /// Reset the terms flag so the Terms screen shows again (for testing).
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('termsAccepted');
    state = false;
  }
}
