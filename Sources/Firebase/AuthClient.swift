//
//  File.swift
//  
//
//  Created by Brian Floersch on 3/30/23.
//

import Foundation
import Vapor
import JWTKit

public actor AuthClient: Sendable {
    private let jwtCacheKey = "FirebaseTokenValidator_firebase_jwks_keys"
    
    let app: Application
    let api: ApiClient
    private var validationClockSkew: TimeInterval = .zero
    
    
    init(app: Application, api: ApiClient) {
        self.app = app
        self.api = api
    }

    public func configureValidation(clockSkew: TimeInterval = .zero) {
        validationClockSkew = max(0, clockSkew)
    }

    public func configureValidation(clockSkew: Duration) {
        configureValidation(clockSkew: clockSkew.timeInterval)
    }
    
    public func validate(idToken: String) async throws -> FirebaseJWTPayload {
        guard let config = await api.config else {
            throw Abort(.internalServerError, reason: "Config required")
        }
        
        let result: FirebaseJWTPayload
        do {
            result = try await verify(idToken: idToken)
        } catch {
            guard Self.shouldRetryVerification(after: error) else {
                throw error
            }

            // It's possible Google has rotated the JWT keys, so refresh the JWKS once
            // for signature and key lookup failures before returning the error.
            result = try await verify(idToken: idToken, forceRefresh: true)
        }
        
        try Self.validateStandardClaims(result, projectID: config.project_id)
        
        return result
    }
    
    private func verify(idToken: String, forceRefresh: Bool = false) async throws -> FirebaseJWTPayload {
        var jwks: JWKS? = try await app.cache.get(jwtCacheKey)
        
        if jwks == nil || forceRefresh {
            let googleCert = try await app.client.get("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com").get()
            jwks = try googleCert.content.decode(JWKS.self)
            if let jwks = jwks {
                try await app.cache.set(jwtCacheKey, to: jwks, expiresIn: .hours(24))
            }
        }
        
        guard let jwks = jwks else {
            throw Abort(.internalServerError, reason: "Failed to resovle Firebase JWKS keys")
        }
        
        let signers = JWTKeyCollection()
        try await signers.add(jwks: jwks)
        
        return try await FirebaseJWTPayload.withVerificationClockSkew(validationClockSkew) {
            try await signers.verify(idToken, as: FirebaseJWTPayload.self)
        }
    }
    
    public func getUser(uid: String) async throws -> FirebaseUser {
        let response = try await api.makeAuthenticatedPost(
            endpoint: try api.config.authEndpoint(.lookup),
            body: UserRequest(localId: uid))
        
        let userResponse: LookupResponse = try await api.decodeOrThrow(response: response)
        guard let user = userResponse.users?.first else {
            throw Abort(.internalServerError, reason: "User not found")
        }
        return user
    }
    
    public func getUsers() async throws -> [FirebaseUser] {
        let response = try await api.makeAuthenticatedPost(endpoint: try api.config.authEndpoint(.query))
        
        let usersResponse: UserList = try await api.decodeOrThrow(response: response)
        return usersResponse.userInfo
    }
    
    public func updateUser(user: FirebaseUser) async throws {
        let response = try await api.makeAuthenticatedPost(
            endpoint: try api.config.authEndpoint(.update),
            body: user)
        
        if response.status == .ok {
            return
        }
        
        try await api.throwIfError(response: response)
        throw Abort(.internalServerError, reason: "Could not parse response")
    }
    
    public func deleteUser(uid: String) async throws {
        let response = try await api.makeAuthenticatedPost(
            endpoint: try api.config.authEndpoint(.delete),
            body: UserRequest(localId: uid))
        
        if response.status == .ok {
            return
        }
        
        try await api.throwIfError(response: response)
        throw Abort(.internalServerError, reason: "Could not parse response")
    }

    static func validateStandardClaims(_ payload: FirebaseJWTPayload, projectID: String) throws {
        guard payload.audience.value.contains(projectID) else {
            throw JWTError.claimVerificationFailure(
                failedClaim: payload.audience,
                reason: "Audience must include the firebase project id."
            )
        }

        guard payload.issuer.value == expectedIssuer(for: projectID) else {
            throw JWTError.claimVerificationFailure(
                failedClaim: payload.issuer,
                reason: "Claim must be issued by Google and contain the project id."
            )
        }
    }

    static func expectedIssuer(for projectID: String) -> String {
        "https://securetoken.google.com/\(projectID)"
    }

    static func shouldRetryVerification(after error: Error) -> Bool {
        guard let jwtError = error as? JWTError else {
            return false
        }

        switch jwtError.errorType {
        case .unknownKID, .signatureVerificationFailed, .noKeyProvided:
            return true
        default:
            return false
        }
    }
}
