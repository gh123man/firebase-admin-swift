//
//  File.swift
//  
//
//  Created by Brian Floersch on 3/26/24.
//

import Foundation
import Vapor

public actor MessagingClient: Sendable {
    let app: Application
    let api: ApiClient
    var config: Config?
    
    
    init(app: Application, api: ApiClient) {
        self.app = app
        self.api = api
    }
    
    // Possible errors: https://firebase.google.cn/docs/reference/fcm/rest/v1/ErrorCode
    public func send(_ message: FcmMessage, dryRun: Bool = false) async throws {
        let response = try await api.makeAuthenticatedPost(
            endpoint: try api.config.messagingEndpoint(),
            body: FcmRequest(validateOnly: dryRun, message: message))
        
        if response.status == .ok {
            return
        }
        try await api.throwIfError(response: response)
        throw Abort(.internalServerError, reason: "Could not parse error response")
    }
}
