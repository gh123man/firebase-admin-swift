import XCTest
import JWTKit
import AnyCodable
@testable import Firebase

final class AuthPayloadsTests: XCTestCase {
    private struct TestAlgorithm: JWTAlgorithm {
        let name = "test"

        func sign<Plaintext>(_ plaintext: Plaintext) throws -> [UInt8] where Plaintext: DataProtocol {
            []
        }

        func verify(_ signature: some DataProtocol, signs plaintext: some DataProtocol) throws -> Bool {
            true
        }
    }

    private func makePayload(
        issuedAt: Date,
        authTime: Date,
        expirationAt: Date
    ) -> FirebaseJWTPayload {
        FirebaseJWTPayload(
            issuer: .init(value: "https://securetoken.google.com/test-project"),
            issuedAt: .init(value: issuedAt),
            expirationAt: .init(value: expirationAt),
            audience: .init(value: ["test-project"]),
            subject: .init(value: "user-123"),
            authTime: authTime,
            userID: "user-123",
            email: "user@example.com",
            picture: nil,
            name: nil,
            isEmailVerified: true,
            phoneNumber: nil,
            firebase: FirebaseContext(
                signInProvider: "password",
                tenant: nil,
                identities: [:]
            )
        )
    }

    func testPayloadAllowsClockSkewForIssuedAtAndAuthTime() async throws {
        let now = Date()
        let payload = makePayload(
            issuedAt: now.addingTimeInterval(20),
            authTime: now.addingTimeInterval(20),
            expirationAt: now.addingTimeInterval(60)
        )

        try await FirebaseJWTPayload.withVerificationClockSkew(30) {
            try await payload.verify(using: TestAlgorithm())
        }
    }

    func testPayloadAllowsClockSkewForRecentlyExpiredToken() async throws {
        let now = Date()
        let payload = makePayload(
            issuedAt: now.addingTimeInterval(-60),
            authTime: now.addingTimeInterval(-60),
            expirationAt: now.addingTimeInterval(-20)
        )

        try await FirebaseJWTPayload.withVerificationClockSkew(30) {
            try await payload.verify(using: TestAlgorithm())
        }
    }

    func testPayloadRejectsIssuedAtBeyondClockSkew() async throws {
        let now = Date()
        let payload = makePayload(
            issuedAt: now.addingTimeInterval(31),
            authTime: now.addingTimeInterval(-60),
            expirationAt: now.addingTimeInterval(60)
        )

        await XCTAssertThrowsErrorAsync {
            try await FirebaseJWTPayload.withVerificationClockSkew(30) {
                try await payload.verify(using: TestAlgorithm())
            }
        }
    }
}

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @escaping () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected expression to throw", file: file, line: line)
    } catch {
    }
}
