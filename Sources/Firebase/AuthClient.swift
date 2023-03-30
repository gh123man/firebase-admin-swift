//
//  File.swift
//  
//
//  Created by Brian Floersch on 3/30/23.
//

import Foundation
import Vapor
import JWT

public class AuthClient {
    private let jwtCacheKey = "FirebaseTokenValidator_firebase_jwks_keys"
    
    let app: Application
    let api: ApiClient
    var config: Config?
    
    
    init(app: Application, api: ApiClient) {
        self.app = app
        self.api = api
    }
    
    public func validate(idToken: String) async throws -> FirebaseJWTPayload {
        guard let config = config else {
            throw Abort(.internalServerError, reason: "Config required")
        }
        
        var jwks: JWKS? = try await app.cache.get(jwtCacheKey)
        
        if jwks == nil {
            let googleCert = try await app.client.get("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com").get()
            jwks = try googleCert.content.decode(JWKS.self)
            if let jwks = jwks {
                try await app.cache.set(jwtCacheKey, to: jwks, expiresIn: .hours(24))
            }
        }
        
        guard let jwks = jwks else {
            throw Abort(.internalServerError, reason: "Failed to resovle Firebase JWKS keys")
        }
        
        let signers = JWTSigners()
        try signers.use(jwks: jwks)
        
        let result = try signers.verify(idToken, as: FirebaseJWTPayload.self)
        
        guard result.audience.value.first == config.project_id else {
            throw JWTError.generic(identifier: "aud", reason: "Audience must be equal to the firebase project id.")
        }
        
        guard let url = URL(string: result.issuer.value),
              let expectedUrl = URL(string: "https://securetoken.google.com/\(config.project_id)"),
                url == expectedUrl else {
            throw JWTError.generic(identifier: "iss", reason: "Claim must be issued by google and contain the project id")
        }
        
        return result
    }
    
    public func getUser(uid: String) async throws -> FirebaseUser {
        let response = try await api.makeAuthenticatedPost(
            endpoint: try config.authEndpoint(.lookup),
            body: UserRequest(localId: uid))
        
        let userResponse: LookupResponse = try api.decodeOrThrow(response: response)
        guard let user = userResponse.users?.first else {
            throw FirebaseError(code: nil, message: "NOT_FOUND") // TODO: Improve this?
        }
        return user
    }
    
    public func getUsers() async throws -> [UserRecord] {
        let response = try await api.makeAuthenticatedPost(endpoint: try config.authEndpoint(.query))
        
        let usersResponse: UserList = try api.decodeOrThrow(response: response)
        return usersResponse.userInfo
    }
    
    public func deleteUser(uid: String) async throws {
        let response = try await api.makeAuthenticatedPost(
            endpoint: try config.authEndpoint(.delete),
            body: UserRequest(localId: uid))
        
        if response.status == .ok {
            return
        }
        
        if let error = try? response.content.decode(FirebaseErrorResponse.self) {
            throw error.error
        }
        throw Abort(.internalServerError, reason: "Could not parse response")
    }
}
