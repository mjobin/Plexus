/* BNGibbs Kernel Matthew Jared Jobin 2015
 *
 *
 *
 *
 *
 *
 */


#include "tinymt32_jump.clh"


#ifdef cl_khr_fp64
#pragma OPENCL EXTENSION cl_khr_fp64 : enable
//#define DOUBLE_SUPPORT_AVAILABLE
#else
#define double float
#define M_E 2.7182818284590452353602874713527f
#endif


int randomx(tinymt32j_t *r, int max)
{
    return (tinymt32j_single01(r)*max);
}

int pointroll(tinymt32j_t *r, float threshold)
{
    if(tinymt32j_single01(r)< threshold) return 1;
    return 0;
    
}

double unidev(tinymt32j_t *r, double v1, double v2){
    return (tinymt32j_single01(r)*(v2-v1)) + v1;
    
}

//------------------------------------------------------------------------------
// Modified from NumRep 2 p289-290
double gasdev(tinymt32j_t *r)
{
    //double ran3(long *idum);
    //float ran3(long *idum);
    int iset=0;
    //static float gset;
    double gset;
    //float fac,rsq,v1,v2;
    double fac,rsq,v1,v2;
    
    
    // if (*idum < 0) iset=0;
    if  (iset == 0) {
        do {
            v1=2.0*tinymt32j_single01(r)-1.0;
            v2=2.0*tinymt32j_single01(r)-1.0;
            rsq=v1*v1+v2*v2;
        } while (rsq >= 1.0 || rsq == 0.0);
        fac=sqrt(-2.0*log(rsq)/rsq);
        gset=v1*fac;
        iset=1;
        return v2*fac;
    } else {
        iset=0;
        return gset;
    }
}
//------------------------------------------------------------------------------


/****************************************************************
 gamma deviate for integer shape argument.  Code modified from pp
 292-293 of Numerical Recipes in C, 2nd edition.
 ****************************************************************/

double igamma_dev(int ia, tinymt32j_t *r)
{
    int j;
    double am,e,s,v1,v2,x,y;
    //long lidum=1L;
    
    if (ia < 1)
    {
        printf("Error: arg of igamma_dev was <1\n");
        
        // exit(1);
    }
    if (ia < 6)
    {
        x=1.0;
        for (j=0; j<ia; j++)
            x *= tinymt32j_single01(r);
        x = -log(x);
    }else
    {
        do
        {
            do
            {
                do
                {                         // next 4 lines are equivalent
                    v1=2.0*tinymt32j_single01(r)-1.0;       // to y = tan(Pi * uni()).
                    v2=2.0*tinymt32j_single01(r)-1.0;
                }while (v1*v1+v2*v2 > 1.0);
                y=v2/v1;
                am=ia-1;
                s=sqrt(2.0*am+1.0);
                x=s*y+am;
            }while (x <= 0.0);
            e=(1.0+y*y)*exp(am*log(x/am)-s*y);
        }while (tinymt32j_single01(r) > e);
    }
    return(x);
}


/* (C) Copr. 1986-92 Numerical Recipes Software Y5jc. */

/*
 Rogers comments:
 
 In answer to your question about my algorithm, I'm going to append my
 entire gamma_dev function.  The comments at the top provide references
 to the original sources.  The algorithm I use is supposedly the most
 commonly used when alpha<1.
 
 In case it is relevant, let me tell you about some of the trouble I've
 run into generating gamma deviates with small values of alpha.  My
 first gamma_dev function was in single precision.  It behaved very
 strangely.  When alpha<0.1, the number of segregating sites went *up*
 as alpha went *down*, which makes no sense at all.  I couldn't find
 any error in the code, but I noticed that the code does things that
 may stretch the limits of floating point arithmetic.  So I recompiled
 using double precision for all variables within gamma_dev.  The
 strange behavior went away.
 
 The literature doesn't say much about the stability of these
 algorithms when alpha is very small.  It seems that no one has ever
 been interested in that case.  I'll bet that none of the commercial
 statistical packages have tested their gamma deviate generator with
 very small alpha values either.  Consequently, we can't test our
 algorithms by comparing the quantiles of our generated values with
 those generated by, say, SPSS.  The only sure way is to calculate
 quantiles by direct integration of the density function.  I have done
 this for alpha=0.1 and am about to compare the quantiles of my numbers
 with these values.  I'll let you know what happens.
 
 Alan
 
 PS  Here's the code along with references.  */

/****************************************************************
 Random deviates from standard gamma distribution with density
 a-1
 x    exp[ -x ]
 f(x) = ----------------
 Gamma[a]
 
 where a is the shape parameter.  The algorithm for integer a comes
 from numerical recipes, 2nd edition, pp 292-293.  The algorithm for
 a<1 uses code from p 213 of Statistical Computing, by Kennedy and
 Gentle, 1980 edition.  This algorithm was originally published in:
 
 Ahrens, J.H. and U. Dieter (1974), "Computer methods for sampling from
 Gamma, Beta, Poisson, and Binomial Distributions".  COMPUTING
 12:223-246.
 
 The mean and variance of these values are both supposed to equal a.
 My tests indicate that they do.
 
 This algorithm has problems when a is small.  In single precision, the
 problem  arises when a<0.1, roughly.  That is why I have declared
 everything as double below.  Trouble is, I still don't know how small
 a can be without causing trouble.  Mean and variance are ok at least
 down to a=0.01.  f(x) doesn't seem to have a series expansion around
 x=0.
 ****************************************************************/


double
gamma_dev(double a, tinymt32j_t *r) {
    
    // printf("gamma with a %g\n", a);
    
    int ia;
    double u, b, p, x, y=0.0, recip_a;
    //long lidum=1L;
    
    if(a <= 0) {
        printf("\ngamma_dev: parameter must be positive\n");
        //  exit(1);
    }
    
    ia = (int) (floor(a));  // integer part
    a -= ia;        // fractional part
    if(ia > 0) {
        y = igamma_dev(ia, r);  // gamma deviate w/ integer argument ia
        if(a==0.0) return(y);
    }
    
    // get gamma deviate with fractional argument "a"
    b = (M_E + a)/M_E;
    recip_a = 1.0/a;
    for(;;) {
        u = tinymt32j_single01(r);
        p = b*u;
        if(p > 1) {
            x = -log( (b-p)/a );
            if( tinymt32j_single01(r) > pow(x, a-1)) continue;
            break;
        }
        else {
            x = pow(p, recip_a);
            if( tinymt32j_single01(r) > exp(-x)) continue;
            break;
        }
    }
    return(x+y);
}


//****************************************************************
//MJJ 4/29/15

double beta_dev(double a, double b, tinymt32j_t *r) {
    double x = gamma_dev(a, r);
    double y = gamma_dev(b, r);
    return x/(x+y);
}



//****************************************************************

//Monte Carlo Gibbs Sampler
__kernel void BNGibbs(__constant int* offsets, __constant int* params, __constant float* nodeFreqs, __constant int* infnet, __constant float* cptnet, __local int* bnstates, __global float *bnresults, __local int* shufflenodes, __constant int* priordisttypes, __constant float* priorv1s, __constant float* priorv2s, __local int* parentnodes, __local int* lastvisitedchild)
{
    
    
    //params[0] = INSize; == bnsize
    // params[1] = maxCPTSize; == maxCPTSize
    // params[2] = clRuns; ==runs
    // params[3] = clBurnins; == burnins
    
    
    
    
    __local int gid;
    gid = get_global_id(0); //A global identifier for this work-item. Used to access its part of the offset, bnstates and results
    
    __local int boffset;
    boffset = gid*params[0]; //offset to part of bnstates buffer used by this work-item
    
    __local int sparseCPTsize;
    sparseCPTsize = pow(2.0f, params[1]);
    
    
     // printf("--------------------------\n");
   // printf("work id is %i, bnsize is %i, maxCPTsize is %i, number of runs %i and burn-in %i \n", gid, params[0],params[1], params[2],params[3]);
    
    //Seed variable for random number generator
    __local int x;
    x = offsets[gid]*get_global_size(0);
    
    

    
    //TinyMT seed and test
    tinymt32j_t tinymt;
    tinymt32j_init_jump(&tinymt, (x)); //init the rng to to something somewhat random within each thread
    
    
    
    //Count variables
    __local int g;
    __local int h;
    __local int i;
    __local int k;
    g = 0;
    h = 0;
    i = 0;
    k = 0;
    
    
    //int binsum = 0; //Binary sum of the states of all the nodes that influence the current node
   // float binx = 0; //Float coutn variable, needed because will be using 2.0^binx
    
    __local infoffset;
    infoffset = 0; //Offset variale for influences array
    __local int cptoffset;
    cptoffset = 0; //Offset variale for CPT array
    
    
    __local int sampletot;
    sampletot = 0; //Number of sampled results
    __local int laststate;
    laststate = -1; //Previous state of a node, used to check for a stationary distribution
    __local int runstationary;
    runstationary = 0; //Number of times in a row the chosen state is the same as before. Used to see if we are converging on a stationary distritbution.
    
    __local int shuffleoffset;
    shuffleoffset = gid * params[0];
    
    
    
    //****************************************************************
    //****************************************************************
    //INPUT CHECK
    //****************************************************************
    //****************************************************************
    /*
    
     printf("------------INPUT CHECK--------------\n");
    printf("Work id is %i, offset is %i, bnsize is %i, maxCPTsize is %i, number of runs %i and burn-in %i\n", gid, offsets[gid], params[0],params[1], params[2],params[3]);
    
    printf("------------NodeFreqs--------------\n");
    for(i=0; i<params[0];i++){
        printf("%f, ", nodeFreqs[i]);
    }
    printf("\n\n");
    
    
    printf("------------Infnet--------------\n");
    for(i=0; i<(params[0]);i++){
        printf("Node, %i\n", i);
        printf("Influenced By\n");
        for(int j=0; j<params[1]; j++){
            printf("%i ", infnet[(j+infoffset)]);
        }
        infoffset = infoffset + params[1];
        printf("\nInfluences\n");
        for(int j=0; j<params[1]; j++){
            printf("%i ", infnet[(j+infoffset)]);
        }
        infoffset = infoffset + params[1];
        printf("\n\n");
    }
    
                                  
    printf("------------Cptnet--------------\n");
    for(i=0; i<(params[0]);i++){
        printf("Node, %i\n", i);
        printf("CPT\n");
        for(int j=0; j<sparseCPTsize; j++){
            printf("%f ", cptnet[(j+cptoffset)]);
        }
        cptoffset = cptoffset + sparseCPTsize;
        printf("\n\n");
    }
                                  
    
    
    printf("------------BNRESULTS--------------\n");
    for(i=0; i<params[0];i++){
        printf("%f, ", bnresults[i+boffset]);
        
    }
    printf("\n\n");
    
    
    printf("------------PriorDistType--------------\n");
    for(i=0; i<params[0];i++){
        printf("%i, ", priordisttypes[i]);
    }
    printf("\n\n");
    
    printf("------------PriorV1s--------------\n");
    for(i=0; i<params[0];i++){
        printf("%f, ", priorv1s[i]);
    }
    printf("\n\n");
    
    
    printf("------------PriorV2s--------------\n");
    for(i=0; i<params[0];i++){
        printf("%f, ", priorv2s[i]);
    }
    printf("\n\n");
    
                                  
    printf("--------------------------\n");
    */
    
    
    //****************************************************************
    //****************************************************************
    
    infoffset = 0;
    cptoffset = 0;
    
    
    
    //****************************************************************
    //****************************************************************
    //TEMPS CHECK
    //****************************************************************
    //****************************************************************
    
    for(i=0; i<(params[0]);i++){
        bnstates[i+boffset] = pointroll(&tinymt, nodeFreqs[i]); //Randomly set an initial state for each variable
        shufflenodes[i+shuffleoffset] = i; //Initialize the nodes array in sequential order
    }
    /*
    printf("------------BNStates--------------\n");
    for(i=0; i<(params[0]);i++){
        printf("%i ", bnstates[i+boffset]);
    }
    
    printf("\n\n");
    
    printf("------------Shufflenodes--------------\n");
    for(i=0; i<(params[0]);i++){
        printf("%i ", shufflenodes[i+shuffleoffset]);
    }
    printf("\n\n");
*/
  

    //****************************************************************
    //****************************************************************
    //MAIN RUN LOOP
    //****************************************************************
    //****************************************************************
    for(g=0; g<params[2]; g++){
        
        
        
        
        //Fisher-Yates shuffle: randomly sort the node array
        __local int j;
        j = 0;
        __local int tmp;
        tmp = 0;
        for (i = params[0] - 1; i > 0; i--) {
            j = randomx(&tinymt, i + 1);
            tmp = shufflenodes[j+shuffleoffset];
            shufflenodes[j+shuffleoffset] = shufflenodes[i+shuffleoffset];
            shufflenodes[i+shuffleoffset] = tmp;
        }
        

        
       //    printf("\n\nRUN %i ************************\n", g);
        
        //Cycle through each of the nodes
        for(h=0; h<params[0]; h++){ //The count var h will only be used to count through the zrray for size
            
            
            
            int sn = shufflenodes[h+shuffleoffset]; //The var sn will mark the location of the data for the present shuffled node
            //printf("gid %i run %i seed %i node %i becomes shuffled node %i \n", gid, g, x, h, sn);
            
         //   printf("node %i*************\n\n", sn);
            
            for(i=0; i<(params[0]);i++){
                parentnodes[i+shuffleoffset] = -1;
                lastvisitedchild[i+shuffleoffset] = -1;
            }
            
            /*
            printf("------------Parentnodes--------------\n");
            for(i=0; i<(params[0]);i++){
                printf("%i ", parentnodes[i+shuffleoffset]);
            }
            printf("\n\n");
            
            printf("------------LastVisitedChild--------------\n");
            for(i=0; i<(params[0]);i++){
                printf("%i ", lastvisitedchild[i+shuffleoffset]);
            }
            printf("\n\n");
            */
            
            laststate = bnstates[sn+boffset]; //Save what the state of the current node was, to check for approach to stationary distribution
            
            
            bnstates[sn+boffset] = 1;  //Set the state of the current variable to true. Thus we are asking for this node "what is the chance, given its influences, that this node is true?"
            
            infoffset = (params[1]*2) * sn; //Location in input array
            cptoffset = sparseCPTsize * sn; //Location in CPT array
            
            
            

            
            
            //
            //****************************************************************
            //****************************************************************
            //Morris Traversal
            //****************************************************************
            //****************************************************************
            __local int cur_node;
            cur_node = sn; //root of tree
            __local bool run_visit;
            run_visit = true;
            __local int oldparent;
            oldparent = -1;
            __local int next_child;
            next_child = -1;
            __local int parentholder;
            parentholder = -1;
            __local float product;
            product = 1.0;
            __local double flip;
            flip = -999.00;
            __local int curoffset;
            __local int parentoffset;
            
              //  printf("state of %i WAS %i\n", sn, bnstates[sn+boffset]);
            while (cur_node >=0){
                curoffset = (params[1]*2) * cur_node; //Location in input array
                
               //    printf("\ncur_node %i  parent %i lvc %i\n", cur_node, parentnodes[cur_node+shuffleoffset], lastvisitedchild[cur_node+shuffleoffset]);
                if(run_visit == true){
                    // printf("VISIT  node %i\n", cur_node);

                    if(infnet[curoffset] >= 0) {//the first infBy not -1 means this node has children
                        //      printf("has children, dependent node. State currenbtly %i\n", bnstates[cur_node+curoffset]);
                        next_child = 0;//next child is the first one
                        
                        if(bnstates[cur_node+curoffset] == 1){
                            product *= nodeFreqs[cur_node+curoffset];
                        }
                        else{
                            product *= (1.0-nodeFreqs[cur_node+curoffset]);
                        }
                        
                    }
                    else{
                         //   printf("has NO children. independent node\n");
                        
                        
                        
                        while(flip < 0 || flip > 1){
                            switch(priordisttypes[sn]) {
                                case 0: //point
                                    flip = priorv1s[sn];
                                    break;
                                case 1: // uniform
                                    flip = unidev(&tinymt, priorv1s[sn], priorv2s[sn]);
                                    break;
                                case 2: //gaussian
                                    flip = priorv2s[sn] * gasdev(&tinymt) + priorv1s[sn];
                                    break;
                                case 3: //beta
                                    flip = beta_dev(priorv1s[sn], priorv2s[sn], &tinymt);
                                    break;
                                case 4: // gamma
                                    flip = gamma_dev(priorv1s[sn]/priorv2s[sn], &tinymt);
                                    break;
                                case 5: //priorpost FIXME
                                    flip = -5;
                                    break;
                                default:
                                    flip = -999;
                            }
                        }
                          //  printf("disttype: %i  flip: %g\n", priordisttypes[sn], flip);
                        product *= flip;
                        next_child = -1; //no childen
                    }
                }
                
                else{
                     // printf("get next sibling\n");
                    next_child = lastvisitedchild[cur_node+shuffleoffset] + 1;
                }
                
                   // printf("position of next_child is %i  which is a %i \n", next_child, infnet[curoffset+next_child]);
                
                if(next_child >=0 && infnet[curoffset+next_child] >=0){ //if we are NOT at end of children
                    oldparent = cur_node;
                    parentoffset = (params[1]*2) * cur_node; //Location in input array
                    cur_node = infnet[parentoffset+next_child];
                    parentnodes[cur_node+shuffleoffset] = oldparent;
                     // printf("not at end. going to child %i whose parent is %i\n", cur_node, parentnodes[cur_node+shuffleoffset]);
                    run_visit = true;
                    
                }
                else{ //if we ARE at end of children
                    
                    
                    parentholder = cur_node;
                    cur_node = parentnodes[cur_node+shuffleoffset];
                    
                    lastvisitedchild[cur_node+shuffleoffset]++;
                    lastvisitedchild[parentholder+shuffleoffset]= -1;
                    
                    parentnodes[parentholder+shuffleoffset] = -1;
                    parentholder = -1;
                     //  printf("at end. going up to parent %i lvc %i whose own parent is %i\n", cur_node, lastvisitedchild[cur_node+shuffleoffset], parentnodes[cur_node+shuffleoffset]);
                    run_visit = false;
                    
                }
            }
            
            //****************************************************************
            //****************************************************************
            
            //  printf("PRODUCT %f\n", product);
            bnstates[sn+boffset] = pointroll(&tinymt, product);
           //  printf("state of %i is now %i\n", sn, bnstates[sn+boffset]);
            
            
            //****************************************************************
            
            
            
            //Iterate through the nodes that influence this node to create the binary sum of the influences
         //   binsum = 0;
           // binx =0;
            /*
             for (i=infoffset; i<(infoffset+params[1]); i++){
             if(infnet[i] < 0) break;
             binsum += bnstates[(infnet[i]+boffset)] * pow(2.0f, binx);
             binx++;
             }
             
             
             if(cptnet[(cptoffset+binsum)] < 0) { //If a -1 was passed to the cptnet, there is no CPT for this node because it is a
             bnstates[sn+boffset] = pointroll(&tinymt, nodeFreqs[sn]);
             }
             else { //There is a CPT for this node, so the chance for the node to be true comes from the probablities of its influencdes
             bnstates[sn+boffset] = pointroll(&tinymt, (cptnet[(cptoffset+binsum)]*nodeFreqs[sn]));  //FIXME is this right? times nodefreqs
             
             
             
             
             }
             
             */
            
            
            infoffset +=params[1]; //Advance the influence offset by the size of a CPT
            if(bnstates[sn+boffset] == laststate) runstationary++; //If the state is not changing, take note, and check to exit early
            
            
           // printf("end nodes loop using h\n");
            //End nodes loop using h as a count variable
        }
        
        
        
        //Begin to record results after burnins value exceeded
        if(g>=params[3]){
            for(k=0; k<params[0]; k++){
                bnresults[k+boffset] += bnstates[k+boffset];
            }
            sampletot++;
        }
        
        
        //FIXME this is sometimes retiurn results > 1
        //  if(runstationary >= params[3] || runstationary >= (params[2]/10)) break; //Check to see if stationary distribution reached. Breaks if exceeds burnins or one tenth of total assigned runs.
        
        //END loop of runs with count variable g
    }
    
    
    for(int l=0; l<params[0]; l++){
        bnresults[l+boffset] /= sampletot; //To obtain posterior point, divide the compiled results through by number of samples taken
    }
    
    
    //END kernel
}
