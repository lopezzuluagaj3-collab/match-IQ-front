import 'dart:async';
import 'dart:html' as html;

class FullscreenService {
  StreamSubscription<html.Event>? _sub;

  bool get isFullscreen => html.document.fullscreenElement != null;

  void enter() {
    try {
      html.document.documentElement?.requestFullscreen();
    } catch (_) {}
  }

  void exit() {
    try {
      if (isFullscreen) html.document.exitFullscreen();
    } catch (_) {}
  }

  void onExitFullscreen(void Function() callback) {
    _sub?.cancel();
    _sub = html.document.onFullscreenChange.listen((_) {
      if (!isFullscreen) callback();
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    exit();
  }
}
