// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_bridge.dart';

// **************************************************************************
// BridgeContractGenerator
// **************************************************************************

// ignore_for_file: unused_element, unnecessary_cast, unused_import, unused_field, require_trailing_commas

const BridgeDescriptor _$KycBridgeDescriptor = BridgeDescriptor(
  name: 'KycBridge',
  channel: 'nativeflow/kyc',
  version: 1,
  codec: BridgeCodecKind.json,
  platforms: <BridgePlatformTarget>[
    BridgePlatformTarget.android,
    BridgePlatformTarget.ios,
    BridgePlatformTarget.macos,
    BridgePlatformTarget.windows,
    BridgePlatformTarget.linux,
  ],
  methods: <BridgeMethodDescriptor>[
    BridgeMethodDescriptor(
      name: 'startSession',
      returnType: 'Future<KycSession>',
      transport: BridgeTransport.methodChannel,
      timeoutMilliseconds: null,
      parameters: <BridgeParameterDescriptor>[
        BridgeParameterDescriptor(
          name: 'userId',
          type: 'String',
          isRequired: true,
          isNullable: false,
        ),
      ],
    ),
    BridgeMethodDescriptor(
      name: 'submitDocument',
      returnType: 'Future<KycResult>',
      transport: BridgeTransport.methodChannel,
      timeoutMilliseconds: 90000000,
      parameters: <BridgeParameterDescriptor>[
        BridgeParameterDescriptor(
          name: 'type',
          type: 'KycDocumentType',
          isRequired: true,
          isNullable: false,
        ),
      ],
    ),
    BridgeMethodDescriptor(
      name: 'cancelSession',
      returnType: 'Future<void>',
      transport: BridgeTransport.methodChannel,
      timeoutMilliseconds: null,
      parameters: <BridgeParameterDescriptor>[],
    ),
  ],
  events: <BridgeEventDescriptor>[
    BridgeEventDescriptor(
      name: 'stepChanged',
      payloadType: 'KycStep',
      replay: 1,
      bufferSize: 16,
    ),
  ],
  errors: <BridgeErrorDescriptor>[
    BridgeErrorDescriptor(
      code: 'kyc_cancelled',
      dartType: 'KycCancelledException',
    ),
    BridgeErrorDescriptor(
      code: 'kyc_session_expired',
      dartType: 'KycSessionExpiredException',
    ),
  ],
);

final class _$KycBridgeClient implements KycBridge {
  _$KycBridgeClient({
    BridgeClient? client,
    BridgeSerializerRegistry? serializers,
  }) : _client =
           client ??
           BridgeClient(
             descriptor: _$KycBridgeDescriptor,
             codec: const JsonBridgeCodec(),
             serializers: serializers,
             errorMapper: _buildErrorMapper(),
           );

  final BridgeClient _client;

  @override
  Future<KycSession> startSession(String userId) {
    return _client.invoke<KycSession>(
      'startSession',
      arguments: <String, Object?>{'userId': userId},
      timeout: null,
    );
  }

  @override
  Future<KycResult> submitDocument(KycDocumentType type) {
    return _client.invoke<KycResult>(
      'submitDocument',
      arguments: <String, Object?>{'type': type},
      timeout: const Duration(milliseconds: 90000000),
    );
  }

  @override
  Future<void> cancelSession() {
    return _client.invoke<void>(
      'cancelSession',
      arguments: null,
      timeout: null,
    );
  }

  @override
  Stream<KycStep> stepChanged() {
    return _client.events<KycStep>('stepChanged');
  }

  static BridgeErrorMapper _buildErrorMapper() {
    final mapper = BridgeErrorMapper.fromDescriptor(_$KycBridgeDescriptor);
    mapper.register('kyc_cancelled', (error, stackTrace) {
      try {
        return KycCancelledException();
      } on NoSuchMethodError {
        return BridgePlatformException(
          error.message ?? 'KycCancelledException reported.',
          code: error.code,
          details: error.details,
          cause: error,
          stackTrace: stackTrace,
        );
      }
    });
    mapper.register('kyc_session_expired', (error, stackTrace) {
      try {
        return KycSessionExpiredException();
      } on NoSuchMethodError {
        return BridgePlatformException(
          error.message ?? 'KycSessionExpiredException reported.',
          code: error.code,
          details: error.details,
          cause: error,
          stackTrace: stackTrace,
        );
      }
    });
    return mapper;
  }
}

const String _$KycBridgeKotlinContract = r"""
package nativeflow.generated

import kotlinx.coroutines.flow.Flow

interface KycBridgeNativeBridge {
  suspend fun startSession(userId: String): Map<String, Any?>
  suspend fun submitDocument(type: Map<String, Any?>): Map<String, Any?>
  suspend fun cancelSession(): Unit
  fun stepChanged(): Flow<Map<String, Any?>>
}

object KycBridgeErrors {
  const val KYC_CANCELLED = "kyc_cancelled"
  const val KYC_SESSION_EXPIRED = "kyc_session_expired"
}

""";
const String _$KycBridgeSwiftContract = r"""
import Combine
import Foundation

protocol KycBridgeNativeBridge {
  func startSession(userId: String) async throws -> [String: Any?]
  func submitDocument(type: [String: Any?]) async throws -> [String: Any?]
  func cancelSession() async throws -> Void
  func stepChanged() -> AnyPublisher<[String: Any?], Error>
}

enum KycBridgeErrors {
  static let kycCancelled = "kyc_cancelled"
  static let kycSessionExpired = "kyc_session_expired"
}

""";
const String _$KycBridgeWindowsContract = r"""
// Auto-generated NativeFlow Bridge Windows contract.
#pragma once

#include <flutter/encodable_value.h>
#include <flutter/method_call.h>
#include <flutter/method_result.h>
#include <memory>
#include <string>

namespace nativeflow_generated {

class KycBridgeNativeBridge {
 public:
  virtual ~KycBridgeNativeBridge() = default;
  virtual void startSession(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) = 0;
  virtual void submitDocument(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) = 0;
  virtual void cancelSession(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) = 0;
};

} // namespace nativeflow_generated

""";
const String _$KycBridgeLinuxContract = r"""
// Auto-generated NativeFlow Bridge Linux contract.
#pragma once

#include <flutter_linux/flutter_linux.h>

typedef struct {
  const gchar* channel;
  void (*startSession)(FlMethodCall* call, FlMethodChannel* channel, gpointer user_data);
  void (*submitDocument)(FlMethodCall* call, FlMethodChannel* channel, gpointer user_data);
  void (*cancelSession)(FlMethodCall* call, FlMethodChannel* channel, gpointer user_data);
} KycBridgeNativeBridge;


""";
