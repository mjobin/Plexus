//
//  PlexusCalculationOperation.h
//  Plexus
//
//  Created by Matthew Jobin on 9/28/11.
//  Copyright 2011 Santa Clara University. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenCL/opencl.h>


@interface PlexusCalculationOperation : NSObject {
    
    //CL Vars
    cl_int err;
    unsigned int num_devices;
    cl_device_id device_ids[256];
    cl_command_queue cl_queues[256];
    cl_ulong gMemSize, lMemSize, cMemSize;
    cl_device_fp_config fpconfig;
    size_t returned_size;
    cl_context       context;

    
    
    
    @private
    NSArray  *initialNodes;
    NSNumber *runs;
    NSNumber *burnins;
    NSNumber *computes;
    NSMutableArray *resultNodes;

}

- (id)initWithNodes:(NSArray *) inNodes withRuns:(NSNumber *) inRuns withBurnin:(NSNumber *) inBurnins withComputes:(NSNumber*) inComputes;
- (NSError *)calc:(NSProgressIndicator *)progInd withCurLabel:(NSTextField *)curLabel;
- (NSMutableArray *)getResults:(id)sender;



@end
