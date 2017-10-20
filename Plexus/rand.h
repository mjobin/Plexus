//
//  rand.h
//  Plexus
//
//  Created by matt on 3/16/17.
//  Copyright © 2017 Santa Clara University. All rights reserved.
//
#include <metal_stdlib>
using namespace metal;

#ifndef rand_h
#define rand_h
uint wang_hash(uint seed);
uint rand_lcg(thread uint *rng_state);
uint rand_xorshift(thread uint *rng_state);
float xorfloat(thread uint *rng_state);
uint randomx(thread uint *rng_state, uint s);
uint pointroll(thread uint *rng_state, float threshold);
float unidev (thread uint *rng_state, float v1, float v2);
float gasdev(thread uint *rng_state);
float igamma_dev(thread uint *rng_state, int ia);
float gamma_dev(thread uint *rng_state, float a);
float beta_dev(thread uint *rng_state, float a, float b);


float genbet (thread uint *rng_state, float aa, float bb );
float gengam (thread uint *rng_state, float a, float r );
float gennor (thread uint *rng_state, float av, float sd );
float r4_exp ( float x );
float r4_max ( float x, float y );
float r4_min ( float x, float y );
float sexpo (thread uint *rng_state );
float sgamma (thread uint *rng_state, float a );
float snorm (thread uint *rng_state );


#endif /* rand_h */
