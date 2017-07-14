//
//  GTNSData.swift
//  GemTotSDK
//
//  Created by Nick Murray on 21/8/14.
//  Copyright (c) 2014 PassKit, Inc. All rights reserved.
// 

import Foundation

// NSData extension to SHA1 Hash

extension Data {
    func sha1() -> String! {
        let str = (self as NSData).bytes
        let digestLen = Int(CC_SHA1_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_SHA1(str, CC_LONG(self.count), result)
        var hash = String()
        for i in 0..<digestLen {
            hash += String(format: "%02x", result[i])
        }
        result.deinitialize()
        return String(format: hash)
    }
}

extension NSMutableData{
    func sha1() -> String! {
        let str = (self as NSData).bytes
        let digestLen = Int(CC_SHA1_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_SHA1(str, CC_LONG(self.length), result)
        var hash = String()
        for i in 0..<digestLen {
            hash += String(format: "%02x", result[i])
        }
        result.deinitialize()
        return String(format: hash)
    }
}
