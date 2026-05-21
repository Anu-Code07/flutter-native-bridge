import 'package:nativeflow_bridge/core.dart';

/// Runtime registry for generated bridges, plugins, and DevTools inspection.
final class BridgeRegistry {
  BridgeRegistry._();

  static final BridgeRegistry instance = BridgeRegistry._();

  final Map<String, BridgeDescriptor> _descriptors =
      <String, BridgeDescriptor>{};
  final Map<String, Object> _plugins = <String, Object>{};

  Iterable<BridgeDescriptor> get descriptors => _descriptors.values;

  void registerDescriptor(BridgeDescriptor descriptor) {
    final existing = _descriptors[descriptor.channel];
    if (existing != null && existing.version != descriptor.version) {
      throw BridgeRegistrationException(
        'Bridge "${descriptor.channel}" already registered with version '
        '${existing.version}; attempted to register ${descriptor.version}.',
      );
    }
    _descriptors[descriptor.channel] = descriptor;
  }

  void registerPlugin(String name, Object plugin) {
    if (_plugins.containsKey(name)) {
      throw BridgeRegistrationException(
        'Bridge plugin "$name" has already been registered.',
      );
    }
    _plugins[name] = plugin;
  }

  T plugin<T extends Object>(String name) {
    final plugin = _plugins[name];
    if (plugin is! T) {
      throw BridgeRegistrationException(
        'Bridge plugin "$name" is not registered as $T.',
      );
    }
    return plugin;
  }
}
