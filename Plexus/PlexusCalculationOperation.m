//
//  PlexusCalculationOperation.m
//  Plexus
//
//  Created by Matthew Jobin on 9/28/11.
//  Copyright 2011 Santa Clara University. All rights reserved.
//

#import "PlexusCalculationOperation.h"
#import "Plexus-Swift.h"

@implementation PlexusCalculationOperation

static void *ProgressObserverContext = &ProgressObserverContext;

- (id)init
{
    self = [super init];


    if(self) {
        
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:@"hardwareDevice" options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        noOpenCL = @{//1000
                     NSLocalizedDescriptionKey: NSLocalizedString(@"No available OpenCL devices", nil),
                     NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"No available OpenCL devices", nil),
                     NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Restart the program to reset", nil)
                     };
        
        noNode = @{//1001
                   NSLocalizedDescriptionKey: NSLocalizedString(@"No nodes in model", nil),
                   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"No nodes in model", nil),
                   NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Make sure that the model has at least one node before calculation", nil)
                   };
        
        kernelFail = @{//1002
                       NSLocalizedDescriptionKey: NSLocalizedString(@"OpenCL", nil),
                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The OpenCL Kernel has failed to build or enqueue", nil),
                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Restart the program to reset", nil)
                       };
        bufferFail = @{//1004
                       NSLocalizedDescriptionKey: NSLocalizedString(@"OpenCL", nil),
                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The OpenCL could not create a buffer", nil),
                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Restart the program to reset", nil)
                       };
        argFail = @{//1005
                    NSLocalizedDescriptionKey: NSLocalizedString(@"OpenCL", nil),
                    NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The OpenCL could not set one of its arguments", nil),
                    NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Restart the program to reset", nil)
                    };

        
        cptCalcFail = [NSMutableDictionary new]; //1006
        [cptCalcFail setObject:@"CPTCalc" forKey:NSLocalizedDescriptionKey];
        [cptCalcFail setObject:@"Check parameters for all nodes and Calculate again." forKey:NSLocalizedRecoverySuggestionErrorKey];
        
        cptInfFail = [NSMutableDictionary new]; //1007
        [cptCalcFail setObject:@"CPTCalc" forKey:NSLocalizedDescriptionKey];
        [cptCalcFail setObject:@"Node corrupt. Recreate dataset." forKey:NSLocalizedRecoverySuggestionErrorKey];
        
        cycleFail = [NSMutableDictionary new]; //1008
        [cycleFail setObject:@"Cycle" forKey:NSLocalizedDescriptionKey];
        [cycleFail setObject:@"Delete problem influences at node and check all nodes for cycles." forKey:NSLocalizedRecoverySuggestionErrorKey];
        

        
    }
    
   
    
    return self;
    
}




- (NSError *) clCompile

{


    NSError * calcerr = nil;
    

     
     NSUInteger devPref = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"hardwareDevice"] integerValue];
     //    NSLog(@"hw pref pref %lu", (unsigned long)devPref);
     
     
     if (devPref == 0) { //CPU
     err = clGetDeviceIDs(NULL, CL_DEVICE_TYPE_CPU, sizeof(device_ids), device_ids, &num_devices);
     if(err || num_devices <= 0)
         {
             calcerr = [NSError errorWithDomain:@"plexusCalc" code:1000 userInfo:noOpenCL];
             return calcerr;
         }
     }
     
     else if (devPref == 1) { //GPU
     
     err = clGetDeviceIDs(NULL, CL_DEVICE_TYPE_GPU, sizeof(device_ids), device_ids, &num_devices);
     if(err || num_devices <= 0)
     {
     
         err = clGetDeviceIDs(NULL, CL_DEVICE_TYPE_ALL, sizeof(device_ids), device_ids, &num_devices);
     
         if(err || num_devices <= 0)
         {
                calcerr = [NSError errorWithDomain:@"plexusCalc" code:1000 userInfo:noOpenCL];
                return calcerr;
         }
     
        }
     
     
     }
     
     else {//all types
     err = clGetDeviceIDs(NULL, CL_DEVICE_TYPE_ALL, sizeof(device_ids), device_ids, &num_devices);
     if(err || num_devices <= 0)
         {
             calcerr = [NSError errorWithDomain:@"plexusCalc" code:1000 userInfo:noOpenCL];
             return calcerr;
         }
     }
     
     
    the_device = device_ids[0];
    
     
     //create context
     context = clCreateContext(0, 1, &the_device, NULL, NULL, &err);
     if(!context || err)
     {
         NSLog(@"Failed to create openCL context!");
         return nil;
     }
     
     
    

    
    //Look for available devices and get their info
    

        
    //Check availability of the devices returned first
    cl_bool device_available;
    err = clGetDeviceInfo(the_device, CL_DEVICE_AVAILABLE, sizeof(cl_bool), &device_available, NULL);
    if(err)
    {
        NSLog(@"Device cannot be checked for availability");
    }
    
    //Test... what have we got here?
    char device_name[200];
    err = clGetDeviceInfo(the_device, CL_DEVICE_NAME, sizeof(device_name), device_name, NULL);
    if(err == CL_SUCCESS)
    {
        NSLog(@"%s reporting.", device_name);
    }
    
    //how much mem?
    
    err = clGetDeviceInfo(the_device, CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(cl_ulong), &gMemSize, NULL);
    if(err == CL_SUCCESS)
    {
        gMemSize /= (1024*1024);
        NSLog(@"Global memory %llu megabytes.", gMemSize);
    }
    
    err = clGetDeviceInfo(the_device, CL_DEVICE_LOCAL_MEM_SIZE, sizeof(cl_ulong), &lMemSize, NULL);
    if(err == CL_SUCCESS)
    {
        lMemSize /= (1024*1024);
        NSLog(@"Device local memory %llu megabytes.", lMemSize);
    }
    
    err = clGetDeviceInfo(the_device, CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE, sizeof(cl_ulong), &cMemSize, NULL);
    if(err == CL_SUCCESS)
    {
        cMemSize /= (1024*1024);
        NSLog(@"Constant memory %llu megabytes.", cMemSize);
    }
    
    
    
    err = clGetDeviceInfo(the_device, CL_DEVICE_DOUBLE_FP_CONFIG, sizeof(cl_device_fp_config), &fpconfig, NULL);
    if(err == CL_SUCCESS)
    {
        
        NSLog(@"Double FP config %llu.", fpconfig);
    }
    
    /*
    char device_extensions[2000];
    err = clGetDeviceInfo(the_device, CL_DEVICE_EXTENSIONS, sizeof(device_extensions), device_extensions, NULL);
    if(err == CL_SUCCESS)
    {
        NSLog(@"Extensions: %s.", device_extensions);
    }
    */
        
        
        
        
        
    
    
    cl_queue = clCreateCommandQueue(context, the_device, CL_QUEUE_PROFILING_ENABLE, &err); //chooses the first available of chosen devices
    
    if(!cl_queue || err)
    {
        NSLog(@"BN calc: Failed to create openCL queue!");
        return nil;
    }
    
    


    
    
    NSMutableData *sourceData = [[NSMutableData alloc] init];
    
    
    //Load the kernel
    NSData *bnData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"bn_kernel" ofType:@"cl"]];
    
    
    [sourceData appendData:bnData];
    
    const char *source = [sourceData bytes];
    size_t length = [sourceData length];
    
    //NSLog(@"source: %s", source);
    
        bn_program = clCreateProgramWithSource(context, 1, &source, &length, &err);
        if (!bn_program || err != CL_SUCCESS) {
            NSLog(@"BN Calc: Fail to create OpenCL program object. Error code: %i", err);
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1002 userInfo:kernelFail];
            return calcerr;
        }
        
        
        //get resource directory
        
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"bn_kernel" ofType:@"cl"];
        NSString *resourcesPath = [bundlePath stringByDeletingLastPathComponent];
        
        NSString *dashI = @"-I ";
        NSString *clOptionsLine = [dashI stringByAppendingString:resourcesPath];
        const char *ccCloptionsLine = [clOptionsLine cStringUsingEncoding:NSASCIIStringEncoding];
        

    //NSLog(@"ccoptions line %s", ccCloptionsLine);
    
    //Build executables

    
        err = clBuildProgram(bn_program, 1, &(the_device), ccCloptionsLine, NULL, NULL);
        if (err != CL_SUCCESS)
        {
            NSLog(@"BN Calc: Failed to build executable.Error code: %i", err);
            
            
            size_t len;
            

            
            // get the details on the error, and store it in buffer
            clGetProgramBuildInfo(
                                  bn_program,              // the program object being queried
                                  the_device,            // the device for which the OpenCL code was built
                                  CL_PROGRAM_BUILD_LOG, // specifies that we want the build log
                                  0,       // the size of the buffer
                                  NULL,               // on return, holds the build log
                                  &len);                // on return, the actual size in bytes of the
            //  error data returned
            
            char *buffer = calloc(len, sizeof(char));
            NSLog(@"buffer len %zu", len);
            
            clGetProgramBuildInfo(
                                  bn_program,              // the program object being queried
                                  the_device,            // the device for which the OpenCL code was built
                                  CL_PROGRAM_BUILD_LOG, // specifies that we want the build log
                                  sizeof(buffer),       // the size of the buffer
                                  buffer,               // on return, holds the build log
                                  &len);                // on return, the actual size in bytes of the
            
            NSLog(@"len %zu", len);
            NSLog(@"buffer %s", buffer);
            NSString *buf = [NSString stringWithCString:buffer encoding:4];
            NSLog(@"Build error message: %@", buf);
            
            NSDictionary *buildFail = @{
                                        NSLocalizedDescriptionKey: NSLocalizedString(@"OpenCL", nil),
                                        NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The OpenCL Kernel has failed to build as an executable.", nil),
                                        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(buf, nil)
                                        };
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1003 userInfo:buildFail];
            return calcerr;
        }
    
    
    return calcerr;
}

- (NSError *)calc:(NSProgressIndicator *)progInd withCurLabel:(NSTextField *)curLabel withWorkLabel:(NSTextField *)workLabel withNodes:(NSArray *) inNodes withRuns:(NSNumber *) inRuns withBurnin:(NSNumber *) inBurnins withComputes:(NSNumber*) inComputes
{
    NSError * calcerr = nil;
    
    initialNodes = inNodes;
    runs =inRuns;
    burnins = inBurnins;
    computes = inComputes;
    resultNodes = [NSMutableArray array];
    
    
    NSDate * startcalc = [NSDate date];
    
    

    
    
    unsigned int i;
    cl_kernel bncalc_Kernel;
    
    

    

    
    
    //*****************************
    //Create a read-only buffer for the initial node state
    //I know the total size of the nodes already
    NSUInteger INSize = [initialNodes count];
    NSLog(@"%lu initial nodes", INSize);
    
    
    NSUInteger maxCPTSize = 0;
    
    NSUInteger clRuns = [runs integerValue]; // to tranfer to buffer
    NSUInteger clBurnins = [burnins integerValue];
    
    //*****************************
    //Check to make sure the graph is acyclic
    //Advise deleting influences if not
    //This should no longer happen since cycles checked on adding influences
    for (BNNode * fNode in initialNodes) {
        if([fNode DFTcyclechk:[NSArray arrayWithObject:fNode]]){
            NSString * cycleFailNodeMesg = [[fNode nodeLink] name];
            NSString * cycleFailMesg = [cycleFailNodeMesg stringByAppendingString:@" is the start of a cycle of influences."];
            [cycleFail setObject:cycleFailMesg forKey:NSLocalizedFailureReasonErrorKey];
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1008 userInfo:cycleFail];
            return calcerr;
        }
    }
    
    
    
    //get maximum size of inputs and outputs
    
    
    for (BNNode * fNode in initialNodes) {
        NSArray * allInSet = [fNode infBy:self];
        if([allInSet count] > maxCPTSize) maxCPTSize = [allInSet count];
    }
    
    for (BNNode * fNode in initialNodes) {
        NSArray * allOutSet = [fNode infs:self];
        if([allOutSet count] > maxCPTSize) maxCPTSize = [allOutSet count];
    }
    
    if(maxCPTSize < 1){
        calcerr = [NSError errorWithDomain:@"plexusCalc" code:1001 userInfo:noNode];
        return calcerr;
        
    }; //so that we don't work with completely unlinked graphs
    
    //--------------------------------------CPT
    cl_int* infnet = malloc(sizeof(cl_int)*INSize*(maxCPTSize*2)); //size of whole list twice on x (influences and influenced by) and once on y (each node)
    
    NSLog(@"infnet size: %lu", (sizeof(cl_int[INSize*(maxCPTSize*2)])));
    NSLog(@"But %lu nodes (maxCPTSize) if we use the maximum input/output size of any node.", maxCPTSize);
    unsigned long sparseCPTsize = pow((double) 2.0, maxCPTSize);
    NSLog(@"And %lu CPT entries per node", sparseCPTsize);
    NSLog(@"So %lu CPT entries for all nodes", (sparseCPTsize*INSize));
    
    
    
    
    cl_float* cptnet = malloc(sizeof(cl_float)*INSize*sparseCPTsize);
    NSLog(@"cptnet size: %lu", sizeof(cl_float[INSize*sparseCPTsize]));
    
    
    
    double timer = [startcalc timeIntervalSinceNow] * -1000.0;
   // NSLog(@"Before getdeviceinfo %f since starting calc fxn", timer);
    
    int xoffset = 0;
    int cptoffset =0;
    int thisCPT =0;
    NSUInteger leftOver = 0;
    

    

    
    //copy in prior parameters, one for the type of distn, and two for its parameters
    cl_int* priorDistType = (cl_int *)malloc(sizeof(cl_int)*INSize);
    cl_float* priorV1 = (cl_float *)malloc(sizeof(cl_float)*INSize);
    cl_float* priorV2 = (cl_float *)malloc(sizeof(cl_float)*INSize);
    
    int prioroffset = 0;
    for (BNNode * fNode in initialNodes) {
        priorDistType[prioroffset] = [[fNode priorDistType] intValue];
        priorV1[prioroffset] = [[fNode priorV1] doubleValue];
        priorV2[prioroffset] = [[fNode priorV2] doubleValue];
        prioroffset++;
    }
    

    
    dispatch_async(dispatch_get_main_queue(), ^{
        workLabel.stringValue = [NSString stringWithFormat:@"Calculating CPTs"];
    });
    
    //Construct influences, CPT, fequencies
    //NSLog(@"construct influences");
    for (BNNode * fNode in initialNodes) {
        // NSLog(@"***************Node: %@", [[fNode nodeLink] name]);
        

        
        //------------- influenced by
        NSArray * theInfluencedBy = [fNode infBy:self];
        
        
        
        thisCPT =0;
        int nInfBy = 0;
        //NSLog(@"INFBY:");
        for (BNNode * inNode in theInfluencedBy) {
           // NSLog(@" %@", [[inNode nodeLink] name]);
            infnet[(xoffset+thisCPT)] = (cl_int)[initialNodes indexOfObject:inNode];
            nInfBy++;
            thisCPT++;
        }
        
        
        leftOver = maxCPTSize-thisCPT;
        
        for(i=0; i<leftOver; i++){
            //add dummy entries to pad out
            infnet[(xoffset+thisCPT)] = -1;
            thisCPT++;
        }
        
        xoffset += maxCPTSize;
        
        //------------- influences
        thisCPT =0;
        
      //  NSLog(@"INFS:");
        NSArray * theInfluences = [fNode infs:self];
        
        for (BNNode * outNode in theInfluences) {
           // NSLog(@" %@", [[outNode nodeLink] name]);
            infnet[(xoffset+thisCPT)] = (cl_int)[initialNodes indexOfObject:outNode];
            thisCPT++;
        }
        
        
        
        leftOver = maxCPTSize-thisCPT;
        
        for(i=0; i<leftOver; i++){
            //add dummy entries to pad out
            infnet[(xoffset+thisCPT)] = -1;
            thisCPT++;
        }
        
        xoffset += maxCPTSize;
        
        
        
        
        
        //----------- CPT of influenced by
        int sparseSize = (int) pow(2.0, nInfBy);
        if(nInfBy == 0) sparseSize = 0; //So we skip the next bit completely with no infuencedBy
        // NSLog(@"Number of cpt entries needed for this one %i", sparseSize);
        
        
        if(sparseSize > sparseCPTsize) NSLog(@"sparseSize over max!");
        

        
        NSArray * curcptnet = [fNode getCPTArray:self];
        for(i=0; i<curcptnet.count; i++){
            cptnet[(cptoffset+i)] = [curcptnet[i] floatValue];
        }

  
        //pad out if needed
        for(i=i; i<sparseCPTsize; i++){
            cptnet[(cptoffset+i)] = -1.0f;
        }
        
        
        
        cptoffset += sparseCPTsize;
        
        
    }
    
    
    
    
    
    if(bn_program == nil){
        NSLog(@"No bn_program, compiling now.");
        [self clCompile];
    }
    

  
    
    
    timer = [startcalc timeIntervalSinceNow] * -1000.0;
    NSLog(@"Before clCreateKernel %f since starting calc fxn", timer);
    
    bncalc_Kernel = clCreateKernel(bn_program, "BNGibbs", &err);
    if (!bncalc_Kernel || err != CL_SUCCESS) {
        NSLog(@"Couldn't find the function 'BNGibbs' in the program.");
        NSLog(@"error code: %i", err);
        calcerr = [NSError errorWithDomain:@"plexusCalc" code:1002 userInfo:kernelFail];
        return calcerr;
    }
    
    
    
    
    //SETUP LOOP
    size_t worksize;
    size_t bnreadsize;
    
    
    timer = [startcalc timeIntervalSinceNow] * -1000.0;
    NSLog(@"Before createbuffer %f since starting calc fxn", timer);
    
    
    
    
    //********************************
    // MAPPED BUFFER CREATION - ARG 1
    //********************************
    
    cl_mem paramsbuf = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_ALLOC_HOST_PTR, 4*sizeof(cl_int), 0, &err);
    if (!paramsbuf || err != CL_SUCCESS) {
        NSLog(@"BN calc: Failed to create params buffer!");
        calcerr = [NSError errorWithDomain:@"plexusCalc" code:1004 userInfo:bufferFail];
        return calcerr;
    }
    
    
    
    //********************************
    // MAPPED BUFFER CREATION - ARG 2
    //********************************
    //create the buffer for the freqs
    cl_mem freqbuf = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_ALLOC_HOST_PTR, sizeof(cl_float)*INSize, 0, &err);
    if (!freqbuf || err != CL_SUCCESS) {
        NSLog(@"BN calc: Failed to create initial frequencies buffer!");
        calcerr = [NSError errorWithDomain:@"plexusCalc" code:1004 userInfo:bufferFail];
        return calcerr;
    }
    
    //********************************
    //********************************
    
    
    
    //********************************
    // MAPPED BUFFER CREATION - ARG 3 - INFNET
    //********************************
    
    cl_mem infnetbuf = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_ALLOC_HOST_PTR, INSize*(maxCPTSize*2)*sizeof(cl_int), 0, &err);
    if (!infnetbuf || err != CL_SUCCESS) {
        NSLog(@"BN calc: Failed to create initial bn inf buffer!");
        calcerr = [NSError errorWithDomain:@"plexusCalc" code:1004 userInfo:bufferFail];
        return calcerr;
    }
    //********************************
    //********************************
    
    
    //********************************
    // MAPPED BUFFER CREATION - ARG 4 - CPTNET
    //********************************
    
    //create the buffer for the cpts
    cl_mem cptnetbuf = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_ALLOC_HOST_PTR, sizeof(cl_float)*INSize*sparseCPTsize, 0, &err);
    if (!cptnetbuf || err != CL_SUCCESS) {
        NSLog(@"BN calc: Failed to create initial cpt buffer!");
        calcerr = [NSError errorWithDomain:@"plexusCalc" code:1004 userInfo:bufferFail];
        return calcerr;
    }
    
    //********************************
    //********************************
    
    
    //********************************
    // MAPPED BUFFER CREATION - ARG 9 - PRIORDISTTYPE
    //********************************
    
    //create the buffer for priodisttype
    cl_mem priordisttypebuf = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_ALLOC_HOST_PTR, sizeof(cl_int)*INSize, 0, &err);
    if (!priordisttypebuf || err != CL_SUCCESS) {
        NSLog(@"BN calc: Failed to create prior dist type buffer!");
        calcerr = [NSError errorWithDomain:@"plexusCalc" code:1004 userInfo:bufferFail];
        return calcerr;
    }
    
    //********************************
    //********************************
    
    //********************************
    // MAPPED BUFFER CREATION - ARG 10 - PRIORV1s
    //********************************
    
    cl_mem priorv1buf = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_ALLOC_HOST_PTR, sizeof(cl_float)*INSize, 0, &err);
    if (!priorv1buf || err != CL_SUCCESS) {
        NSLog(@"BN calc: Failed to create prior v1 buffer!");
        calcerr = [NSError errorWithDomain:@"plexusCalc" code:1004 userInfo:bufferFail];
        return calcerr;
    }
    
    //********************************
    //********************************
    
    //********************************
    // MAPPED BUFFER CREATION - ARG 11 - PRIORV2s
    //********************************
    
    cl_mem priorv2buf = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_ALLOC_HOST_PTR, sizeof(cl_float)*INSize, 0, &err);
    if (!priorv2buf || err != CL_SUCCESS) {
        NSLog(@"BN calc: Failed to create prior v2 buffer!");
        calcerr = [NSError errorWithDomain:@"plexusCalc" code:1004 userInfo:bufferFail];
        return calcerr;
    }
    
    //********************************
    //********************************
    
    
    //********************************
    // MAPPING ONCE-ONLY BUFFERS
    //********************************
    


    
    timer = [startcalc timeIntervalSinceNow] * -1000.0;
   // NSLog(@"Before enqueuemapbuffers %f since starting calc fxn", timer);
    

        

    
    //********************************
    // MAPPED BUFFER CREATION - ARG 1 - PARAMS
    //********************************
    
    int * mappedParams = clEnqueueMapBuffer(cl_queue, paramsbuf, CL_TRUE, CL_MAP_READ, 0, 4*sizeof(cl_int), 0, NULL, NULL, NULL);
    mappedParams[0] = (int)INSize;
    mappedParams[1] = (int)maxCPTSize;
    mappedParams[2] = (int)clRuns;
    mappedParams[3] = (int)clBurnins;
    
    //********************************
    //********************************
    
    
    //********************************
    // MAPPED BUFFER CREATION - ARG 2 - INFNET
    //********************************
    
    // clEnqueueWriteBuffer(cl_queues[dev], infnetbuf, CL_TRUE, 0, INSize*(maxCPTSize*2)*sizeof(cl_int), (void*)infnet, 0, 0, 0);
    // infnetbufs[dev] = infnetbuf;
    
    
    int * mappedInfnet = clEnqueueMapBuffer(cl_queue, infnetbuf, CL_TRUE, CL_MAP_READ, 0, INSize*(maxCPTSize*2)*sizeof(cl_int), 0, NULL, NULL, NULL);
    
    for(i=0;i<(INSize*(maxCPTSize*2));i++){
        mappedInfnet[i] = infnet[i];
      //   NSLog(@"infnet %i", mappedInfnet[i]);
    }
    
    //********************************
    //********************************
    
    
    
    //********************************
    // MAPPED BUFFER CREATION - ARG 3 - CPTNET
    //********************************
    //  clEnqueueWriteBuffer(cl_queues[dev], cptnetbuf, CL_TRUE, 0, sizeof(cl_float)*INSize*sparseCPTsize, (void*)cptnet, 0, 0, 0);
    // cptnetbufs[dev] = cptnetbuf;
    
    float * mappedCptnet = clEnqueueMapBuffer(cl_queue, cptnetbuf, CL_TRUE, CL_MAP_READ, 0, sizeof(cl_float)*INSize*sparseCPTsize, 0, NULL, NULL, NULL);
    
    for(i=0;i<(INSize*sparseCPTsize);i++){
        mappedCptnet[i] = cptnet[i];
         //  NSLog(@"cptnet %f", mappedCptnet[i]);
    }
    
    //********************************
    //********************************
    

    
    //********************************
    // MAPPED BUFFER CREATION - ARG 8 - PRIORDISTTYPE
    //********************************
    
    //clEnqueueWriteBuffer(cl_queues[dev], priordisttypebuf, CL_TRUE, 0, sizeof(cl_int)*INSize, (void*)priorDistType, 0, 0, 0);
    //  priordisttypebufs[dev]=priordisttypebuf;
    
     int *mappedPriordisttype = clEnqueueMapBuffer(cl_queue, priordisttypebuf, CL_TRUE, CL_MAP_READ, 0, sizeof(cl_int)*INSize, 0, NULL, NULL, NULL);
    
    for(i=0;i<(INSize);i++){
        mappedPriordisttype[i] = priorDistType[i];
     //   NSLog(@"mappedPriordisttype %i", mappedPriordisttype[i]);
    }
    
    //********************************
    //********************************
    
    
    //********************************
    // MAPPED BUFFER CREATION - ARG 9 - PRIORV1s
    //********************************
    
    //  clEnqueueWriteBuffer(cl_queues[dev], priorv1buf, CL_TRUE, 0, sizeof(cl_float)*INSize, (void*)priorV1, 0, 0, 0);
    // priorv1bufs[dev]=priorv1buf;
    
    float * mappedPriorv1s = clEnqueueMapBuffer(cl_queue, priorv1buf, CL_TRUE, CL_MAP_READ, 0, sizeof(cl_float)*INSize, 0, NULL, NULL, NULL);
    
    for(i=0;i<(INSize);i++){
        mappedPriorv1s[i] = priorV1[i];
     //    NSLog(@"mappedPriorv1s %f", mappedPriorv1s[i]);
    }
    
    //********************************
    //********************************
    
    //********************************
    // MAPPED BUFFER CREATION - ARG 10 - PRIORV2s
    //********************************
    
    //clEnqueueWriteBuffer(cl_queues[dev], priorv2buf, CL_TRUE, 0, sizeof(cl_float)*INSize, (void*)priorV2, 0, 0, 0);
    //priorv2bufs[dev]=priorv2buf;
    
    float * mappedPriorv2s = clEnqueueMapBuffer(cl_queue, priorv2buf, CL_TRUE, CL_MAP_READ, 0, sizeof(cl_float)*INSize, 0, NULL, NULL, NULL);
    
    for(i=0;i<(INSize);i++){
        mappedPriorv2s[i] = priorV2[i];
      //   NSLog(@"mappedPriorv2s %f", mappedPriorv2s[i]);
    }
    
    //********************************
    //********************************
        
        
    
    size_t max_work_item_dims;
    err = clGetDeviceInfo(the_device, CL_DEVICE_DOUBLE_FP_CONFIG, sizeof(max_work_item_dims), &max_work_item_dims, &returned_size);
    
    
    
    
    size_t max_work_item_sizes[3];
    err = clGetDeviceInfo(the_device, CL_DEVICE_MAX_WORK_ITEM_SIZES, sizeof(max_work_item_sizes), max_work_item_sizes, &returned_size);
    for(size_t i=0;i<3;i++) {
        NSLog(@"Max Work Items in Dim %lu: %lu\n",(long unsigned)(i+1),(long unsigned)max_work_item_sizes[i]);
    }
    
    size_t kwBuf = 0;
    err = clGetKernelWorkGroupInfo(
                                   bncalc_Kernel,                      // the kernel object being queried
                                   the_device, // a device associated with the kernel object
                                   CL_KERNEL_WORK_GROUP_SIZE,    // requests the work-group size
                                   sizeof(kwBuf),             // size in bytes of return buffer
                                   &kwBuf,                    // on return, points to requested information
                                   &returned_size);
    
    NSLog(@"Kernel work group size for bn_kernel %lu", (long unsigned)kwBuf);
    
    //Figure out how many work items - use all initially
    size_t gWorkItems = max_work_item_sizes[0]*max_work_item_sizes[1]*max_work_item_sizes[2];
    
    
    if(gWorkItems > kwBuf) gWorkItems = kwBuf;
    //if(gWorkItems > [computes intValue]) gWorkItems = [computes intValue];
    
    //gWorkItems = 1;
    
    NSLog(@"work-group items %lu", (long unsigned)gWorkItems);
    worksize = gWorkItems;
    bnreadsize = worksize * [initialNodes count]; //All the memory needed to read one work units data

   // NSLog(@"computes %i  worksize %zu remainder %lu", [computes intValue], worksize, [computes intValue]%worksize);
    int numpasses = ([computes intValue] / worksize); //The number of passes with this device needed to

    if([computes intValue]%worksize != 0){
        numpasses++;
    }
    

    
    
    cl_int * offsetarrays[numpasses];
    cl_float * bnresultsarrays[numpasses];
    
     NSLog(@"bnreadsize: %zu worksize %zu computes %i numpasses %i", bnreadsize, worksize, [computes intValue], numpasses);
    

    NSMutableArray *passchk = [NSMutableArray arrayWithCapacity:numpasses];
    for(i=0; i<numpasses; i++){
        [passchk addObject:[NSNumber numberWithInt:i]];
    }

    
    timer = [startcalc timeIntervalSinceNow] * -1000.0;
   // NSLog(@"Before main queueing loop %f since starting calc fxn", timer);
    
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        workLabel.stringValue = [NSString stringWithFormat:@"Calculating Posteriors"];
    });
    
    BOOL firsttime = TRUE;
    //********************************
    // MAIN QUEUEING LOOP
    //********************************
    int ct =0;
    int tt = 0;

    
      cl_mem * bnresultsbufs = malloc(sizeof(cl_mem)*numpasses);
      cl_mem * offsetbufs = malloc(sizeof(cl_mem)*numpasses);
        cl_event * prof_events = malloc(sizeof(cl_event)*numpasses);

    
    while(ct < [computes intValue]){
        
        timer = [startcalc timeIntervalSinceNow] * -1000.0;
       // NSLog(@"Top of ct loop %f since starting calc fxn", timer);
    
            
    //    NSLog(@"******  tt is %i", tt);
        
        
        size_t thisWork = worksize;
        
        //    NSLog(@"worksize for this dev %lu", thisWork);
        
        size_t workRemaining = [computes intValue] - ct;
        
        //      NSLog(@"remaining work %lu", workRemaining);
        
        if (thisWork > workRemaining) thisWork = workRemaining;
        
        //   NSLog(@"worksize should now be %lu", thisWork);
        
        
        timer = [startcalc timeIntervalSinceNow] * -1000.0;
       // NSLog(@"Before offsets enqueue %f since starting calc fxn", timer);
        
        
        //********************************
        // MAPPED BUFFER CREATION - ARG 0 - OFFSET
        //********************************
        
        //create the buffer for RNG seeds
        cl_mem offsetbuf = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_ALLOC_HOST_PTR, worksize*sizeof(cl_int), 0, &err);
        if (!offsetbuf || err != CL_SUCCESS) {
            NSLog(@"BN calc: Failed to create initial rng offsets buffer!");
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1004 userInfo:bufferFail];
            return calcerr;
        }
        
        timer = [startcalc timeIntervalSinceNow] * -1000.0;
      //  NSLog(@"Before offsets enqueuemapbiuffer %f since starting calc fxn", timer);
        
        int * mappedOffsets = clEnqueueMapBuffer(cl_queue, offsetbuf, CL_FALSE, CL_MAP_READ, 0, worksize*sizeof(cl_int), 0, NULL, NULL, NULL);
        
        timer = [startcalc timeIntervalSinceNow] * -1000.0;
       // NSLog(@"Before offsets arcrandopm  %f since starting calc fxn", timer);
        for(i=0;i<worksize;i++){
            mappedOffsets[i] = arc4random();
            //  NSLog(@"offset %i", mappedOffsets[i]);
        }
        
        offsetbufs[tt] = offsetbuf;
        offsetarrays[tt] = mappedOffsets;
        
        //********************************
        //********************************
        
        
        timer = [startcalc timeIntervalSinceNow] * -1000.0;
      //  NSLog(@"Before results enqueue %f since starting calc fxn", timer);
        
        //********************************
        // MAPPED BUFFER CREATION - ARG 5 - BNRESULTS
        //********************************
        
        
        cl_mem bnresultsbuf = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_ALLOC_HOST_PTR, bnreadsize*sizeof(cl_float), 0, &err);
        if (!bnresultsbuf || err != CL_SUCCESS) {
            NSLog(@"BN calc: Failed to create initial bnresults buffer!");
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1004 userInfo:bufferFail];
            return calcerr;
        }
        
        float *mappedBNresults = clEnqueueMapBuffer(cl_queue, bnresultsbuf, CL_FALSE, CL_MAP_WRITE, 0, bnreadsize*sizeof(cl_float), 0, NULL, NULL, NULL);
        bnresultsbufs[tt] = bnresultsbuf;
        bnresultsarrays[tt] = mappedBNresults;

        
        //********************************
        //********************************
        

        
        timer = [startcalc timeIntervalSinceNow] * -1000.0;
      //  NSLog(@"Before set arguments %f since starting calc fxn", timer);
        
        //********************************
        //********************************
        
        
        //set args
        
        
        
        
        err = clSetKernelArg(bncalc_Kernel, 0, sizeof(cl_mem), (void*)&offsetbuf);
        if (err != CL_SUCCESS) {
            NSLog(@"Failure setting argument");
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1005 userInfo:argFail];
            return calcerr;
        }
        
        
        err = clSetKernelArg(bncalc_Kernel, 1, sizeof(cl_mem), (void*)&paramsbuf);
        if (err != CL_SUCCESS) {
            NSLog(@"Failure setting argument");
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1005 userInfo:argFail];
            return calcerr;
        }
        
        err = clSetKernelArg(bncalc_Kernel, 2, sizeof(cl_mem), (void*)&infnetbuf);
        if (err != CL_SUCCESS) {
            NSLog(@"Failure setting argument");
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1005 userInfo:argFail];
            return calcerr;
        }
        
        err = clSetKernelArg(bncalc_Kernel, 3, sizeof(cl_mem), (void*)&cptnetbuf);
        if (err != CL_SUCCESS) {
            NSLog(@"Failure setting argument");
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1005 userInfo:argFail];
            return calcerr;
        }
        
        err = clSetKernelArg(bncalc_Kernel, 4, bnreadsize*sizeof(cl_int), NULL);
        if (err != CL_SUCCESS) {
            NSLog(@"Failure setting argument");
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1005 userInfo:argFail];
            return calcerr;
        }
        
        err = clSetKernelArg(bncalc_Kernel, 5, sizeof(cl_mem), (void*)&bnresultsbuf);
        if (err != CL_SUCCESS) {
            NSLog(@"Failure setting argument");
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1005 userInfo:argFail];
            return calcerr;
        }
        
        
        err = clSetKernelArg(bncalc_Kernel, 6, thisWork * INSize * sizeof(cl_int), NULL); //this is the array size of the shuffled nodes...uses local mem
        if (err != CL_SUCCESS) {
            NSLog(@"Failure setting argument");
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1005 userInfo:argFail];
            return calcerr;
        }
        
        err = clSetKernelArg(bncalc_Kernel, 7, sizeof(cl_mem), (void*)&priordisttypebuf);
        if (err != CL_SUCCESS) {
            NSLog(@"Failure setting argument");
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1005 userInfo:argFail];
            return calcerr;
        }
        
        err = clSetKernelArg(bncalc_Kernel, 8, sizeof(cl_mem), (void*)&priorv1buf);
        if (err != CL_SUCCESS) {
            NSLog(@"Failure setting argument");
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1005 userInfo:argFail];
            return calcerr;
        }
        
        err = clSetKernelArg(bncalc_Kernel, 9, sizeof(cl_mem), (void*)&priorv2buf);
        if (err != CL_SUCCESS) {
            NSLog(@"Failure setting argument");
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1005 userInfo:argFail];
            return calcerr;
        }
        
        
        
        timer = [startcalc timeIntervalSinceNow] * -1000.0;
        //NSLog(@"Before kernel enqueue %f since starting calc fxn", timer);
        
        //Enqueue kernel
        err = CL_SUCCESS;
        err = clEnqueueNDRangeKernel(
                                     cl_queue,         // a valid command queue
                                     bncalc_Kernel,           // a valid kernel object
                                     1,                       // the data dimensions                   [4]
                                     NULL,                    // reserved; must be NULL
                                     &worksize,                  // work sizes for each dimension         [5]
                                     NULL,                   // work-group sizes for each dimension   [6]
                                     0,                       // num entires in event wait list        [7]
                                     NULL,                    // event wait list                       [8]
                                     &prof_events[tt]);                   // on return, points to new event object [9]
        
        
        if (err != CL_SUCCESS){
            NSLog(@"Failure enqueueing kernel. Error %i", err);
            
            NSString * recStr = @"The OpenCL error returned is %i";
            NSString * errStr = [NSString stringWithFormat:@"%i", err];
            NSString * recerrStr = [recStr stringByAppendingString:errStr];
            
            NSDictionary *enqueueFail = @{//1006
                                          NSLocalizedDescriptionKey: NSLocalizedString(@"OpenCL", nil),
                                          NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The OpenCL Kernel has failed to enqueue.", nil),
                                          NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(recerrStr, nil)
                                          };
            calcerr = [NSError errorWithDomain:@"plexusCalc" code:1006 userInfo:enqueueFail];
            return calcerr;
        }
            
            

            //add completed
            
            ct += thisWork;
            

                
            
            
            //end device loop
            tt++;
            if(ct >= [computes intValue]) break; //in case we do not need all the devices
            timer = [startcalc timeIntervalSinceNow] * -1000.0;
          //  NSLog(@"Bottom of ct loop %f since starting calc fxn", timer);
        
        
        
    

        
        
        
        //end while ct < computes
    }
    cl_int info;
  
    int cct = 0;
    while([passchk count]>0){
        NSMutableArray *tmppasschk = [NSMutableArray arrayWithCapacity:numpasses];
       // NSLog(@"***************************");
        for (NSNumber * chknum in passchk) {
           // NSLog(@"checking on %@", chknum);
            clGetEventInfo(prof_events[[chknum intValue]], CL_EVENT_COMMAND_EXECUTION_STATUS, sizeof(cl_int), (void *)&info, NULL);
            if ( info == CL_COMPLETE ){
              //  NSLog(@"*****Event %i complete", [chknum intValue]);
                cct += worksize;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [progInd incrementBy:worksize];
                    curLabel.stringValue = [NSString stringWithFormat:@"%i", cct];
                    //FIXME can only advance if first time completing this one
                });
     
            }
            else{
                [tmppasschk addObject:chknum];
            }
        }
        passchk = tmppasschk;
        usleep(10000);
    }
    



     
    
    
    timer = [startcalc timeIntervalSinceNow] * -1000.0;
     NSLog(@"After clFinish %f since starting calc fxn", timer);
    
    /*
    for(int dev = 0; dev < numpasses; dev++){
        cl_ulong ev_start_time=(cl_ulong)0;
        cl_ulong ev_end_time=(cl_ulong)0;
        cl_ulong ev_queued_time=(cl_ulong)0;
        cl_ulong ev_submit_time=(cl_ulong)0;
        err = clWaitForEvents(1, &prof_events[dev]);
        err |= clGetEventProfilingInfo(prof_events[dev], CL_PROFILING_COMMAND_START, sizeof(cl_ulong), &ev_start_time, NULL);
        err |= clGetEventProfilingInfo(prof_events[dev], CL_PROFILING_COMMAND_END, sizeof(cl_ulong), &ev_end_time, NULL);
        err |= clGetEventProfilingInfo(prof_events[dev], CL_PROFILING_COMMAND_QUEUED, sizeof(cl_ulong), &ev_queued_time, NULL);
        err |= clGetEventProfilingInfo(prof_events[dev], CL_PROFILING_COMMAND_SUBMIT, sizeof(cl_ulong), &ev_submit_time, NULL);
        float que_time_gpu = (float)(ev_submit_time - ev_queued_time)/1000; // in usec
        float sub_time_gpu = (float)(ev_start_time - ev_submit_time)/1000; // in usec
        float run_time_gpu = (float)(ev_end_time - ev_start_time)/1000; // in usec
        NSLog(@"Pass %i: Queued until submitted %f. Submitted until start %f. Start until finished %f", dev, que_time_gpu, sub_time_gpu, run_time_gpu);
    }
    */
    
    int totcount = 0;
    for(int dev = 0; dev < numpasses; dev++) {

        int nodecount = 0;
        for(i=0;i<bnreadsize;i++){
            // NSLog(@"Pass %i run %i: %@ goes into node %i" ,dev, i, [NSNumber numberWithFloat:bnresultsarrays[dev][i]], nodecount);
            
            if(firsttime){
                NSMutableArray *newPA = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithFloat:bnresultsarrays[dev][i]], nil];
                [resultNodes addObject:newPA];
                
            }
            else {
                [[resultNodes objectAtIndex:nodecount] addObject:[NSNumber numberWithFloat:bnresultsarrays[dev][i]]];
            }
            
            nodecount++;
            if(nodecount >= [initialNodes count]){
                firsttime = FALSE;
                nodecount=0;
                totcount++;
                
            }
            
            if(totcount >= [computes intValue])break;
        }
        
    }
    
    timer = [startcalc timeIntervalSinceNow] * -1000.0;
    NSLog(@"After results read %f since starting calc fxn", timer);
    
    
    for(int dev = 0; dev < numpasses; dev++){
        
        clEnqueueUnmapMemObject(cl_queue, offsetbufs[dev], offsetarrays[dev],  0, NULL, NULL);
        clEnqueueUnmapMemObject(cl_queue, bnresultsbufs[dev], bnresultsarrays[dev],  0, NULL, NULL); //FIXME bnresultsbufs should have numpasses entries
        
        
    }
   
    


        
    clEnqueueUnmapMemObject(cl_queue, paramsbuf, mappedParams,  0, NULL, NULL);
    clEnqueueUnmapMemObject(cl_queue, infnetbuf, mappedInfnet,  0, NULL, NULL);
    clEnqueueUnmapMemObject(cl_queue, cptnetbuf, mappedCptnet,  0, NULL, NULL);
    clEnqueueUnmapMemObject(cl_queue, cptnetbuf, mappedCptnet,  0, NULL, NULL);
    clEnqueueUnmapMemObject(cl_queue, priordisttypebuf, mappedPriordisttype,  0, NULL, NULL);
    clEnqueueUnmapMemObject(cl_queue, priorv1buf, mappedPriorv1s,  0, NULL, NULL);
    clEnqueueUnmapMemObject(cl_queue, priorv2buf, mappedPriorv2s,  0, NULL, NULL);
    

    

    clReleaseKernel(bncalc_Kernel);

    
    
    
    free(infnet);
    free(cptnet);
    
    //if end is reached safely, no error
    
    
    timer = [startcalc timeIntervalSinceNow] * -1000.0;
    NSLog(@"At end of calc fxn %f since starting calc fxn", timer);
    
    return calcerr;
    
    
    
}


- (NSMutableArray *)getResults:(id)sender{
    
    
    return resultNodes;
}



-(void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject
                       change:(NSDictionary *)aChange context:(void *)aContext
{

    [self clCompile];
}

- (BOOL *) isBNProgram:(id)sender{
    if(bn_program == nil){
        return FALSE;
    }
    return TRUE;
}


@end
