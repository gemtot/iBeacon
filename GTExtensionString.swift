//
//  GTExtensionString.swift
//  GemTotSDK
//
//  Created by Kapil Sachdeva on 10/6/15.
//  Copyright © 2015 PassKit, Inc. All rights reserved.
//

import Foundation

extension String {
    
    func stringByAppendingPathComponent(_ path: String) -> String {
        let nsSt = self as NSString
        return nsSt.appendingPathComponent(path)
    }
    
    func UUIDWithDashes()->String
    {
        guard self.characters.count == 32 else{
            return self
        }
        
        let uuidStringN : NSString = NSString(string: self)
        var components : [String] = []
        components.append(uuidStringN.substring(to: 8))
        components.append(uuidStringN.substring(with: NSMakeRange(8, 4)))
        components.append(uuidStringN.substring(with: NSMakeRange(12, 4)))
        components.append(uuidStringN.substring(with: NSMakeRange(16, 4)))
        components.append(uuidStringN.substring(from: 20))
        
        
        return components.joined(separator: "-").lowercased()
    }
}
