import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_models.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  Stream<AppUser?> authState() => _auth.authStateChanges().map((u) => u == null ? null : AppUser(uid: u.uid, email: u.email, displayName: u.displayName));

  AppUser? current() { final u = _auth.currentUser; return u == null ? null : AppUser(uid: u.uid, email: u.email, displayName: u.displayName); }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser> signInWithGoogle() async {
    final gUser = await GoogleSignIn().signIn();
    final gAuth = await gUser!.authentication;
    final cred = fb.GoogleAuthProvider.credential(idToken: gAuth.idToken, accessToken: gAuth.accessToken);
    final userCred = await _auth.signInWithCredential(cred);
    final u = userCred.user!;
    return AppUser(uid: u.uid, email: u.email, displayName: u.displayName);
  }

  Future<AppUser> registerWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final u = cred.user!; return AppUser(uid: u.uid, email: u.email, displayName: u.displayName);
  }

  Future<AppUser> loginWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final u = cred.user!; return AppUser(uid: u.uid, email: u.email, displayName: u.displayName);
  }

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  // MFA/2FA hooks – configure in Firebase console; enroll flows can be added later.
}