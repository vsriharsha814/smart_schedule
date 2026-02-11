import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Phase I: Identity and OAuth 2.0 token gateway.
///
/// In a no-backend architecture, authentication is not only a gatekeeper but
/// the mechanism to obtain short-lived tokens the client uses to talk directly
/// to third-party APIs (e.g. Google Calendar). This service exposes those
/// tokens for use by API clients.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Stream of auth state; use for routing (signed-in vs signed-out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current Firebase user, if any.
  User? get currentUser => _auth.currentUser;

  /// Sign in with Google (primary gateway for identity and OAuth 2.0).
  /// Establishes Firebase identity and makes Google tokens available.
  Future<void> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return;

    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
      accessToken: auth.accessToken,
    );
    await _auth.signInWithCredential(credential);
  }

  /// Sign out from Firebase and Google.
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Short-lived ID token for the current user (e.g. for backend or API checks).
  /// Returns null if not signed in or token cannot be obtained.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  /// OAuth 2.0 access token for calling Google APIs (e.g. Calendar) directly.
  /// Returns null if not signed in or token cannot be obtained.
  Future<String?> getAccessToken() async {
    final account = await _googleSignIn.signInSilently();
    final auth = await account?.authentication;
    return auth?.accessToken;
  }

  /// Both tokens for direct use by API clients. Prefer this when you need
  /// to call Google APIs with the same identity as Firebase.
  Future<OAuthTokens?> getOAuthTokens({bool forceRefreshIdToken = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final account = await _googleSignIn.signInSilently();
    final googleAuth = await account?.authentication;
    if (googleAuth == null) return null;

    final idToken = forceRefreshIdToken
        ? await user.getIdToken(true)
        : googleAuth.idToken ?? await user.getIdToken();
    return OAuthTokens(
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }
}

/// Short-lived OAuth 2.0 tokens for direct API use (no-backend).
class OAuthTokens {
  const OAuthTokens({this.idToken, this.accessToken});

  final String? idToken;
  final String? accessToken;
}
