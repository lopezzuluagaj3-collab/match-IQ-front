import 'dart:html' as html;

class CameraCapture {
  html.VideoElement? _video;
  html.CanvasElement? _canvas;
  html.MediaStream? _stream;
  bool _initialized = false;

  Future<bool> initialize() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) return false;

      _stream = await mediaDevices.getUserMedia({
        'video': {'width': 320, 'height': 240, 'facingMode': 'user'},
        'audio': false,
      });

      _video = html.VideoElement()
        ..srcObject = _stream
        ..autoplay = true
        ..muted = true
        ..style.position = 'fixed'
        ..style.top = '-9999px'
        ..style.left = '-9999px'
        ..style.width = '1px'
        ..style.height = '1px';
      html.document.body?.append(_video!);
      _canvas = html.CanvasElement(width: 320, height: 240);

      // Let the video element start streaming before first capture
      await Future.delayed(const Duration(milliseconds: 800));
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  String? captureFrame() {
    if (!_initialized || _video == null || _canvas == null) return null;
    try {
      _canvas!.context2D.drawImageScaled(_video!, 0, 0, 320, 240);
      final dataUrl = _canvas!.toDataUrl('image/jpeg', 0.6);
      final idx = dataUrl.indexOf(',');
      return idx == -1 ? null : dataUrl.substring(idx + 1);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _initialized = false;
    _stream?.getTracks().forEach((t) => t.stop());
    _video?.remove();
    _video = null;
    _canvas = null;
    _stream = null;
  }
}
