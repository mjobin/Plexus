//
//  BNGibbs.metal
//  Plexus
//
//  Created by matt on 12/18/16.
//  Copyright © 2016 Santa Clara University. All rights reserved.
//

#include <metal_stdlib>
#include "mt.h" 
using namespace metal;


kernel void bngibbs(const device unsigned int *rngseeds [[buffer(0)]], device float *bnresults [[buffer(1)]], const device unsigned int *p [[buffer(2)]], const device unsigned int *priordisttypes [[buffer(3)]], const device float *priorv1s [[buffer(4)]], const device float *priorv2s[[buffer(5)]], const device int *infnet [[buffer(6)]], const device float *cptnet [[buffer(7)]], device uint *shufflenodes[[buffer(8)]], device float *bnstates[[buffer(9)]], const device float *postpriors [[buffer(10)]], uint gid [[thread_position_in_grid]]){

    //p[0] = runs per
    //p[1] = burnins
    //p[2] = nodes count
    //p[3] = maxInfSize
    //p[4] = maxCPTSize
    //p[5] = maxPPsize
    unsigned int g, h, i,j, k, sn, tmp = 0;
    int binsum = 0;
    float binx = 0;
    float flip = -999.99;
    int tot = 0;
    

    //Offsets
    //Rngseeds: gid
    //BNresults: gid*nodescount -> boff
    //Shufflenodes: gid*nodescount -> boff
    //BNStates: gid*nodescount -> boff
    int boff = gid*p[2];
    //Infnet: maxinfsize -> p[3]*sn
    int ioff = 0;
    //Cptnet: maxCPTsize -> p[4]*sn
    int coff = 0;
    //Postpriors: maxPPsize -> p[5]*sn
    int ppoff = 0;

    
    //Initialize and seed RNG
    mt19937 mt;
    mt.srand(rngseeds[gid]);
    
   
    //Initialize node order
    for(i=0; i<p[2]; i++){
        bnstates[boff+i] = mt.pointroll(0.5);
        shufflenodes[boff+i] = i;
    }
    
    bnresults[boff] = infnet[0];
    bnresults[boff+1] = infnet[1];
    
    for (g=0; g<p[0]; g++){
        
        //Fisher-Yates shuffle: randomly sort the node array
        j = 0;
        tmp = 0;
        for ( i = p[2]-1; i > 0; i--) {
            j = mt.randomx(i + 1);
            tmp = shufflenodes[boff+j];
            shufflenodes[boff+j] = shufflenodes[boff+i];
            shufflenodes[boff+i] = tmp;
        }
        
        for(h=0; h<p[2]; h++){ //The count var h will only be used to count through the array for size
            sn = shufflenodes[boff+h]; //The var sn will mark the location of the data for the present shuffled node
            
            //Iterate through the nodes that influence this node to create the binary sum of the influences
            binsum = 0;
            binx = 0;
            ioff = p[3]*sn;
            coff = p[4]*sn;
            ppoff = p[5]*sn;

            
            for (i=ioff; i<(ioff+p[3]); i++){
                if(infnet[i]<0) break;
                binsum += bnstates[infnet[i]+boff] * pow(2.0f, binx);
                binx++;
            }
            
            if(cptnet[coff+binsum] < 0) {
                
                //FIXME inster distns
                flip = -999.99;
                while(flip < 0 || flip > 1){
                    switch(priordisttypes[sn]) {
                        case 0: //point
                            flip = priorv1s[sn];
                            break;
                        case 1: // uniform
                            flip = mt.unidev(priorv1s[sn], priorv2s[sn]);
                            break;
                        case 2: //gaussian
                            flip = priorv2s[sn] * mt.gasdev() + priorv1s[sn];
                            break;
                        case 3: //beta
                            flip = mt.beta_dev(priorv1s[sn], priorv2s[sn]);
                            break;
                        case 4: // gamma
                            flip = mt.gamma_dev(priorv1s[sn]/priorv2s[sn]);
                            break;
                        case 5: //Posterior Prior
                            flip = postpriors[ppoff+mt.randomx(p[5])];
                            break;
                        default:
                            flip = priorv1s[sn];
                            break;
                    }
                    
                }

                bnstates[sn+boff] = mt.pointroll(flip);
                
            }
            
            else {
                bnstates[sn+boff] = mt.pointroll(cptnet[coff+binsum]);
            }
        }
        
        //Begin to record results after burnins value exceeded
        if(g>=p[1]){
            for(k=0; k<p[2]; k++){
                bnresults[k+boff] += bnstates[k+boff];
            }
            tot++;
        }
        
     //END g loop
    }
    
    
    //Output
    for(i=0; i<p[2]; i++){
        bnresults[boff+i] /= tot;
    }
//    if(gid <= p[4]*p[2]){
//        testout[gid] = cptnet[gid];
//    }


    
}
