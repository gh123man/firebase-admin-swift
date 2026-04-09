# Agent Guide

## What This Repo Is

This package is an unofficial Firebase admin client for Vapor. It wraps a small subset of Firebase Admin functionality:

- service-account OAuth token minting
- Firebase ID token validation
- basic user management
- FCM message sending

The package exposes a single product, `Firebase`, from [Package.swift](/Users/brian/dev/FirebaseVapor/Package.swift).

## Repo Layout

- [Sources/Firebase/FirebaseApi.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/FirebaseApi.swift)
  Public top-level actor exposed as `app.firebase` and `req.firebase`. Loads config and owns the auth and messaging clients.
- [Sources/Firebase/VaporExtensions.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/VaporExtensions.swift)
  Wires `FirebaseApi` into `Application` and `Request` storage.
- [Sources/Firebase/AuthClient.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/AuthClient.swift)
  Verifies Firebase ID tokens, fetches and caches Google JWKS, and provides user CRUD helpers.
- [Sources/Firebase/AuthPayloads.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/AuthPayloads.swift)
  JWT payload models for validated Firebase user tokens plus local claim verification rules.
- [Sources/Firebase/ApiClient.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/ApiClient.swift)
  Shared internal HTTP client for authenticated Firebase REST calls and service-account OAuth token caching.
- [Sources/Firebase/InternalPayloads.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/InternalPayloads.swift)
  Internal JWT payloads and OAuth token response models used to mint Google access tokens.
- [Sources/Firebase/Endpoints.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/Endpoints.swift)
  Firebase REST endpoint builders derived from the loaded service-account config.
- [Sources/Firebase/MessagingClient.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/MessagingClient.swift)
  FCM send entrypoint.
- [Sources/Firebase/MessagesPayloads.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/MessagesPayloads.swift)
  Codable request payloads for FCM.
- [Sources/Firebase/Config.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/Config.swift)
  Decoded `serviceAccountKey.json` shape.
- [Sources/Firebase/JsonExtensions.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/JsonExtensions.swift)
  JSON decoding helpers.
- [Sources/Firebase/Date+Extensions.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/Date+Extensions.swift)
  Small `TimeInterval` helpers used throughout the package.
- [Tests/FirebaseTests/AuthPayloadsTests.swift](/Users/brian/dev/FirebaseVapor/Tests/FirebaseTests/AuthPayloadsTests.swift)
  Tracked unit tests for JWT skew handling.

## Public Entry Points

Typical startup:

```swift
let serviceAccountKey: String = ...
try await app.firebase.loadConfig(from: serviceAccountKey, authClockSkew: .seconds(30))
```

Typical usage:

```swift
let payload = try await app.firebase.auth.validate(idToken: token)
let user = try await app.firebase.auth.getUser(uid: payload.userID)
try await app.firebase.messaging.send(message)
```

## How The Main Flows Work

### ID token validation

1. `AuthClient.validate(idToken:)` loads project config from `ApiClient`.
2. `AuthClient.verify(idToken:forceRefresh:)` fetches cached Google JWKS from `app.cache`.
3. If no keys are cached, it downloads Firebase JWKS from Google and caches them for 24 hours.
4. `JWTKeyCollection.verify` checks the token signature and decodes `FirebaseJWTPayload`.
5. `FirebaseJWTPayload.verify(using:)` enforces local claim checks, including configurable clock skew.
6. `AuthClient.validate(idToken:)` then verifies `aud` and `iss` against the configured Firebase project.

### Authenticated Firebase REST calls

1. `ApiClient.makeAuthenticatedPost` asks for a Google OAuth access token.
2. `ApiClient.getOAuthToken` reuses a cached token when possible.
3. `ApiClient.getNewOAuthToken` signs a service-account JWT and exchanges it against Google OAuth.
4. The resulting bearer token is attached to Firebase REST requests.

## Testing

Useful commands:

```bash
swift test --filter AuthPayloadsTests
swift test
swift build
```

Notes:

- The tracked unit coverage currently lives in [Tests/FirebaseTests/AuthPayloadsTests.swift](/Users/brian/dev/FirebaseVapor/Tests/FirebaseTests/AuthPayloadsTests.swift).
- The repo also has an ignored file name, `FirebaseVaporTests.swift`, in `.gitignore`. That path has historically been used for local integration experiments and should not be relied on for tracked regression coverage.
- `swift test` emits a third-party warning from `multipart-kit` about `Docs.docc`. That warning is upstream and not caused by this package.

## Conventions And Gotchas

- `FirebaseApi`, `AuthClient`, and `MessagingClient` are `actor`s. Keep new async state changes actor-isolated.
- This package depends on `app.cache` for both Google JWKS and OAuth token reuse.
- When changing JWT validation, keep the package-level claim checks in [Sources/Firebase/AuthPayloads.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/AuthPayloads.swift) aligned with Firebase’s documented token rules.
- `Config` intentionally mirrors Google service-account JSON keys and uses snake_case to match the file format.
- Endpoint builders live in [Sources/Firebase/Endpoints.swift](/Users/brian/dev/FirebaseVapor/Sources/Firebase/Endpoints.swift); add new REST surfaces there instead of hard-coding URLs across clients.

## When Adding Features

- Add new public behavior through `FirebaseApi` or one of the existing client actors.
- Put request and response models in the payload files instead of embedding anonymous `Codable` types in clients.
- Add tracked tests in `Tests/FirebaseTests/`.
- Update [README.md](/Users/brian/dev/FirebaseVapor/README.md) when public initialization or usage changes.
- Prefer `Duration` for new public time-based APIs. This repo still accepts `TimeInterval` in some places for compatibility, but `Duration` is the better call-site type.
