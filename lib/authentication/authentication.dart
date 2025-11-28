import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ────────────────────────────────
  //  Email / Password
  // ────────────────────────────────
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.sendEmailVerification();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseError(e));
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseError(e));
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseError(e));
    } catch (e) {
      throw Exception("Password reset failed: $e");
    }
  }

  Future<bool> checkUserExists(String email) async {
    try {

      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw Exception('Invalid email format.');
      }

      return true; 
    } catch (e) {
      throw Exception('Failed to check account status.');
    }
  }

  // ────────────────────────────────
  //  Google
  // ────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseError(e));
    } catch (e) {
      throw Exception("Google sign-in failed: $e");
    }
  }

  // ────────────────────────────────
  //  Facebook
  // ────────────────────────────────
  // Future<UserCredential?> signInWithFacebook() async {
  //   try {
  //     final LoginResult result = await FacebookAuth.instance.login();

  //     if (result.status == LoginStatus.success) {
  //       final AccessToken accessToken = result.accessToken!;
  //       final credential =
  //           FacebookAuthProvider.credential(accessToken.tokenString);
  //       return await _auth.signInWithCredential(credential);
  //     } else if (result.status == LoginStatus.cancelled) {
  //       return null;
  //     } else {
  //       throw Exception(result.message ?? 'Facebook sign-in failed.');
  //     }
  //   } on FirebaseAuthException catch (e) {
  //     throw Exception(_firebaseError(e));
  //   } catch (e) {
  //     throw Exception("Facebook sign-in failed: $e");
  //   }
  // }

  // ────────────────────────────────
  //  Logout
  // ────────────────────────────────
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
     // await FacebookAuth.instance.logOut();
    } catch (e) {
      throw Exception("Sign-out failed: $e");
    }
  }

  // ────────────────────────────────
  //  Helpers
  // ────────────────────────────────
  User? get currentUser => _auth.currentUser;

  String _firebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-disabled':
        return 'User has been disabled.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'weak-password':
        return 'Password too weak.';
      default:
        return 'Invalid email or password.';
    }
  }
}