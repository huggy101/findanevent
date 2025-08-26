import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_models.dart';
import 'app_providers.dart';

final authStateProvider = StreamProvider<AppUser?>((ref) => ref.read(authServiceProvider).authState());
