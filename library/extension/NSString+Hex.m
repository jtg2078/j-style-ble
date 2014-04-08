//
//  NSString+Hex.m
//  bluetooth
//
//  Created by jason on 4/9/14.
//  Copyright (c) 2014 jason. All rights reserved.
//

#import "NSString+Hex.h"

@implementation NSString (Hex)

- (NSString *)hexToDecimal
{
    NSScanner* scanner = [NSScanner scannerWithString:self];
    unsigned int outVal;
    [scanner scanHexInt:&outVal];
    
    return [NSString stringWithFormat:@"%d", outVal];
}

@end
