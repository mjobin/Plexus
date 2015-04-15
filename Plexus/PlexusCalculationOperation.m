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

- (id)init
{
    self = [super init];
   
    return self;
    
}

- (id)initWithNodes:(NSArray *) inNodes withRuns:(NSNumber *) inRuns withBurnin:(NSNumber *) inBurnins withComputes:(NSNumber*) inComputes
{
    self = [super init];
    if (self) {
        NSLog(@"init calc op");
        //How many devices do we have locally?
        
        
        initialNodes = inNodes;
        runs =inRuns;
        burnins = inBurnins;
        computes = inComputes;
        resultNodes = [NSMutableArray array];
        
        NSLog(@"BN calc operation loaded");
        
        
        
       
    
    return self;
    }

    return nil;
}

- (NSError *)calc:(id)sender
{
    NSError * calcerr = nil;
    unsigned int i;
    cl_kernel bncalc_Kernel;
    
    
    NSUInteger devPref = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"hardwareDevice"] integerValue];
    NSLog(@"hw pref pref %lu", (unsigned long)devPref);
    
    NSUInteger calcSpd = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"calcSpeed"] integerValue];
    NSLog(@"calc pref %lu", (unsigned long)calcSpd);
    
    if (devPref == 0) { //CPU
        err = clGetDeviceIDs(NULL, CL_DEVICE_TYPE_CPU, sizeof(device_ids), device_ids, &num_devices);
        if(err || num_devices <= 0)
        {
            NSLog(@"Failed to find any openCL devices!!!");
            return FALSE;
        }
    }
    
    else if (devPref == 1) { //GPU
        
        err = clGetDeviceIDs(NULL, CL_DEVICE_TYPE_GPU, sizeof(device_ids), device_ids, &num_devices);
        if(err || num_devices <= 0)
        {
            
            err = clGetDeviceIDs(NULL, CL_DEVICE_TYPE_ALL, sizeof(device_ids), device_ids, &num_devices);
            
            if(err || num_devices <= 0)
            {
                NSLog(@"Failed to find any openCL devices!!!");
                return FALSE;
            }
            
        }
        
        
    }
    
    else {//all types
        err = clGetDeviceIDs(NULL, CL_DEVICE_TYPE_ALL, sizeof(device_ids), device_ids, &num_devices);
        if(err || num_devices <= 0)
        {
            NSLog(@"Failed to find any openCL devices!!!");
            return FALSE;
        }
    }
    
    
    
    
    
    
    //create context
    context = clCreateContext(0, num_devices, device_ids, NULL, NULL, &err);
    if(!context || err)
    {
        NSLog(@"Failed to create openCL context!");
        return nil;
    }
    
    
    
    
    //Look for available devices and get their info
    //b unsigned int i;
    for(i = 0; i < num_devices; i++)
    {
        
        //Check availability of the devices returned first
        cl_bool device_available;
        err = clGetDeviceInfo(device_ids[i], CL_DEVICE_AVAILABLE, sizeof(cl_bool), &device_available, NULL);
        if(err)
        {
            NSLog(@"Device %i cannot be checked for availability", i);
        }
        
        //Test... what have we got here?
        char device_name[200];
        err = clGetDeviceInfo(device_ids[i], CL_DEVICE_NAME, sizeof(device_name), device_name, NULL);
        if(err == CL_SUCCESS)
        {
            NSLog(@"%s reporting.", device_name);
        }
        
        //how much mem?
        
        err = clGetDeviceInfo(device_ids[i], CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(cl_ulong), &gMemSize, NULL);
        if(err == CL_SUCCESS)
        {
            gMemSize /= (1024*1024);
            NSLog(@"Device memory %llu megabytes.", gMemSize);
        }
        
        err = clGetDeviceInfo(device_ids[i], CL_DEVICE_LOCAL_MEM_SIZE, sizeof(cl_ulong), &lMemSize, NULL);
        if(err == CL_SUCCESS)
        {
            lMemSize /= (1024*1024);
            NSLog(@"Device local memory %llu megabytes.", lMemSize);
        }
        
        
        size_t max_work_item_dims;
        err = clGetDeviceInfo(device_ids[i], CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS, sizeof(max_work_item_dims), &max_work_item_dims, &returned_size);
        
        size_t max_work_item_sizes[3];
        err = clGetDeviceInfo(device_ids[i], CL_DEVICE_MAX_WORK_ITEM_SIZES, sizeof(max_work_item_sizes), max_work_item_sizes, &returned_size);
        for(size_t i=0;i<3;i++) {
            NSLog(@"Max Work Items in Dim %lu: %lu\n",(long unsigned)(i+1),(long unsigned)max_work_item_sizes[i]);
        }
        
        
        
        
        cl_queues[i] = clCreateCommandQueue(context, device_ids[i], 0, &err);
        
        if(!cl_queues[i] || err)
        {
            NSLog(@"BN calc: Failed to create openCL queue for CPU device!");
            return nil;
        }
        
        
    }
    
    
    //*****************************
    //Create a read-only buffer for the initial node state
    //I know the total size of the nodes already
    NSUInteger INSize = [initialNodes count];
    NSLog(@"%lu initial nodes", INSize);
    
    
    NSUInteger maxCPTSize = 0;
    
    NSUInteger clRuns = [runs integerValue]; // to tranfer to buffer
    NSUInteger clBurnins = [burnins integerValue];
    
    
    //get maximum size of inputs and outputsd
    
    

        
    for (BNNode * fNode in initialNodes) {
        NSMutableOrderedSet * allInSet = [fNode recursiveInfBy:self infBy:[[NSMutableOrderedSet alloc] init] depth:0];
        if([allInSet count] > maxCPTSize) maxCPTSize = [allInSet count];
    }
    
    
    
    
    for (BNNode * fNode in initialNodes) {
        NSMutableOrderedSet * allOutSet = [fNode recursiveInfs:self infs:[[NSMutableOrderedSet alloc] init] depth:0];
        if([allOutSet count] > maxCPTSize) maxCPTSize = [allOutSet count];
    }
    
        
    
    
    
    if(maxCPTSize < 1) return nil; //so that we don't work with completely unlinked graphs
    
    //--------------------------------------CPT
    cl_int* infnet = malloc(sizeof(cl_int)*INSize*(maxCPTSize*2)); //size of whole list twice on x (influences and influenced by) and once on y (each node)
    
    NSLog(@"infnet size: %lu", (sizeof(cl_int[INSize*(maxCPTSize*2)])));
    
    
    
    
    NSLog(@"But %lu nodes if we use the maximum input/output size of any node", maxCPTSize);
    unsigned long sparseCPTsize = pow((double) 2.0, maxCPTSize);
    NSLog(@"And %lu CPT entries per node", sparseCPTsize);
    NSLog(@"So %lu CPT entries for all nodes", (sparseCPTsize*INSize));
    
    
    
    cl_float* cptnet = malloc(sizeof(cl_float)*INSize*sparseCPTsize);
    // NSLog(@"cptnet size: %lu", sizeof(cl_float[INSize*sparseCPTsize]));
    
    
    int xoffset = 0;
    int cptoffset =0;
    int thisCPT =0;
    NSUInteger leftOver = 0;
    
    cl_float* nodeFreqs = (cl_float *)malloc(sizeof(cl_float)*INSize); //one for the type of distn, and two for its parameters
    int freqOffset =0;
    
    //Construct influences, CPT, fequencies
    //NSLog(@"construct influences");
    for (BNNode * fNode in initialNodes) {
        // NSLog(@"***************Node: %@", [[fNode nodeLink] name]);
        
        
        //add freq
        nodeFreqs[freqOffset] = [fNode freqForCPT:self];
        
        //------------- influenced by
        
        NSMutableOrderedSet * theInfluencedBy = [fNode recursiveInfBy:self infBy:[[NSMutableOrderedSet alloc] init] depth:0];
        //NSMutableOrderedSet * laceInfluencedBy = [fNode laceInfluencedBy:self: [[NSMutableOrderedSet alloc]init] :0];
        
        
        thisCPT =0;
        int nInfBy = 0;
        
        for (BNNode * inNode in theInfluencedBy) {
            infnet[(xoffset+thisCPT)] = (cl_int)[initialNodes indexOfObject:inNode];
            nInfBy++;
            thisCPT++;
        }
        
        
        leftOver = maxCPTSize-thisCPT;
        
        for(i=0; i<=leftOver; i++){
            //add dummy entries to pad out
            infnet[(xoffset+thisCPT)] = -1;
            thisCPT++;
        }
        
        xoffset += maxCPTSize;
        
        //------------- influences
        thisCPT =0;
        
        NSMutableOrderedSet * theInfluences = [fNode recursiveInfs:self infs:[[NSMutableOrderedSet alloc] init] depth:0];
        
        
        for (BNNode * outNode in theInfluences) {
            infnet[(xoffset+thisCPT)] = (cl_int)[initialNodes indexOfObject:outNode];
            thisCPT++;
        }
        
        
        
        leftOver = maxCPTSize-thisCPT;
        
        for(i=0; i<=leftOver; i++){
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
        
        
        for(i=0; i<sparseSize; i++){
            
            NSMutableArray *ftft = [[NSMutableArray alloc]init];
            
            //get a binary representation of i, with F's meaning zeroes and T's meaning ones
            int num = i;
            int n = (log(num)/log(2)+1)-1;          //Figure out the maximum power of 2 needed
            for (int j=n; j>=0; j--)            //Iterate down through the powers of 2
            {
                long long curPOW = powl(2,j);
                if (curPOW <= num)          //If the number is greater than current power of 2
                {
                    num -= curPOW;                                  //Subtract the power of 2
                    [ftft addObject:[NSNumber numberWithBool:TRUE]];
                }
                else [ftft addObject:[NSNumber numberWithBool:FALSE]];
            }
            
            //pad out with F's
            for(int k=(int)[ftft count]; k<nInfBy; k++){
                [ftft insertObject:[NSNumber numberWithBool:FALSE] atIndex:0];
            }
            
            
            cptnet[(cptoffset+i)] = [fNode CPT:self infBy:theInfluencedBy.array ftft:[NSArray arrayWithArray:ftft] depth:0];
            
            //cptnet[(cptoffset+i)] = [fNode CPT:self : laceInfluencedBy :[NSArray arrayWithArray:ftft]: 0];
            // NSLog(@"The ftft string: %@ Going into CPT: %f", ftft, [fNode CPT:self : influencedBy :[NSArray arrayWithArray:ftft]: 0]);
            
        }
        
        for(i=i; i<sparseCPTsize; i++){
            cptnet[(cptoffset+i)] = -1.0f;
        }
        
        
        cptoffset += sparseCPTsize;
        
        freqOffset++;
        
    }
    
    //*****************************
    
    //test inpout
    
    /*
    
    NSLog(@"\n\ninfluencedby and  influences");
    
    int w =0;
    for(i=0;i<INSize;i++){
        NSLog(@"***************Node: %@", [[initialNodes objectAtIndex:i]name]);
        printf("influencedby:");
        for(int j=0;j<maxCPTSize;j++){
            printf("%i ", infnet[w]);
            w++;
        }
        printf("\ninfluences:");
        for(int j=0;j<maxCPTSize;j++){
            printf("%i ", infnet[w]);
            w++;
        }
        printf("\n");
        
    }
    
    printf("\n\n----------------------\n\n");
    
    
    
    w =0;
    for(i=0;i<INSize;i++){
        NSLog(@"***************Node: %@", [[initialNodes objectAtIndex:i] name]);
        printf("influencedby:");
        for(int j=0;j<sparseCPTsize;j++){
            printf("%f ", cptnet[w]);
            w++;
        }
        printf("\n");
        
    }
    
    printf("\n\n----------------------\n\n");
    
    NSLog(@"freqs");
    w =0;
    for(i=0;i<INSize;i++){
        NSLog(@"***************Node: %@", [[initialNodes objectAtIndex:i] name]);
        printf("%f\n", nodeFreqs[i]);
        
        
    }
    
    printf("\n\n----------------------\n\n");
    */
    
    
    //Load the kernel
    NSData *bnData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"bn_kernel" ofType:@"cl"]];
    
    NSMutableData *sourceData = [[NSMutableData alloc] init];
    
    //[sourceData appendData:rngData];
    [sourceData appendData:bnData];
    
    const char *source = [sourceData bytes];
    size_t length = [sourceData length];
    
    
    //NSLog(@"SOURCE:/n%s",source);
    
    cl_program bncalc_program = clCreateProgramWithSource(context, 1, &source, &length, &err);
    if (!bncalc_program || err != CL_SUCCESS) {
        NSLog(@"BN Calc: Fail to create OpenCL program object.");
    }
    
    // NSLog(@"%lu",length);
    
    
    //Build executable
    err = clBuildProgram(bncalc_program, num_devices, device_ids, NULL, NULL, NULL);
    
    if (err != CL_SUCCESS)
    {
        NSLog(@"BN Calc: Fail to build executable.");
        
        size_t len;
        
        // declare a buffer to hold the build info
        char buffer[2048];
        
        // get the details on the error, and store it in buffer
        clGetProgramBuildInfo(
                              bncalc_program,              // the program object being queried
                              device_ids[0],            // the device for which the OpenCL code was built
                              CL_PROGRAM_BUILD_LOG, // specifies that we want the build log
                              sizeof(buffer),       // the size of the buffer
                              buffer,               // on return, holds the build log
                              &len);                // on return, the actual size in bytes of the
        //   data returned
        NSString *buf = [NSString stringWithCString:buffer encoding:4];
        NSLog(@"%@", buf);
        
    }
    
    
    
    bncalc_Kernel = clCreateKernel(bncalc_program, "BNGibbs", &err);
    if (!bncalc_Kernel || err != CL_SUCCESS) {
        NSLog(@"Couldn't find the function 'BNGibbs' in the program.");
    }
    
    
    
    
    //SETUP LOOP
    size_t worksizes[num_devices];
    size_t bnreadsizes[num_devices];
    size_t maxworksize = 0; //this will end up being the column size for the data
    
    cl_mem * infnetbufs = malloc(sizeof(cl_mem)*num_devices);
    cl_mem * cptnetbufs = malloc(sizeof(cl_mem)*num_devices);
    cl_mem * freqbufs = malloc(sizeof(cl_mem)*num_devices);
    
    for(int dev = 0; dev < num_devices; dev++){
        
        
        //create the buffer for BN influences
        cl_mem infnetbuf = clCreateBuffer(context, CL_MEM_READ_ONLY, INSize*(maxCPTSize*2)*sizeof(cl_int), 0, &err);
        if (!infnetbuf || err != CL_SUCCESS) {
            NSLog(@"BN calc: Failed to create initial bn inf buffer!");
        }
        clEnqueueWriteBuffer(cl_queues[dev], infnetbuf, CL_TRUE, 0, INSize*(maxCPTSize*2)*sizeof(cl_int), (void*)infnet, 0, 0, 0);
        infnetbufs[dev] = infnetbuf;
        
        
        //create the buffer for the cpts
        cl_mem cptnetbuf = clCreateBuffer(context, CL_MEM_READ_ONLY, sizeof(cl_float)*INSize*sparseCPTsize, 0, &err);
        if (!cptnetbuf || err != CL_SUCCESS) {
            NSLog(@"BN calc: Failed to create initial cpt buffer!");
        }
        clEnqueueWriteBuffer(cl_queues[dev], cptnetbuf, CL_TRUE, 0, sizeof(cl_float)*INSize*sparseCPTsize, (void*)cptnet, 0, 0, 0);
        cptnetbufs[dev] = cptnetbuf;
        
        //create the buffer for the freqs
        cl_mem freqbuf = clCreateBuffer(context, CL_MEM_READ_ONLY, sizeof(cl_float)*INSize, 0, &err);
        if (!freqbuf || err != CL_SUCCESS) {
            NSLog(@"BN calc: Failed to create initial frequencies buffer!");
        }
        clEnqueueWriteBuffer(cl_queues[dev], freqbuf, CL_TRUE, 0, sizeof(cl_float)*INSize, (void*)nodeFreqs, 0, 0, 0);
        freqbufs[dev]=freqbuf;
        
        
        
        
        
        
        
        size_t max_work_item_dims;
        err = clGetDeviceInfo(device_ids[dev], CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS, sizeof(max_work_item_dims), &max_work_item_dims, &returned_size);
        
        size_t max_work_item_sizes[3];
        err = clGetDeviceInfo(device_ids[dev], CL_DEVICE_MAX_WORK_ITEM_SIZES, sizeof(max_work_item_sizes), max_work_item_sizes, &returned_size);
        for(size_t i=0;i<3;i++) {
            NSLog(@"Max Work Items in Dim %lu: %lu\n",(long unsigned)(i+1),(long unsigned)max_work_item_sizes[i]);
        }
        
        size_t kwBuf = 0;
        err = clGetKernelWorkGroupInfo(
                                       bncalc_Kernel,                      // the kernel object being queried
                                       device_ids[dev], // a device associated with the kernel object
                                       CL_KERNEL_WORK_GROUP_SIZE,    // requests the work-group size
                                       sizeof(kwBuf),             // size in bytes of return buffer
                                       &kwBuf,                    // on return, points to requested information
                                       &returned_size);
        
        NSLog(@"Kernel work group size for bn_kernel %lu", (long unsigned)kwBuf);
        
        //Figure out how many work items - use all initially
        size_t gWorkItems = max_work_item_sizes[0]*max_work_item_sizes[1]*max_work_item_sizes[2];
        //Adjust for speed setting
        if(calcSpd == 0) gWorkItems = gWorkItems *0.5;
        else if (calcSpd ==1) gWorkItems = gWorkItems*0.75;
        //if it's set at 2, use maximum number of work items
        
        
        if(gWorkItems > kwBuf) gWorkItems = kwBuf;
        //if(gWorkItems > [computes intValue]) gWorkItems = [computes intValue];
        
        //TEST set to 1
        //gWorkItems = 1;
        
        NSLog(@"work-group items %lu", (long unsigned)gWorkItems);
        worksizes[dev] = gWorkItems;
        bnreadsizes[dev] = gWorkItems * [initialNodes count];
        if(worksizes[dev] > maxworksize) maxworksize = worksizes[dev];
        
    }
    
    
    size_t bnstatesize = maxworksize * [initialNodes count];
    
    //initialize and zero read arrays
    cl_int bnstatesarrays[num_devices][bnstatesize];
    cl_float bnresultsarrays[num_devices] [bnstatesize];
    cl_int offsetarrays [num_devices][maxworksize];
    cl_int offsetcheckarrays [num_devices][maxworksize];
    
    for (int i =0; i < num_devices; i++) {
        for (int j = 0; j < maxworksize; j++) {
            offsetarrays [i][j] = 0;
            offsetcheckarrays [i][j] = 0;
        }
        for (int j = 0; j < bnstatesize; j++) {
            bnstatesarrays [i][j] = 0;
            bnresultsarrays [i][j] = 0.0;
        }
        
    }
    
    BOOL firsttime = TRUE;
    //NEW MAIN LOOP
    int ct =0;
    while(ct < [computes intValue]){
        
        cl_mem * bnstatesbufs = malloc(sizeof(cl_mem)*num_devices);
        cl_mem * bnresultsbufs = malloc(sizeof(cl_mem)*num_devices);
        cl_mem * offsetbufs = malloc(sizeof(cl_mem)*num_devices);
        cl_mem * outputbufs = malloc(sizeof(cl_mem)*num_devices);
        
        
        for(int dev = 0; dev < num_devices; dev++){

            
            cl_mem bnstatesbuf = clCreateBuffer(context, CL_MEM_READ_WRITE, bnstatesize*sizeof(cl_int), 0, &err);
            if (!bnstatesbuf || err != CL_SUCCESS) {
                NSLog(@"BN calc: Failed to create initial bn_states buffer!");
            }
            clEnqueueWriteBuffer(cl_queues[dev], bnstatesbuf, CL_TRUE, 0, bnstatesize*sizeof(cl_int), (void*)bnstatesarrays[dev], 0, 0, 0);
            bnstatesbufs[dev]=bnstatesbuf;
            
            
            cl_mem bnresultsbuf = clCreateBuffer(context, CL_MEM_READ_WRITE, bnstatesize*sizeof(cl_float), 0, &err);
            if (!bnresultsbuf || err != CL_SUCCESS) {
                NSLog(@"BN calc: Failed to create initial bnresults buffer!");
            }
            clEnqueueWriteBuffer(cl_queues[dev], bnresultsbuf, CL_TRUE, 0, bnstatesize*sizeof(cl_float), (void*)bnresultsarrays[dev], 0, 0, 0);
            bnresultsbufs[dev] = bnresultsbuf;
            
            for(i=0;i<worksizes[dev];i++){
                offsetarrays[dev][i] = arc4random();
                //NSLog(@"offset %i", offsetarrays[dev][i]);
            }
            
            
            //create the buffer for RNG seeds
            cl_mem offsetbuf = clCreateBuffer(context, CL_MEM_READ_WRITE, worksizes[dev]*sizeof(cl_int), 0, &err);
            if (!offsetbuf || err != CL_SUCCESS) {
                NSLog(@"BN calc: Failed to create initial rng offsets buffer!");
            }
            clEnqueueWriteBuffer(cl_queues[dev], offsetbuf, CL_TRUE, 0, worksizes[dev]*sizeof(cl_int), (void*)offsetarrays[dev], 0, 0, 0);
            offsetbufs[dev] = offsetbuf;//add to array so can free it afterward
            
            
            
            
            //TEST - output buffer just to read the offset
            // cl_int output[worksizes[dev]];
            cl_mem outputbuf = clCreateBuffer(context, CL_MEM_READ_WRITE, worksizes[dev]*sizeof(cl_int), 0, &err);
            if (!outputbuf || err != CL_SUCCESS) {
                NSLog(@"BN calc: Failed to create output buffer!");
            }
            outputbufs[dev] = outputbuf;
            
            
            //set args
            
            
            
            
            err = clSetKernelArg(bncalc_Kernel, 0, sizeof(cl_mem), (void*)&offsetbuf);
            if (err != CL_SUCCESS) {
                NSLog(@"Failure setting argument");
            }
            
            err = clSetKernelArg(bncalc_Kernel, 1, sizeof(cl_int), (void*)&INSize);
            if (err != CL_SUCCESS) {
                NSLog(@"Failure setting argument");
            }
            
            err = clSetKernelArg(bncalc_Kernel, 2, sizeof(cl_int), (void*)&maxCPTSize);
            if (err != CL_SUCCESS) {
                NSLog(@"Failure setting argument");
            }
            
            
            err = clSetKernelArg(bncalc_Kernel, 3, sizeof(cl_mem), (void*)&freqbufs[dev]);
            if (err != CL_SUCCESS) {
                NSLog(@"Failure setting argument");
            }
            
            
            err = clSetKernelArg(bncalc_Kernel, 4, sizeof(cl_mem), (void*)&infnetbufs[dev]);
            if (err != CL_SUCCESS) {
                NSLog(@"Failure setting argument");
            }
            
            err = clSetKernelArg(bncalc_Kernel, 5, sizeof(cl_mem), (void*)&cptnetbufs[dev]);
            if (err != CL_SUCCESS) {
                NSLog(@"Failure setting argument");
            }
            
            err = clSetKernelArg(bncalc_Kernel, 6, sizeof(cl_mem), (void*)&bnstatesbuf);
            if (err != CL_SUCCESS) {
                NSLog(@"Failure setting argument 6");
            }
            
            err = clSetKernelArg(bncalc_Kernel, 7, sizeof(cl_mem), (void*)&bnresultsbuf);
            if (err != CL_SUCCESS) {
                NSLog(@"Failure setting argument 7");
            }
            
            
            err = clSetKernelArg(bncalc_Kernel, 8, sizeof(cl_mem), (void*)&outputbuf);
            if (err != CL_SUCCESS) {
                NSLog(@"Failure setting argument");
            }
            
            err = clSetKernelArg(bncalc_Kernel, 9, sizeof(cl_int), (void*)&clRuns);
            if (err != CL_SUCCESS) {
                NSLog(@"Failure setting argument");
            }
            
            err = clSetKernelArg(bncalc_Kernel, 10, sizeof(cl_int), (void*)&clBurnins);
            if (err != CL_SUCCESS) {
                NSLog(@"Failure setting argument");
            }
            
            
            
            //Enqueue kernel
            err = CL_SUCCESS;
            err = clEnqueueNDRangeKernel(
                                         cl_queues[dev],         // a valid command queue
                                         bncalc_Kernel,           // a valid kernel object
                                         1,                       // the data dimensions                   [4]
                                         NULL,                    // reserved; must be NULL
                                         &worksizes[dev],                  // work sizes for each dimension         [5]
                                         NULL,                   // work-group sizes for each dimension   [6]
                                         0,                       // num entires in event wait list        [7]
                                         NULL,                    // event wait list                       [8]
                                         NULL);                   // on return, points to new event object [9]
            
            
            if (err != CL_SUCCESS){
                NSLog(@"Failure enqueueing kernel. Error %i", err);
            }
            
            
            //FIXME change to non blocking
            
            clEnqueueReadBuffer(cl_queues[dev], outputbuf, CL_FALSE, 0, worksizes[dev]*sizeof(cl_int), (void*)offsetcheckarrays[dev], 0, 0, 0);
            
            clEnqueueReadBuffer(cl_queues[dev], bnstatesbuf, CL_FALSE, 0, bnstatesize*sizeof(cl_int), (void*)bnstatesarrays[dev], 0, 0, 0);
            
            clEnqueueReadBuffer(cl_queues[dev], bnresultsbuf, CL_FALSE, 0, bnstatesize*sizeof(cl_float), (void*)bnresultsarrays[dev], 0, 0, 0);
            
            
            //add completed
            
            ct += worksizes[dev];
            
            //end device loop
            if(ct >= [computes intValue]) break; //in case we do not need all the devices
        }
        
        
        for(int dev = 0; dev < num_devices; dev++){
            clFinish(cl_queues[dev]);
        }
        
        
        //send update message to clProgressIndicator
        
        
        for(int dev = 0; dev < num_devices; dev++) {
            
            //now check output
            
            /*
            NSLog(@"work size check %zu", worksizes[dev]);
            
            for(int i=0;i<worksizes[dev];i++){
                
                NSLog(@"run %i: gave offset rng %i ran up to %i", i, offsetarrays[dev][i], offsetcheckarrays[dev][i]);
            }
            
            for(int i=0;i<bnreadsizes[dev];i++){
                NSLog(@"state %i : result %f", bnstatesarrays[dev][i], bnresultsarrays[dev][i]);
                
            }
             */
            
            
            int nodecount = 0;
            for(i=0;i<bnreadsizes[dev];i++){
               // NSLog(@"%i: %@ goes into node %i" ,i, [NSNumber numberWithFloat:bnresultsarrays[dev][i]], nodecount);
                
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
                }
            }
        }
        
        for(int dev = 0; dev < num_devices; dev++){
            
            clReleaseMemObject(bnstatesbufs[dev]);
            clReleaseMemObject(bnresultsbufs[dev]);
            clReleaseMemObject(offsetbufs[dev]);
            clReleaseMemObject(outputbufs[dev]);
            
        }
        
        
        
        //end while ct < computes
    }
    
    
    
    
    
    
    
    for(int dev = 0; dev < num_devices; dev++){
        
        clReleaseMemObject(infnetbufs[dev]);
        clReleaseMemObject(cptnetbufs[dev]);
        clReleaseMemObject(freqbufs[dev]);
        
        clReleaseCommandQueue(cl_queues[dev]);
    }
    
    
    clReleaseProgram(bncalc_program);
    clReleaseKernel(bncalc_Kernel);
    clReleaseContext(context);
    
    
    
    free(infnet);
    free(cptnet);
    free(nodeFreqs);
    
    //if end is reached safely, no error
    
    return calcerr;

    
    
}


- (NSMutableArray *)getResults:(id)sender{
    return resultNodes;
}


@end
