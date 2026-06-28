import '../../../core/api/proctoring_api_client.dart';

class FrameAnalysis {
  const FrameAnalysis({
    required this.isLooking,
    required this.hasIntruder,
    required this.hasDevice,
    required this.events,
  });

  final bool isLooking;
  final bool hasIntruder;
  final bool hasDevice;
  final List<Map<String, dynamic>> events;
}

abstract class ProctoringDatasource {
  Future<String?> startSession(String userId, int submissionId);
  Future<FrameAnalysis?> sendFrame(String sessionId, String frameB64);
  Future<Map<String, dynamic>?> endSession(String sessionId);
}

class RemoteProctoringDatasource implements ProctoringDatasource {
  RemoteProctoringDatasource(this._client);
  final ProctoringApiClient _client;

  @override
  Future<String?> startSession(String userId, int submissionId) async {
    final res = await _client.post('/api/session/start', {
      'usuario_id': userId,
      'submission_id': submissionId,
    });
    return res?['session_id'] as String?;
  }

  @override
  Future<FrameAnalysis?> sendFrame(String sessionId, String frameB64) async {
    final res = await _client.post('/api/frame', {
      'session_id': sessionId,
      'frame_b64': frameB64,
    });
    if (res == null) return null;
    return FrameAnalysis(
      isLooking: res['mirando'] as bool? ?? true,
      hasIntruder: res['hay_intruso'] as bool? ?? false,
      hasDevice: res['hay_dispositivo'] as bool? ?? false,
      events: (res['eventos'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          [],
    );
  }

  @override
  Future<Map<String, dynamic>?> endSession(String sessionId) async {
    final res = await _client.post(
      '/api/session/end',
      {'session_id': sessionId},
    );
    return res?['reporte'] as Map<String, dynamic>?;
  }
}
