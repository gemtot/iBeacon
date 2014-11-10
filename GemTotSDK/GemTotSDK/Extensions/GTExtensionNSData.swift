//
//  GTNSData.swift
//  GemTotSDK
//
//  Created by Nick Murray on 21/8/14.
//  Copyright (c) 2014 PassKit, Inc. All rights reserved.
// 

import Foundation

// NSData extension to SHA1 Hash

extension NSData {
    func sha1() -> String! {
        let str = self.bytes
        let digestLen = Int(CC_SHA1_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        CC_SHA1(str, CC_LONG(self.length), result)
        var hash = String()
        for i in 0..<digestLen {
            hash += String(format: "%02x", result[i])
        }
        result.destroy()
        return String(format: hash)
    }
}