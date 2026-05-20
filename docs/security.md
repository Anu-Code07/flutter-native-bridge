# Security model

NativeFlow Bridge treats bridge contracts as a trust boundary. Generated and
runtime code should validate payload shape before invoking native SDKs.

## Controls

- Stable channel namespaces avoid accidental cross-plugin collisions.
- Descriptors include contract versions for compatibility checks.
- Typed exceptions prevent leaking arbitrary native exception objects.
- Custom serializers are the right place to redact sensitive fields.
- Permission checks belong in native adapters before starting platform work.

## Sensitive payloads

For tokens, payment secrets, health data, NFC payloads, or model prompts:

1. prefer opaque handles over raw values
2. avoid writing payloads to DevTools telemetry
3. encrypt persisted native state with platform keychain/keystore APIs
4. scope permissions to the bridge method that needs them
5. clear native buffers after FFI calls when the platform supports it

## DevTools redaction

DevTools integrations should record metadata by default:

- bridge name
- operation name
- payload size
- duration
- error code

Raw payload inspection should be opt-in and serializer-controlled.
