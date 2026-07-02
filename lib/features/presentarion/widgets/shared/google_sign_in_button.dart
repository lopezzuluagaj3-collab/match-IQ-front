import 'dart:async';

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
  // `GoogleSignIn.instance.initialize()` may only be called once per app
  // lifetime (calling it again throws "init() has already been called").
  // This widget gets remounted whenever the login page is (re)built — e.g.
  // after a logout — so the initialization itself is memoized here, shared
  // across every instance/remount, while event subscriptions stay per-widget.
  static Future<void>? _initializeFuture;
  static bool _initializeFailed = false;

  bool _ready = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Web needs `clientId`; native platforms need `serverClientId` (there's
    // no google-services.json / GoogleService-Info.plist checked in), or
    // initialize() throws a client configuration error. Passing
    // `serverClientId` on web instead trips an assertion in
    // google_sign_in_web, so the two are mutually exclusive by platform.
    _initializeFuture ??= GoogleSignIn.instance
        .initialize(
      clientId: kIsWeb ? GoogleAuthConstants.clientId : null,
      serverClientId: kIsWeb ? null : GoogleAuthConstants.clientId,
    )
        .catchError((Object e, StackTrace stack) {
      _initializeFailed = true;
      debugPrint('[GoogleSignIn] initialize() failed: $e');
      if (e is GoogleSignInException) {
        debugPrint(
            '[GoogleSignIn] code=${e.code} description=${e.description}');
      }
      debugPrintStack(stackTrace: stack);
    });

    await _initializeFuture;
    if (_initializeFailed) {
      widget.onError('No se pudo inicializar el inicio de sesión con Google.');
    } else {
      _subscription = GoogleSignIn.instance.authenticationEvents.listen(
        _handleEvent,
        onError: _handleError,
      );
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _authenticate() async {
    try {
      await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e, stack) {
      debugPrint(
          '[GoogleSignIn] authenticate() failed: code=${e.code} description=${e.description}');
      debugPrintStack(stackTrace: stack);
      if (e.code != GoogleSignInExceptionCode.canceled) {
        widget.onError('No se pudo iniciar sesión con Google.');
      }
    } catch (e, stack) {
      debugPrint('[GoogleSignIn] authenticate() failed: $e');
      debugPrintStack(stackTrace: stack);
      widget.onError('No se pudo iniciar sesión con Google.');
    }
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
    debugPrint('[GoogleSignIn] authenticationEvents error: $error');
    if (error is GoogleSignInException) {
      debugPrint(
          '[GoogleSignIn] code=${error.code} description=${error.description}');
    }
    widget.onError('No se pudo iniciar sesión con Google.');
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _initializeFailed) {
      return const SizedBox(height: 40);
    }
    if (kIsWeb) {
      return SizedBox(width: double.infinity, child: web.renderButton());
    }
    if (GoogleSignIn.instance.supportsAuthenticate()) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _authenticate,
          icon: const Icon(Icons.g_mobiledata),
          label: const Text('Continuar con Google'),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
