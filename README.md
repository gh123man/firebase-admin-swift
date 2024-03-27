# Unofficial Firebase admin SDK for Swift

This repo implements (some of) the firebase API in swift for use in [Vapor](https://vapor.codes/) projects. This library uses the `serviceAccountKey.json` like the official libraries. Fetches the firebase admin OAuth token, validates user ID tokens, and more. 

## Usage

Add the package dependency to your `Package.swift`

```swift
.package(url: "https://github.com/gh123man/firebase-admin-swift", from: "0.0.1"),
...

.target(name: "App", dependencies: [
    .product(name: "Vapor", package: "vapor"),
    .product(name: "Firebase", package: "firebase-admin-swift")
])
```

In `configure.swift`

```swift
import Firebase

// Called before your application initializes.
func configure(_ app: Application) throws {
    let serviceAccountKey: String = // Load your serviceAccountKey.json file
    try app.firebase.loadConfig(from: serviceAccountKey)
}
```

In your app

```swift 

// Validate an ID token
let jwtResponse = try await app.firebase.auth.validate(idToken: token)

// Fetch all users
let users = try await app.firebase.auth.getUsers()

// Fetch a single user
let user = try await app.firebase.auth.getUser(uid: "abcdefg1234567")

// Delete a single user
try await app.firebase.auth.deleteUser(uid: "abcdefg1234567")

// Send an FCM message
try await app.firebase.messaging.send(FcmMessage(
    notification: FcmNotification(title: "foo", body: "bar"),
    token: "MY_TOKEN"))

```

Also works on `req.firebase`

## TODO

Only a few methods are implemented (see above), and several arguments/query parameters are missing. The ground work is done, so adding new methods should be fairly simple. Feel free to open an issue or PR. 


## Notes

- This library uses the `app.cache` to store tokens before they expire. 


