import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../infrastructure/datasources/proctor_datasource.dart';

enum ProctorStatus { idle, starting, monitoring, ended, error }

class ProctorState extends Equatable {
  const ProctorState({
    this.status = ProctorStatus.idle,
    this.sessionId,
    this.isLooking = true,
    this.hasIntruder = false,
    this.hasDevice = false,
    this.distractionCount = 0,
    this.intruderCount = 0,
    this.deviceCount = 0,
    this.finalReport,
    this.error,
  });

  final ProctorStatus status;
  final String? sessionId;

  /// true = candidate is looking at the screen (mirando)
  final bool isLooking;

  /// hay_intruso: another person detected in frame
  final bool hasIntruder;

  /// hay_dispositivo: prohibited device (phone, etc.) detected
  final bool hasDevice;

  final int distractionCount;
  final int intruderCount;
  final int deviceCount;

  /// Populated after endSession() — full report from /api/session/end
  final Map<String, dynamic>? finalReport;
  final String? error;

  ProctorState copyWith({
    ProctorStatus? status,
    String? sessionId,
    bool? isLooking,
    bool? hasIntruder,
    bool? hasDevice,
    int? distractionCount,
    int? intruderCount,
    int? deviceCount,
    Map<String, dynamic>? finalReport,
    String? error,
  }) =>
      ProctorState(
        status: status ?? this.status,
        sessionId: sessionId ?? this.sessionId,
        isLooking: isLooking ?? this.isLooking,
        hasIntruder: hasIntruder ?? this.hasIntruder,
        hasDevice: hasDevice ?? this.hasDevice,
        distractionCount: distractionCount ?? this.distractionCount,
        intruderCount: intruderCount ?? this.intruderCount,
        deviceCount: deviceCount ?? this.deviceCount,
        finalReport: finalReport ?? this.finalReport,
        error: error,
      );

  @override
  List<Object?> get props => [
        status,
        sessionId,
        isLooking,
        hasIntruder,
        hasDevice,
        distractionCount,
        intruderCount,
        deviceCount,
        finalReport,
        error,
      ];
}

class ProctorCubit extends Cubit<ProctorState> {
  ProctorCubit(this._datasource) : super(const ProctorState());

  final ProctoringDatasource _datasource;

  Future<void> startSession(String userId, int submissionId) async {
    emit(state.copyWith(status: ProctorStatus.starting));
    final sessionId = await _datasource.startSession(userId, submissionId);
    if (isClosed) return;
    if (sessionId == null) {
      emit(state.copyWith(
        status: ProctorStatus.error,
        error: 'Proctoring session could not be started',
      ));
      return;
    }
    emit(state.copyWith(status: ProctorStatus.monitoring, sessionId: sessionId));
  }

  Future<void> processFrame(String frameB64) async {
    final sessionId = state.sessionId;
    if (sessionId == null || state.status != ProctorStatus.monitoring) return;

    final result = await _datasource.sendFrame(sessionId, frameB64);
    if (isClosed || result == null) return;

    emit(state.copyWith(
      isLooking: result.isLooking,
      hasIntruder: result.hasIntruder,
      hasDevice: result.hasDevice,
      distractionCount:
          result.isLooking ? state.distractionCount : state.distractionCount + 1,
      intruderCount:
          result.hasIntruder ? state.intruderCount + 1 : state.intruderCount,
      deviceCount:
          result.hasDevice ? state.deviceCount + 1 : state.deviceCount,
    ));
  }

  /// Ends the proctoring session. The Python backend stores the report
  /// and the .NET backend exposes it via GET /api/tests/submissions/{matchId}/proctoring.
  Future<void> endSession() async {
    final sessionId = state.sessionId;
    if (sessionId == null || state.status == ProctorStatus.ended) return;
    emit(state.copyWith(status: ProctorStatus.ended));
    final report = await _datasource.endSession(sessionId);
    if (isClosed) return;
    emit(state.copyWith(finalReport: report));
  }
}
