import XCTest
import AnyCodable
import JWTKit
@testable import Firebase

final class AuthClientTests: XCTestCase {
    private func makePayload(
        audience: [String] = ["test-project"],
        issuer: String = AuthClient.expectedIssuer(for: "test-project"),
        subject: String = "user-123"
    ) -> FirebaseJWTPayload {
        FirebaseJWTPayload(
            issuer: .init(value: issuer),
            issuedAt: .init(value: .distantPast),
            expirationAt: .init(value: .distantFuture),
            audience: .init(value: audience),
            subject: .init(value: subject),
            authTime: .distantPast,
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

    func testValidateStandardClaimsAcceptsMatchingProjectIDAnywhereInAudience() throws {
        let payload = makePayload(audience: ["another-project", "test-project"])

        XCTAssertNoThrow(try AuthClient.validateStandardClaims(payload, projectID: "test-project"))
    }

    func testValidateStandardClaimsRejectsMissingAudience() throws {
        let payload = makePayload(audience: ["another-project"])

        XCTAssertThrowsError(try AuthClient.validateStandardClaims(payload, projectID: "test-project")) { error in
            guard let jwtError = error as? JWTError else {
                return XCTFail("Expected JWTError")
            }
            XCTAssertEqual(jwtError.errorType, .claimVerificationFailure)
            XCTAssertEqual(jwtError.reason, "Audience must include the firebase project id.")
        }
    }

    func testValidateStandardClaimsRejectsMismatchedIssuer() throws {
        let payload = makePayload(issuer: "https://securetoken.google.com/another-project")

        XCTAssertThrowsError(try AuthClient.validateStandardClaims(payload, projectID: "test-project")) { error in
            guard let jwtError = error as? JWTError else {
                return XCTFail("Expected JWTError")
            }
            XCTAssertEqual(jwtError.errorType, .claimVerificationFailure)
            XCTAssertEqual(jwtError.reason, "Claim must be issued by Google and contain the project id.")
        }
    }

    func testShouldRetryVerificationOnlyForKeyLookupAndSignatureFailures() {
        XCTAssertTrue(AuthClient.shouldRetryVerification(after: JWTError.unknownKID(.init(string: "kid"))))
        XCTAssertTrue(AuthClient.shouldRetryVerification(after: JWTError.signatureVerificationFailed))
        XCTAssertTrue(AuthClient.shouldRetryVerification(after: JWTError.noKeyProvided))

        XCTAssertFalse(
            AuthClient.shouldRetryVerification(
                after: JWTError.claimVerificationFailure(
                    failedClaim: SubjectClaim(value: ""),
                    reason: "bad subject"
                )
            )
        )
        XCTAssertFalse(AuthClient.shouldRetryVerification(after: JWTError.malformedToken(reason: "bad token")))
    }
}
