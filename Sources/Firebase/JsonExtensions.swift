//
//  File.swift
//  
//
//  Created by Brian Floersch on 3/28/23.
//

import Foundation
extension Encodable {
    var json: String? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

extension Data {
    func fromJson<T: Decodable>() -> T? {
        return try? JSONDecoder().decode(T.self, from: self)
    }
}

extension String {
    func jsonDecoded<T: Decodable>() throws -> T? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
