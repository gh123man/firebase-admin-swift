//
//  File.swift
//  
//
//  Created by Brian Floersch on 3/28/23.
//

import Foundation
extension TimeInterval {
    static func seconds(_ val: Double) -> Self {
        return val
    }
    
    static func minutes(_ val: Double) -> Self {
        return val * .seconds(60)
    }
    
    static func hours(_ val: Double) -> Self {
        return val * .minutes(60)
    }
    
    static func days(_ val: Double) -> Self {
        return val * .hours(24)
    }
}
