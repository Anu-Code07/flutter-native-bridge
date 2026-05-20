# nativeflow_bridge_annotations

Annotations for declaring type-safe NativeFlow Bridge contracts in Dart.

Use this package in domain or shared API packages where you define bridge
interfaces. It has no Flutter dependency and is consumed by
`nativeflow_bridge_generator`.

## Usage

```dart
import 'package:nativeflow_bridge_annotations/nativeflow_bridge_annotations.dart';

@Bridge(channel: 'payments')
abstract class PaymentBridge {
  Future<void> cancelPayment();
}
```

## Maintainer

Maintained by Anurag in the
[flutter-native-bridge](https://github.com/Anu-Code07/flutter-native-bridge)
repository.
