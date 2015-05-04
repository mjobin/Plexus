//
//  Bridging-Header.h
//  Plexus
//
//  Created by matt on 1/1/2015.
//  Copyright (c) 2015 Santa Clara University. All rights reserved.
//

#ifndef Plexus_Bridging_Header_h
#define Plexus_Bridging_Header_h


#import <CorePlot/CorePlot.h>
#import "CPTMutablePlotRange+SwiftCompat.h"
//#import "CPTXYAxis+SwiftCompat.h"
#import "PlexusCalculationOperation.h"



// A routine for generating good random numbers
extern double ran3(long *idum);

//returns gaussian deviates
double gasdev(long *idum);

//returns gamma deviates
extern double gamma_dev(double a);
extern double igamma_dev(int ia);

double beta_dev(double a, double b);


#endif
