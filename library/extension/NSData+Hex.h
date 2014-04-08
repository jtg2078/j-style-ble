//
//  NSData+Hex.h
//  bluetooth
//
//  Created by jason on 4/9/14.
//  Copyright (c) 2014 jason. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Hex)

- (NSString *)hexRepresentationWithSpaces:(BOOL)spaces capitals:(BOOL)capitals;
- (NSArray *)hexInArray;

@end
