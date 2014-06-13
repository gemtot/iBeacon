//
//  PKUUID.m
//  GemTotSDK
//
//  Copyright (c) 2014 PassKit, Inc.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.


#import "PKUUID.h"

// The CommonCrypto library has not been ported to Swift so for now, this funciton class remains in Objective-C

@implementation PKUUID

/**
 *
 *  @brief   Parses an NSString and if the string supplied is a valid UUID, it is returned,
 *           else, the a type 5 UUID is returned using a fixed namespace seed
 *
 *  @param   UUIDNameOrString - the UUID to be checked or string to be hashed
 *
 *  @return  NSString - a string that contains a valid UUID
 *
 */

+ (NSString *) UUIDforString:(NSString *)UUIDNameOrString {
    
    NSRange range = [UUIDNameOrString rangeOfString:@"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[1-5][0-9A-Fa-f]{3}-[89ABab][0-9A-Fa-f]{3}-[0-9A-Fa-f]{12}$" options:NSRegularExpressionSearch];
    
    if (range.location != NSNotFound && [UUIDNameOrString length] == 36) {
        return UUIDNameOrString;
    }
    
    NSString *uuidString;
    int16_t count = 16 + [UUIDNameOrString length];
    
    char *hashNS = (char *)calloc(count + 1, sizeof(char));
    
    // Unique Namespace - equal to namespace in core PassKit code
    NSString *nameSpace = @"b8672a1f84f54e7c97bdff3e9cea6d7a";
    
    char byte_chars[3] = {'\0','\0','\0'};
    int i; int x =0;
    for (i=0; i < [nameSpace length]/2; i++) {
        byte_chars[0] = [nameSpace characterAtIndex:i*2];
        byte_chars[1] = [nameSpace characterAtIndex:i*2+1];
        hashNS[x] = strtol(byte_chars, NULL, 16);
        x++;
    }
    
    for (i=0; i < [UUIDNameOrString length]; i++) {
        hashNS[x] = [UUIDNameOrString characterAtIndex:i];
        x++;
    }
    
    NSString *hashedString = [self sha1:hashNS];
    
    free(hashNS);
    
    NSScanner *uuidPart3 = [NSScanner scannerWithString:[hashedString substringWithRange:NSMakeRange(12, 4)]];
    NSScanner *uuidPart4 = [NSScanner scannerWithString:[hashedString substringWithRange:NSMakeRange(16, 4)]];
    unsigned part3 = 0; unsigned part4 = 0;
    [uuidPart3 scanHexInt:&part3];
    [uuidPart4 scanHexInt:&part4];
    
    uuidString = [NSString stringWithFormat:@"%@-%@-%04x-%04x-%12@",
                  
                  // 32 bits for "time_low"
                  [hashedString substringWithRange:NSMakeRange(0, 8)],
                  
                  // 16 bits for "time_mid"
                  [hashedString substringWithRange:NSMakeRange(8, 4)],
                  
                  // 16 bits for "time_hi_and_version",
                  // four most significant bits holds version number 5
                  (part3 & 0x0FFF) | 0x5000,
                  
                  // 16 bits, 8 bits for "clk_seq_hi_res",
                  // 8 bits for "clk_seq_low",
                  // two most significant bits holds zero and one for variant DCE1.1
                  (part4 & 0x3fff) | 0x8000,
                  
                  // 48 bits for "node"
                  [hashedString substringWithRange:NSMakeRange(20, 12)]];
    
    return uuidString;
}

+ (NSString *)sha1:(char *)cStr {
    //const char *cStr = [str UTF8String];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cStr, (int16_t)strlen(cStr), result);
    NSString *s = [NSString  stringWithFormat:
                   @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   result[0], result[1], result[2], result[3], result[4],
                   result[5], result[6], result[7],
                   result[8], result[9], result[10], result[11], result[12],
                   result[13], result[14], result[15],
                   result[16], result[17], result[18], result[19]
                   ];
    
    return s;
}

@end
