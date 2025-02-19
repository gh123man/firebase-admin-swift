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
    
    public func loadConfig(from json: String) async throws {
        config = try json.jsonDecoded()
        await api.setConfig(config)
    }
    
}




