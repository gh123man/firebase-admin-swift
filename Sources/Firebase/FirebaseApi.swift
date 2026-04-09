//
//  File.swift
//  
//
//  Created by Brian Floersch on 3/26/23.
//

import Foundation
import Vapor
import JWTKit

public actor FirebaseApi: Sendable {
    
    private let app: Application
    private var config: Config?
    private let api: ApiClient
    
    public let auth: AuthClient
    public let messaging: MessagingClient
    
    public init(app: Application) {
        self.app = app
        self.api = ApiClient(app: app)
        self.auth = AuthClient(app: app, api: api)
        self.messaging = MessagingClient(app: app, api: api)
    }
    
    public func loadConfig(from json: String, authClockSkew: TimeInterval = .zero) async throws {
        config = try json.jsonDecoded()
        await api.setConfig(config)
        await auth.configureValidation(clockSkew: authClockSkew)
    }

    public func loadConfig(from json: String, authClockSkew: Duration) async throws {
        try await loadConfig(from: json, authClockSkew: authClockSkew.timeInterval)
    }

    public func configureAuthValidation(clockSkew: TimeInterval = .zero) async {
        await auth.configureValidation(clockSkew: clockSkew)
    }

    public func configureAuthValidation(clockSkew: Duration) async {
        await auth.configureValidation(clockSkew: clockSkew)
    }
    
}


