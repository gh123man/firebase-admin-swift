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
    
    
    init(app: Application, api: ApiClient) {
        self.app = app
        self.api = api
    }
    
    public func validate(idToken: String) async throws -> FirebaseJWTPayload {
        guard let config = await api.config else {
            throw Abort(.internalServerError, reason: "Config required")
        }
        
        let result: FirebaseJWTPayload
        do {
            result = try await verify(idToken: idToken)
        } catch {
            // It's possible google has rotated the JWT keys, so if we get any kind of failure - let's try one more time without the cache.
            result = try await verify(idToken: idToken, forceRefresh: true)
        }
        
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
        
        return try await signers.verify(idToken, as: FirebaseJWTPayload.self)
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
}
