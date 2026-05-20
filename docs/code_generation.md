# Code generation pipeline

```mermaid
flowchart TB
  A[Dart source files] --> B[build_runner asset graph]
  B --> C[source_gen LibraryReader]
  C --> D[Annotation scanner]
  D --> E[BridgeContract model]
  E --> F[Dart proxy emitter]
  E --> G[Descriptor emitter]
  E --> H[Kotlin contract emitter]
  E --> I[Swift contract emitter]
```

## Analyzer rules

The generator validates:

- `@Bridge` targets are abstract classes.
- Bridge operations are abstract instance methods.
- Stream operations return `Stream<T>`.
- Event stream operations do not currently accept parameters.

## Generated Dart

The Dart emitter creates:

- `BridgeDescriptor` constants for runtime registration and DevTools.
- private client implementations such as `_$PaymentBridgeClient`.
- method invocations through `BridgeClient.invoke<T>()`.
- event stream access through `BridgeClient.events<T>()`.

Application code owns the public abstraction. Generated code owns transport
binding.

## Native contracts

The first-generation emitter produces Kotlin and Swift protocol/interface
contracts as generated strings. The next step is a dedicated builder that writes
native files into platform source sets while keeping the Dart asset graph
incremental and deterministic.
