//
//  File.swift
//  
//
//  Created by Brian Floersch on 3/28/23.
//

import Foundation

struct Config: Codable {
    let type: String
    let project_id: String
    let private_key_id: String
    let private_key: String
    let client_email: String
    let client_id: String
    let auth_uri: String
    let token_uri: String
    let auth_provider_x509_cert_url: String
    let client_x509_cert_url: String
}
