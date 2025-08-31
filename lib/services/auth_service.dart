import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_models.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Remove the constructor and _initializeGoogleSignIn method
  // They are no longer needed in newer versions

  Stream<AppUser?> authState() {
    return _auth.authStateChanges().map((user) {
      if (user == null) {
        return null;
      } else {
        return AppUser(uid: user.uid, email: user.email, displayName: user.displayName);
      }
    });
  }

  AppUser? current() {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    } else {
      return AppUser(uid: user.uid, email: user.email, displayName: user.displayName);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<AppUser> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception("Google sign-in aborted by user");
    }

    final GoogleSignInAuthentication gAuth = await googleUser.authentication;
    final fb.OAuthCredential credential = fb.GoogleAuthProvider.credential(
      idToken: gAuth.idToken,
      accessToken: gAuth.accessToken,
    );

    final fb.UserCredential userCred = await _auth.signInWithCredential(credential);
    final fb.User user = userCred.user!;

    return AppUser(uid: user.uid, email: user.email, displayName: user.displayName);
  }

  Future<AppUser> registerWithEmail(String email, String password) async {
    final fb.UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fb.User user = cred.user!;
    return AppUser(uid: user.uid, email: user.email, displayName: user.displayName);
  }

  Future<AppUser> loginWithEmail(String email, String password) async {
    final fb.UserCredential cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fb.User user = cred.user!;
    return AppUser(uid: user.uid, email: user.email, displayName: user.displayName);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}