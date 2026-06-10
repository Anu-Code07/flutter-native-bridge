import 'dart:async';

import 'package:nativeflow_bridge/nativeflow_bridge.dart';

part 'kyc_bridge.g.dart';

/// Multi-step KYC flow where the native SDK owns the document-capture UI.
///
/// Flutter starts the session, listens to step transitions over an
/// `EventChannel`, and submits one document at a time over `MethodChannel`.
@Bridge(channel: 'nativeflow/kyc', version: 1)
abstract class KycBridge {
  Future<KycSession> startSession(String userId);

  @BridgeMethod(timeout: Duration(seconds: 90))
  Future<KycResult> submitDocument(KycDocumentType type);

  @BridgeEvent(name: 'stepChanged', replay: 1, bufferSize: 16)
  Stream<KycStep> stepChanged();

  Future<void> cancelSession();
}

enum KycDocumentType { passport, drivingLicence, idCard }

enum KycStepKind { intro, frontCapture, backCapture, selfie, review, done }

final class KycSession {
  const KycSession({required this.sessionId, required this.expiresAt});

  final String sessionId;
  final DateTime expiresAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'sessionId': sessionId,
    'expiresAt': expiresAt.toIso8601String(),
  };
}

final class KycResult {
  const KycResult({required this.documentId, required this.status});

  final String documentId;
  final KycResultStatus status;
}

enum KycResultStatus { accepted, rejected, pending }

final class KycStep {
  const KycStep({required this.kind, required this.message});

  final KycStepKind kind;
  final String message;
}

@BridgeError('kyc_cancelled')
final class KycCancelledException extends BridgeException {
  const KycCancelledException()
    : super('The customer cancelled the KYC flow.', code: 'kyc_cancelled');
}

@BridgeError('kyc_session_expired')
final class KycSessionExpiredException extends BridgeException {
  const KycSessionExpiredException()
    : super('The KYC session expired.', code: 'kyc_session_expired');
}
