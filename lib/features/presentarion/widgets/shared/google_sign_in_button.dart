import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import '../../../../core/api/api_constants.dart';

/// Renders Google's own "Sign in with Google" UI and reports the resulting
/// ID token upward. On web the sign-in SDK requires its own rendered button
/// (FedCM/GIS restriction) rather than a custom button triggering `authenticate()`.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onSignedIn,
    required this.onError,
  });

  final void Function(String idToken, String email) onSignedIn;
  final void Function(String message) onError;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final signIn = GoogleSignIn.instance;
    try {
      await signIn.initialize(clientId: GoogleAuthConstants.clientId);
      signIn.authenticationEvents.listen(_handleEvent).onError(_handleError);
    } catch (_) {
      widget.onError('No se pudo inicializar el inicio de sesión con Google.');
    }
    if (mounted) setState(() => _ready = true);
  }

  void _handleEvent(GoogleSignInAuthenticationEvent event) {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;
    final idToken = event.user.authentication.idToken;
    if (idToken == null) {
      widget.onError('Google no devolvió un token válido.');
      return;
    }
    widget.onSignedIn(idToken, event.user.email);
  }

  void _handleError(Object error) {
    widget.onError('No se pudo iniciar sesión con Google.');
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(height: 40);
    }
    if (kIsWeb) {
      return SizedBox(width: double.infinity, child: web.renderButton());
    }
    if (GoogleSignIn.instance.supportsAuthenticate()) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => GoogleSignIn.instance.authenticate(),
          icon: const Icon(Icons.g_mobiledata),
          label: const Text('Continuar con Google'),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
