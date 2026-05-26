import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'bridge_timeline.dart';

/// Registers VM-service extensions that expose [BridgeInspector] data to
/// external clients (Dart DevTools, the NativeFlow Bridge DevTools extension,
/// or custom tooling).
///
/// The registered methods are namespaced under `ext.nativeflow_bridge.*` and
/// are only registered in non-release builds.
final class BridgeDevToolsService {
  BridgeDevToolsService._();

  static bool _registered = false;

  /// Idempotently registers the service extensions.
  static void register({BridgeInspector? inspector}) {
    if (kReleaseMode || _registered) {
      return;
    }
    _registered = true;
    final target = inspector ?? BridgeInspector.instance;

    developer.registerExtension(
      'ext.nativeflow_bridge.timeline',
      (String method, Map<String, String> parameters) async {
        return developer.ServiceExtensionResponse.result(target.exportJson());
      },
    );

    developer.registerExtension(
      'ext.nativeflow_bridge.stats',
      (String method, Map<String, String> parameters) async {
        return developer.ServiceExtensionResponse.result(
          _encode(target.stats.map((stat) => stat.toJson()).toList()),
        );
      },
    );

    developer.registerExtension(
      'ext.nativeflow_bridge.clear',
      (String method, Map<String, String> parameters) async {
        target.clear();
        return developer.ServiceExtensionResponse.result('{"cleared": true}');
      },
    );

    developer.registerExtension(
      'ext.nativeflow_bridge.config',
      (String method, Map<String, String> parameters) async {
        final enabled = parameters['enabled'];
        if (enabled != null) {
          target.isEnabled = enabled == 'true';
        }
        final capturePayloads = parameters['capturePayloads'];
        if (capturePayloads != null) {
          target.capturePayloads = capturePayloads == 'true';
        }
        final broadcast = parameters['vmServiceBroadcast'];
        if (broadcast != null) {
          target.vmServiceBroadcast = broadcast == 'true';
        }
        return developer.ServiceExtensionResponse.result(
          _encode(<String, Object?>{
            'enabled': target.isEnabled,
            'capturePayloads': target.capturePayloads,
            'vmServiceBroadcast': target.vmServiceBroadcast,
          }),
        );
      },
    );
  }

  static String _encode(Object? value) => jsonEncode(value);
}
