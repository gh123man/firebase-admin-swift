//
//  File.swift
//  
//
//  Created by Brian Floersch on 3/26/23.
//

import Foundation
import Vapor


extension Request {
    public var firebase: FirebaseApi {
        return application.firebase
    }
}

extension Application {
    private struct Key: StorageKey, Sendable {
        typealias Value = FirebaseApi
    }
    
    public var firebase: FirebaseApi {
        if storage[Key.self] == nil {
            storage[Key.self] = FirebaseApi(app: self)
        }
        
        return storage[Key.self]!
    }
}
