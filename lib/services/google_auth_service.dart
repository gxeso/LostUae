// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static Future<User?> signInWithGoogle() async {
    try {

      // Initialize (REQUIRED in v7.2+)
      await _googleSignIn.initialize(
        serverClientId: null, // keep null unless using backend verification
      );

      // Clear previous session
      await _googleSignIn.signOut();

      // Start authentication
      final GoogleSignInAccount account =
          await _googleSignIn.authenticate();

      final GoogleSignInAuthentication auth =
          await account.authentication;

      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      return userCredential.user;

    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }
}