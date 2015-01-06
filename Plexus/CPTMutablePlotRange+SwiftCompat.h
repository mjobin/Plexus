//
//  CPTMutablePlotRange+SwiftCompat.h
//  Plexus
//
//  Created by matt on 1/6/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <CorePlot/CPTMutablePlotRange.h>

@interface CPTMutablePlotRange (SwiftCompat)

- (void)setLengthFloat:(float)lengthFloat;

@end
