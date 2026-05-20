// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_bridge.dart';

// **************************************************************************
// BridgeContractGenerator
// **************************************************************************

// ignore_for_file: unused_element

const BridgeDescriptor _$PaymentBridgeDescriptor = BridgeDescriptor(
  name: 'PaymentBridge',
  channel: 'nativeflow/payments',
  version: 1,
  methods: <BridgeMethodDescriptor>[
    BridgeMethodDescriptor(
      name: 'pay',
      returnType: 'Future<PaymentResult>',
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
      timeoutMilliseconds: null,
      parameters: <BridgeParameterDescriptor>[],
    ),
  ],
  events: <BridgeEventDescriptor>[
    BridgeEventDescriptor(
      name: 'events',
      payloadType: 'PaymentEvent',
    ),
  ],
);

final class _$PaymentBridgeClient implements PaymentBridge {
  _$PaymentBridgeClient({BridgeClient? client})
      : _client = client ??
            BridgeClient(
              descriptor: _$PaymentBridgeDescriptor,
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
}

const String _$PaymentBridgeKotlinContract = r"""
package nativeflow.generated

import kotlinx.coroutines.flow.Flow

interface PaymentBridgeNativeBridge {
  suspend fun pay(request: Map<String, Any?>): Map<String, Any?>
  suspend fun cancelPayment(): Unit
  fun events(): Flow<Map<String, Any?>>
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

""";
