//
//  File.swift
//  
//
//  Created by Brian Floersch on 3/30/23.
//

import Foundation
import Vapor

// MARK: Auth
enum AuthEndpoint: String {
    case query = "accounts:query"
    case delete = "accounts:delete"
    case lookup = "accounts:lookup"
}

extension Config {
    func authEndpoint(_ path: AuthEndpoint) -> URI {
        return "https://identitytoolkit.googleapis.com/v1/projects/\(project_id)/\(path.rawValue)"
    }
    
    func messagingEndpoint() -> URI {
        return "https://fcm.googleapis.com/v1/projects/\(project_id)/messages:send"
    }
}

extension Optional<Config> {
    func authEndpoint(_ path: AuthEndpoint) throws -> URI {
        guard let cfg = self else {
            throw Abort(.internalServerError, reason: "Config required")
        }
        return cfg.authEndpoint(path)
    }
    
    func messagingEndpoint() throws -> URI {
        guard let cfg = self else {
            throw Abort(.internalServerError, reason: "Config required")
        }
        return cfg.messagingEndpoint()
    }
}

// MARK: messages
enum MessagesEndpoint: String {
    case send = "messages:query"
}

extension Config {
    func messagesEndpoint(_ path: MessagesEndpoint) -> URI {
        return "https://fcm.googleapis.com/v1/projects/\(project_id)/\(path.rawValue)"
    }
}

extension Optional<Config> {
    func messagesEndpoint(_ path: MessagesEndpoint) throws -> URI {
        guard let cfg = self else {
            throw Abort(.internalServerError, reason: "Config required")
        }
        return cfg.messagesEndpoint(path)
    }
}
