//
//  File.swift
//  
//
//  Created by Brian Floersch on 3/28/23.
//

import Foundation
import Vapor
import JWT

struct OAuthTokenResponse: Codable {
    static let cacheKey = "OauthTokenResponse"
    let access_token: String
    let expires_in: Int
    let token_type: String
}

struct TokenFormRequest: Codable {
    var grant_type: String
    var assertion: String
}

struct FirebaseAdminAuthPayload: JWTPayload {
    
    enum CodingKeys: String, CodingKey {
        case expiration = "exp"
        case audience = "aud"
        case algorithm = "alg"
        case issuer = "iss"
        case issuedAt = "iat"
        case scope = "scope"
    }
    
    var scope: String 
    var issuer: IssuerClaim
    var algorithm = "RS256"
    var issuedAt: IssuedAtClaim = .init(value: Date())
    var audience: AudienceClaim
    var expiration: ExpirationClaim = .init(value: Date().addingTimeInterval(.seconds(1000)))
    
    func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
