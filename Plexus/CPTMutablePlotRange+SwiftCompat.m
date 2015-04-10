//
//  CPTMutablePlotRange+SwiftCompat.m
//  Plexus
//
//  Created by matt on 1/6/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

#import "CPTMutablePlotRange+SwiftCompat.h"

@implementation CPTMutablePlotRange (SwiftCompat)


- (void)setLengthFloat:(float)lengthFloat
{
    NSNumber *number = [NSNumber numberWithFloat:lengthFloat];
    [self setLength:number];
}


@end
