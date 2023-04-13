//
//  Util.swift
//  Trombone Champ Mod Manager
//
//  Created by Andrew Glaze on 4/13/23.
//

import Foundation

extension URL {
    @available(macOS 11.0, *)
    func path(percentEncoded: Bool = true) -> String {
        return path
    }
    
    @available(macOS 11.0, *)
    func appending<S>(path: S) -> URL where S : StringProtocol {
        appendingPathComponent(String(path))
    }
    
    @available(macOS 11.0, *)
    mutating func append<S>(path: S) where S : StringProtocol {
        appendPathComponent(String(path))
    }
}
