/* RNG borrowed from Ian Henderson at http://inst.cs.berkeley.edu/~ianh/proj1.html
*/

typedef struct { ulong a, b, c } random_state;


unsigned long random(random_state *r)
{
    unsigned long old = r->b;
    r->b = r->a * 1103515245 + 12345;
    r->a = (~old ^ (r->b >> 3)) - r->c++;
    return r->b;
}

float random_01(random_state *r)
{
    return (random(r) & 4294967295) / 4294967295.0f;
}


void seed_random(random_state *r, ulong seed)
{
    r->a = seed;
    r->b = 0;
    r->c = 362436;
}


int randomx(random_state *r, int max)
{
    return (random_01(r)*max);
}

int pointroll(random_state *r, float threshold)
{
    if(random_01(r)< threshold) return 1;
    return 0;

}

float uniformroll(random_state *r, float v1, float v2)
{
    return (((v2-v1)*random_01(r))+v1);
}





__kernel void BNGibbs(__constant int* offsets, int bnsize, int maxCPTsize, __constant float* nodeFreqs, __constant int* infnet, __constant float* cptnet, __global int* bnstates, __global float *bnresults, __global int* results, int runs, int burnins)
{
    int gid = get_global_id(0); //A global identifier for this work-item. Used top access its part of the offset, bnstates and results

    int boffset = gid*bnsize; //offset to part of bnstates buffer used by this work-item

    int sparseCPTsize = pow(2.0f, maxCPTsize);


   // printf("work id is %i, number of runs %i and burn-in %i\n", gid, runs, burnins);
    
   // printf("work id is %i, number of runs %i and burn-in %i and nodeFreq[0] is %f\n", gid,  nodeFreqs[0]);
    
    //Seed rng
    int x = get_global_id(0) + offsets[gid]*get_global_size(0);
    int y = get_global_id(1) + (offsets[gid]+1)*get_global_size(1);
    random_state randstate;
    seed_random(&randstate, x + y*640);

    
    //Count vars
    int g, h, i, k = 0;


    int binsum = 0;
    float binx =0;
    
    int infoffset = 0;
    int cptoffset = 0;
    

    
    
    int sampletot = 0;
    int laststate = -1;
    int runstationary = 0; //number of times in a row the chosen state is the same as before...used to see if we are converging on a stationary distn

    //Set initial states FIXME... priors?
   // printf("--------------------------\n");
   // printf("work id is %i\n", gid);
   // printf("bnsize is %i\n", bnsize);
    
    int shufflenodes[bnsize];
    
    for(i=0; i<(bnsize);i++){
        bnstates[i+boffset] = pointroll(&randstate, nodeFreqs[i]);
        shufflenodes[i] = i;
   //     printf("initial state %i is %i\n", i, bnstates[i+boffset]);
    }
    
    //create randomly sorted array
    //Fisher-Yates shuffle
    /*
    for (i = bnsize - 1; i > 0; i--) {
        j = randomx(&randstate, i + 1);
        tmp = shufflenodes[j];
        shufflenodes[j] = shufflenodes[i];
        shufflenodes[i] = tmp;
    }
    */
    
    /*
    printf("--------------------------\n");
    printf("Shuffled node for work id is %i\n", gid);
    for(i=0; i<(bnsize);i++){
        printf("%i, ", shufflenodes[i]);
    }
    printf("\n\n");
    */

    
    //RUN to a hard limit FIXME hardcoded for now, make this assignable) unless the distn becomes stationary
    for(g=0; g<runs; g++){
   //     for(g=0; g<10000; g++){

        //CYCLE through each of the nodes one at a time
        for(h=0; h<bnsize; h++){
            
         //   printf("Node %i ", h);
            
           // sn = shufflenodes[h]; //FIXME this will be used instead of h

            //save what the state was to check later
            laststate = bnstates[h+boffset];
        
            //clear the state of the current variable
            //First set it to true, so that we are asking "what is chance if true..."
            bnstates[h+boffset] = 1;

            infoffset = (maxCPTsize*2) * h;
            cptoffset = sparseCPTsize * h;


          //  printf("infoffset %i\n\n", infoffset);
            
            //Go through influenced BY, and you'll want the CPT of the INFLUENCED - the current one
            //int binsum = bininfluence(infoffset, maxCPTsize, infnet, &bn_states);

            binsum = 0;
            binx =0;

            for (i=infoffset; i<(infoffset+maxCPTsize); i++){
                if(infnet[i] < 0) break;
                binsum += bnstates[(infnet[i]+boffset)] * pow(2.0f, binx);

                binx++;
            }

          //  printf("recived binsum %i ", binsum);
            
            
            if(cptnet[(cptoffset+binsum)] < 0) {
                //its an independent node and you just want it's nodefreq

                bnstates[h+boffset] = pointroll(&randstate, nodeFreqs[h]);
              //  printf(" which is the chance %f ", nodeFreqs[h]);

                }
            else {
                
               // printf(" which is the chance %f ", cptnet[(cptoffset+binsum)]*nodeFreqs[h]);
                
                bnstates[h+boffset] = pointroll(&randstate, (cptnet[(cptoffset+binsum)]*nodeFreqs[h]));  //is this right? times nodefreqs
                
            }
            
           // printf(" and the roll is %i\n", bnstates[h+boffset]);

            infoffset +=maxCPTsize;
           // printf("infoffset now %i\n\n", infoffset);

           // printf(" and is %i\n", bnstates[(h+boffset)]);
            if(bnstates[h+boffset] == laststate) runstationary++;
            
        //end h loop
        }

        //Allow for burn-in, only sample every 100th afterward
        if(g>burnins && g%100==0){
        //    if(g>100 && g%100==0){
            //put in distn here
            for(k=0; k<bnsize; k++){
                bnresults[k+boffset] += bnstates[k+boffset];
            }
            sampletot++;
        }
            
        //how far did it get? -- FIXME remove this once you know this is behaving well
        results[gid] = g;

        //Check to see if stationary (FIXME limit hardcoded for now)
        //if(runstationary >= 1000) break;
    
        //end g loop
    }
    
    //divide through by number of recordings made
    for(int l=0; l<bnsize; l++){
        bnresults[l+boffset] /= sampletot;
       // printf("work id is %i, node %i, buffer loc %i, results %f\n", gid, l, (l+boffset) , bnresults[l+boffset]);
        
    }
    //This is an average drawn from the posterior distn


//end kernel
}
