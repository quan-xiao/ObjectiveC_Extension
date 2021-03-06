//
//  NSDateFormatter+Extension.m
//  ObjectiveC_Extension
//
//  Created by Vitor Marques de Miranda on 21/07/17.
//  Copyright © 2017 Vitor Marques de Miranda. All rights reserved.
//

#import "NSDateFormatter+Extension.h"

@implementation NSDateFormatter (VMMDateFormatter)

+(nullable NSDate*)dateFromString:(nonnull NSString *)string withFormat:(nonnull NSString*)format
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:format];
    return [df dateFromString:string];
}

@end
