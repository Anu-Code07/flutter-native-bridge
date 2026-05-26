// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_bridge.dart';

// **************************************************************************
// BridgeContractGenerator
// **************************************************************************

// ignore_for_file: unused_element, unnecessary_cast, unused_import, unused_field, require_trailing_commas

const BridgeDescriptor _$PaymentBridgeDescriptor = BridgeDescriptor(
  name: 'PaymentBridge',
  channel: 'nativeflow/payments',
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
      name: 'pay',
      returnType: 'Future<PaymentResult>',
      transport: BridgeTransport.methodChannel,
      timeoutMilliseconds: null,
      parameters: <BridgeParameterDescriptor>[
        BridgeParameterDescriptor(
          name: 'request',
          type: 'PaymentRequest',
          isRequired: true,
          isNullable: false,
        ),
      ],
    ),
    BridgeMethodDescriptor(
      name: 'cancelPayment',
      returnType: 'Future<void>',
      transport: BridgeTransport.methodChannel,
      timeoutMilliseconds: null,
      parameters: <BridgeParameterDescriptor>[],
    ),
  ],
  events: <BridgeEventDescriptor>[
    BridgeEventDescriptor(
      name: 'events',
      payloadType: 'PaymentEvent',
      replay: 1,
      bufferSize: 128,
    ),
  ],
  errors: <BridgeErrorDescriptor>[
    BridgeErrorDescriptor(
      code: 'payment_cancelled',
      dartType: 'PaymentCancelledException',
    ),
  ],
);

final class _$PaymentBridgeClient implements PaymentBridge {
  _$PaymentBridgeClient({
    BridgeClient? client,
    BridgeSerializerRegistry? serializers,
  }) : _client =
           client ??
           BridgeClient(
             descriptor: _$PaymentBridgeDescriptor,
             codec: const JsonBridgeCodec(),
             serializers: serializers,
             errorMapper: _buildErrorMapper(),
           );

  final BridgeClient _client;

  @override
  Future<PaymentResult> pay(PaymentRequest request) {
    return _client.invoke<PaymentResult>(
      'pay',
      arguments: <String, Object?>{'request': request},
      timeout: null,
    );
  }

  @override
  Future<void> cancelPayment() {
    return _client.invoke<void>(
      'cancelPayment',
      arguments: null,
      timeout: null,
    );
  }

  @override
  Stream<PaymentEvent> events() {
    return _client.events<PaymentEvent>('events');
  }

  static BridgeErrorMapper _buildErrorMapper() {
    final mapper = BridgeErrorMapper.fromDescriptor(_$PaymentBridgeDescriptor);
    mapper.register('payment_cancelled', (error, stackTrace) {
      try {
        return PaymentCancelledException();
      } on NoSuchMethodError {
        return BridgePlatformException(
          error.message ?? 'PaymentCancelledException reported.',
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

const String _$PaymentBridgeKotlinContract = r"""
package nativeflow.generated

import kotlinx.coroutines.flow.Flow

interface PaymentBridgeNativeBridge {
  suspend fun pay(request: Map<String, Any?>): Map<String, Any?>
  suspend fun cancelPayment(): Unit
  fun events(): Flow<Map<String, Any?>>
}

object PaymentBridgeErrors {
  const val PAYMENT_CANCELLED = "payment_cancelled"
}

""";
const String _$PaymentBridgeSwiftContract = r"""
import Combine
import Foundation

protocol PaymentBridgeNativeBridge {
  func pay(request: [String: Any?]) async throws -> [String: Any?]
  func cancelPayment() async throws -> Void
  func events() -> AnyPublisher<[String: Any?], Error>
}

enum PaymentBridgeErrors {
  static let paymentCancelled = "payment_cancelled"
}

""";
const String _$PaymentBridgeWindowsContract = r"""
// Auto-generated NativeFlow Bridge Windows contract.
#pragma once

#include <flutter/encodable_value.h>
#include <flutter/method_call.h>
#include <flutter/method_result.h>
#include <memory>
#include <string>

namespace nativeflow_generated {

class PaymentBridgeNativeBridge {
 public:
  virtual ~PaymentBridgeNativeBridge() = default;
  virtual void pay(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) = 0;
  virtual void cancelPayment(const flutter::EncodableValue& arguments, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) = 0;
};

} // namespace nativeflow_generated

""";
const String _$PaymentBridgeLinuxContract = r"""
// Auto-generated NativeFlow Bridge Linux contract.
#pragma once

#include <flutter_linux/flutter_linux.h>

typedef struct {
  const gchar* channel;
  void (*pay)(FlMethodCall* call, FlMethodChannel* channel, gpointer user_data);
  void (*cancelPayment)(FlMethodCall* call, FlMethodChannel* channel, gpointer user_data);
} PaymentBridgeNativeBridge;


""";
