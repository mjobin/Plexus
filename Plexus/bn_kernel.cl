/* BNGibbs Kernel Matthew Jared Jobin 2015
 *
 *
 *
 *
 *
 *
 */


#include "tinymt32_jump.clh"



int randomx(tinymt32j_t *r, int max)
{
    return (tinymt32j_single01(r)*max);
}

int pointroll(tinymt32j_t *r, float threshold)
{
    if(tinymt32j_single01(r)< threshold) return 1;
    return 0;
    
}



//Monte Carlo Gibbs Sampler
__kernel void BNGibbs(__constant int* offsets, int bnsize, int maxCPTsize, __constant float* nodeFreqs, __constant int* infnet, __constant float* cptnet, __global int* bnstates, __global float *bnresults, __global int* results, int runs, int burnins)
{
    int gid = get_global_id(0); //A global identifier for this work-item. Used to access its part of the offset, bnstates and results

    int boffset = gid*bnsize; //offset to part of bnstates buffer used by this work-item

    int sparseCPTsize = pow(2.0f, maxCPTsize);


  //  printf("--------------------------\n");
   // printf("work id is %i, number of runs %i and burn-in %i\n", gid, runs, burnins);
    
    //Seed variable for random number generator
    int x = offsets[gid]*get_global_size(0);
    printf("%i\n", x);

    
    //TinyMT seed and test
   tinymt32j_t tinymt;
   tinymt32j_init_jump(&tinymt, (x)); //init the rng to to something somewhat random within each thread



    
    //Count variables
    int g, h, i, k = 0;


    int binsum = 0;
    float binx =0;
    
    int infoffset = 0;
    int cptoffset = 0;
    
    
    int sampletot = 0;
    int laststate = -1;
    int runstationary = 0; //number of times in a row the chosen state is the same as before...used to see if we are converging on a stationary distn

    //Set initial states FIXME... priors?


    
    int shufflenodes[bnsize];

    
    for(i=0; i<(bnsize);i++){
        bnstates[i+boffset] = pointroll(&tinymt, nodeFreqs[i]); //randomly set an initial state for each variable
        shufflenodes[i] = i; //initialize the nodes array in sequential order
     //   printf("initial state %i is %i\n", i, bnstates[i+boffset]);
     //   printf("shufflenodes %i is %i\n", i, shufflenodes[i]);
    }
    
    
    /*
    //Fisher-Yates shuffle
    //Randomly sort the node array
    int j, tmp = 0;
    for (i = bnsize - 1; i > 0; i--) {
        j = randomx(&tinymt, i + 1);
        tmp = shufflenodes[j];
        shufflenodes[j] = shufflenodes[i];
        shufflenodes[i] = tmp;

    }
    
    */
    /*
    printf("--------------------------\n");
    printf("Shuffled node for work id %i\n", gid);
    for(i=0; i<(bnsize);i++){
        printf("%i, ", shufflenodes[i]);
    }
    printf("\n\n");
    */
    

    for(g=0; g<runs; g++){


        //CYCLE through each of the nodes one at a time
        for(h=0; h<bnsize; h++){
            
            //printf("Node %i ", h);
            
          // int sn = shufflenodes[h]; //FIXME this will be used instead of h
          // printf("becomes shuffled node %i \n", sn);

            //save what the state was to check later
            laststate = bnstates[h+boffset];
        
            //clear the state of the current variable
            //First set it to true, so that we are asking "what is chance if true..."
            bnstates[h+boffset] = 1;

            infoffset = (maxCPTsize*2) * h;
            cptoffset = sparseCPTsize * h;


         //   printf("infoffset %i\n", infoffset);
            
            //Go through influenced BY, and you'll want the CPT of the INFLUENCED - the current one
            //int binsum = bininfluence(infoffset, maxCPTsize, infnet, &bn_states);

            binsum = 0;
            binx =0;

            for (i=infoffset; i<(infoffset+maxCPTsize); i++){
                if(infnet[i] < 0) break;
                binsum += bnstates[(infnet[i]+boffset)] * pow(2.0f, binx);

                binx++;
            }

         //   printf("recived binsum %i ", binsum);
            
            
            if(cptnet[(cptoffset+binsum)] < 0) {
                //its an independent node and you just want its nodefreq

                //bnstates[h+boffset] = pointroll(&randstate, nodeFreqs[h]);
                bnstates[h+boffset] = pointroll(&tinymt, nodeFreqs[h]);
             //   printf(" which is the chance %f ", nodeFreqs[h]);

                }
            else {
                
             //   printf(" which is thee chance %f ", cptnet[(cptoffset+binsum)]*nodeFreqs[h]);
                
                bnstates[h+boffset] = pointroll(&tinymt, (cptnet[(cptoffset+binsum)]*nodeFreqs[h]));  //is this right? times nodefreqs
                
            }
            
         //   printf(" and the roll is %i\n", bnstates[h+boffset]);

            infoffset +=maxCPTsize;
          //  printf("infoffset now %i\n\n", infoffset);


            if(bnstates[h+boffset] == laststate) runstationary++;
            
        //end h loop
        }

        //Allow for burn-in, only sample every 100th afterward
        //FIXME RESTORE FOR REALif(g>burnins && g%100==0){
            if(g>=burnins){
            
           // printf("in bnresults loop\n");
            
            for(k=0; k<bnsize; k++){
                bnresults[k+boffset] += bnstates[k+boffset];
            }
            sampletot++;
        }
            
        //how far did it get? -- FIXME remove this once you know this is behaving well
        results[gid] = g;

        //Check to see if stationary
        if(runstationary >= burnins || runstationary >= (runs/10)) break;
    
        //end g loop
    }
    
    //divide through by number of recordings made
    for(int l=0; l<bnsize; l++){
        bnresults[l+boffset] /= sampletot;
      //  printf("work id is %i, node %i, buffer loc %i, sampletot %i, results %f\n", gid, l, (l+boffset) , sampletot, bnresults[l+boffset]);
        
    }
    //This is an average drawn from the posterior distn


//end kernel
}
