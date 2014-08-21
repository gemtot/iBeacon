//
//  String.swift
//  GemTotSDK
//
//  Created by Nick Murray on 21/8/14.
//  Copyright (c) 2014 PassKit, Inc. All rights reserved.
//

import Foundation

// String extension for SHA1 Hash
extension String {
        
    func GTsha1String() -> String {

        if let data = self.cStringUsingEncoding(NSISOLatin1StringEncoding) {

            // Convert String to C String for use with CC_SHA1 and create pointers for hash inputs and results
            let hashInputBytes = UnsafeMutablePointer<CUnsignedChar>(data)
            let hashResultBytes = UnsafeMutablePointer<CUnsignedChar>(NSMutableData(length: Int(CC_SHA1_DIGEST_LENGTH)).mutableBytes)

            // Hash using Common Crypto
            CC_SHA1(hashInputBytes, CC_LONG(countElements(self)), hashResultBytes)

            // Enumerate over result
            let resultEnumerator = UnsafeBufferPointer<CUnsignedChar>(start: hashResultBytes, count: Int(CC_SHA1_DIGEST_LENGTH))
            let SHA1 = NSMutableString()
            for c in resultEnumerator {
                SHA1.appendFormat("%02x", c)
            }

            return SHA1
        }

        // If no string or not decodable, return null
        return ""
    }
}