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
__kernel void BNGibbs(__constant int* offsets, int bnsize, int maxCPTsize, __constant float* nodeFreqs, __constant int* infnet, __constant float* cptnet, __global int* bnstates, __global float *bnresults, __local int* shufflenodes, int runs, int burnins)
{
    int gid = get_global_id(0); //A global identifier for this work-item. Used to access its part of the offset, bnstates and results

    int boffset = gid*bnsize; //offset to part of bnstates buffer used by this work-item

    int sparseCPTsize = pow(2.0f, maxCPTsize);


  //  printf("--------------------------\n");
   // printf("work id is %i, number of runs %i and burn-in %i\n", gid, runs, burnins);
    
    //Seed variable for random number generator
    int x = offsets[gid]*get_global_size(0);


    
    //TinyMT seed and test
   tinymt32j_t tinymt;
   tinymt32j_init_jump(&tinymt, (x)); //init the rng to to something somewhat random within each thread



    
    //Count variables
    int g, h, i, k = 0;


    int binsum = 0; //Binary sum of the states of all the nodes that influence the current node
    float binx = 0; //Float coutn variable, needed because will be using 2.0^binx
    
    int infoffset = 0; //Offset variale for influences array
    int cptoffset = 0; //Offset variale for CPT array
    
    
    int sampletot = 0; //Number of sampled results
    int laststate = -1; //Previous state of a node, used to check for a stationary distribution
    int runstationary = 0; //Number of times in a row the chosen state is the same as before. Used to see if we are converging on a stationary distritbution.

    int shuffleoffset = gid * bnsize;

  //  printf("gid %i and shuffle array start is %i\n", gid, shuffleoffset);
    
    
    for(i=0; i<(bnsize);i++){
        bnstates[i+boffset] = pointroll(&tinymt, nodeFreqs[i]); //Randomly set an initial state for each variable
        shufflenodes[i+shuffleoffset] = i; //Initialize the nodes array in sequential order
    }
    
    

    
    //Main run loop
    for(g=0; g<runs; g++){

        //Fisher-Yates shuffle: randomly sort the node array
        int j, tmp = 0;
        for (i = bnsize - 1; i > 0; i--) {
            j = randomx(&tinymt, i + 1);
            tmp = shufflenodes[j+shuffleoffset];
            shufflenodes[j+shuffleoffset] = shufflenodes[i+shuffleoffset];
            shufflenodes[i+shuffleoffset] = tmp;
        }

        //Cycle through each of the nodes
        for(h=0; h<bnsize; h++){ //The count var h will only be used to count through the zrray for size
            
            
           int sn = shufflenodes[h+shuffleoffset]; //The var sn will mark the location of the data for the present shuffled node
          // printf("gid %i run %i seed %i node %i becomes shuffled node %i \n", gid, g, x, h, sn);

            
            laststate = bnstates[sn+boffset]; //Save what the state of the current node was, to check for approach to stationary distribution
        

            bnstates[sn+boffset] = 1;  //Set the state of the current variable to true. Thus we are asking for this node "what is the chance, given its influences, that this node is true?"

            infoffset = (maxCPTsize*2) * sn; //Location in input array
            cptoffset = sparseCPTsize * sn; //Location in CPT array

            
            //Iterate through the nodes that influence this node to create the binary sum of the influences
            binsum = 0;
            binx =0;
            for (i=infoffset; i<(infoffset+maxCPTsize); i++){
                if(infnet[i] < 0) break;
                binsum += bnstates[(infnet[i]+boffset)] * pow(2.0f, binx);
                binx++;
            }
            

            if(cptnet[(cptoffset+binsum)] < 0) { //If a -1 was passed to the cptnet, there is no CPT for this node because it is a parent node
                //The state of the result comes from the frequency derived from the prior distribution
                //   i.e. in a uniform distribution of 0-1, this particular run might have been given a 0.546, and that is what is used here
                bnstates[sn+boffset] = pointroll(&tinymt, nodeFreqs[sn]);
                }
            else { //There is a CPT for this node, so the chance for the node to be true comes from the probablities of its influencdes
                bnstates[sn+boffset] = pointroll(&tinymt, (cptnet[(cptoffset+binsum)]*nodeFreqs[sn]));  //is this right? times nodefreqs
            }


            infoffset +=maxCPTsize; //Advance the influence offset by the size of a CPT


            if(bnstates[sn+boffset] == laststate) runstationary++; //If the state is not changing, take note, and check to exit early
            
        //End nodes loop using h as a count variable
        }

        
        //Begin to record results after burnins value exceeded
        if(g>=burnins){
                for(k=0; k<bnsize; k++){
                    bnresults[k+boffset] += bnstates[k+boffset];
                }
            sampletot++;
        }
            

        //FIXME this is sometimes retiurn results > 1
      //  if(runstationary >= burnins || runstationary >= (runs/10)) break; //Check to see if stationary distribution reached. Breaks if exceeds burnins or one tenth of total assigned runs.
    
       //END loop of runs with count variable g
    }
    
    for(int l=0; l<bnsize; l++){
        bnresults[l+boffset] /= sampletot; //To obtain posterior point, divide the compiled results through by number of samples taken
    }
    

//END kernel
}
