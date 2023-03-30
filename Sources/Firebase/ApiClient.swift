//
//  File.swift
//  
//
//  Created by Brian Floersch on 3/30/23.
//

import Foundation
import Vapor
import JWT

class ApiClient {
    
    let app: Application
    var config: Config?
    
    init(app: Application) {
        self.app = app
    }
    
    func decodeOrThrow<T: Codable>(response: ClientResponse) throws -> T {
        if let decoded = try? response.content.decode(T.self) {
            return decoded
        }
        if let error = try? response.content.decode(FirebaseError.self) {
            throw error
        }
        throw Abort(.internalServerError, reason: "Could not parse response")
    }
    
    func makeAuthenticatedPost(endpoint: URI, body: Codable? = nil) async throws -> ClientResponse {
        let token = try await getOAuthToken()
        
        return try await app.client.post(endpoint, beforeSend: {
            $0.headers.contentType = .json
            $0.headers.bearerAuthorization = BearerAuthorization(token: token.access_token)
            if let body = body {
                $0.body = ByteBuffer(data: try JSONEncoder().encode(body))
            }
        }).get()
    }
    
    func getOAuthToken() async throws -> OAuthTokenResponse {
        if let token: OAuthTokenResponse = try await app.cache.get(OAuthTokenResponse.cacheKey) {
            return token
        }
        let newToken = try await getNewOAuthToken()
        try await app.cache.set(OAuthTokenResponse.cacheKey, to: newToken, expiresIn: .seconds(newToken.expires_in - 10))
        return newToken
    }
    
    func getNewOAuthToken() async throws -> OAuthTokenResponse {
        guard let config = config else {
            throw Abort(.internalServerError, reason: "Config required")
        }
        
        let scopes = "https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/devstorage.full_control https://www.googleapis.com/auth/firebase https://www.googleapis.com/auth/identitytoolkit https://www.googleapis.com/auth/userinfo.email"
        
        let privateKey = try RSAKey.private(pem: config.private_key)
        let signers = JWTSigners()
        signers.use(.rs256(key: privateKey), kid: JWKIdentifier(string: config.private_key_id))
        
        let jwt = try signers.sign(FirebaseAdminAuthPayload(
            scope: scopes,
            issuer: .init(stringLiteral: config.client_email),
            audience: .init(stringLiteral: config.token_uri))
        )
        
        let oauthResponse = try await app.client.post("\(config.token_uri)", beforeSend: {
            $0.headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
            $0.headers.bearerAuthorization = BearerAuthorization(token: jwt)
            $0.body = ByteBuffer(string: try URLEncodedFormEncoder().encode(TokenFormRequest(grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: jwt)))
        }).get()
        
        guard let parsed = try? oauthResponse.content.decode(OAuthTokenResponse.self) else {
            throw FirebaseError(code: nil, message: "Could not get OAuth token")
        }
        return parsed
    }
}
