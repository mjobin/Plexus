//
//  UserInput.c
//  Plexus
//
//  Created by matt on 4/28/2015.
//  Copyright (c) 2015 Matthew Jobin. All rights reserved.
//

#include <stdio.h>
#include <math.h>




/* (C) Copr. 1986-92 Numerical Recipes Software Y5jc. */
//------------------------------------------------------------------------------
#define MBIG 1000000000L
#define MSEED 161803398L
#define MZ 0
#define FAC (1.0/MBIG)

double ran3(long *idum)
{
    static int inext,inextp;
    static long ma[56];
    static int iff=0;
    long mj,mk;
    int i,ii,k;
    
    if ((*idum < 0) || (iff == 0) ) {
        iff=1;
        mj=MSEED-(*idum < 0 ? -*idum : *idum);
        mj %= MBIG;
        ma[55]=mj;
        mk=1;
        for (i=1;i<=54;++i) {
            ii=(21*i) % 55;
            ma[ii]=mk;
            mk=mj-mk;
            if (mk < MZ) mk += MBIG;
            mj=ma[ii];
        }
        for (k=1;k<=4;++k)
            for (i=1;i<=55;++i) {
                ma[i] -= ma[1+(i+30) % 55];
                if (ma[i] < MZ) ma[i] += MBIG;
            }
        inext=0;
        inextp=31;
        *idum=1;
    }
    if (++inext == 56) inext=1;
    if (++inextp == 56) inextp=1;
    mj=ma[inext]-ma[inextp];
    if (mj < MZ) mj += MBIG;
    ma[inext]=mj;
    
    
    
    //for debug
    if( (mj*FAC) >= 1.0){
        mj=(MBIG-1);
        return mj*FAC;
    }
    else{
        return mj*FAC;
    }
    
    
    
}
#undef MBIG
#undef MSEED
#undef MZ
#undef FAC

//------------------------------------------------------------------------------
// Modified from NumRep 2 p289-290
double gasdev(long *idum)
{
    double ran3(long *idum);
    //float ran3(long *idum);
    static int iset=0;
    //static float gset;
    static double gset;
    //float fac,rsq,v1,v2;
    double fac,rsq,v1,v2;
    
    
    if (*idum < 0) iset=0;
    if  (iset == 0) {
        do {
            v1=2.0*ran3(idum)-1.0;
            v2=2.0*ran3(idum)-1.0;
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
double igamma_dev(int ia)
{
    int j;
    double am,e,s,v1,v2,x,y;
    long lidum=1L;
    
    if (ia < 1)
    {
        printf("Error: arg of igamma_dev was <1\n");

       // exit(1);
    }
    if (ia < 6)
    {
        x=1.0;
        for (j=0; j<ia; j++)
            x *= ran3(&lidum);
        x = -log(x);
    }else
    {
        do
        {
            do
            {
                do
                {                         /* next 4 lines are equivalent */
                    v1=2.0*ran3(&lidum)-1.0;       /* to y = tan(Pi * uni()).     */
                    v2=2.0*ran3(&lidum)-1.0;
                }while (v1*v1+v2*v2 > 1.0);
                y=v2/v1;
                am=ia-1;
                s=sqrt(2.0*am+1.0);
                x=s*y+am;
            }while (x <= 0.0);
            e=(1.0+y*y)*exp(am*log(x/am)-s*y);
        }while (ran3(&lidum) > e);
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
gamma_dev(double a) {
    
    int ia;
    double u, b, p, x, y=0.0, recip_a;
    long lidum=1L;
    
    if(a <= 0) {
        printf("\ngamma_dev: parameter must be positive\n");
      //  exit(1);
    }
    
    ia = (int) (floor(a));  /* integer part */
    a -= ia;        /* fractional part */
    if(ia > 0) {
        y = igamma_dev(ia);  /* gamma deviate w/ integer argument ia */
        if(a==0.0) return(y);
    }
    
    /* get gamma deviate with fractional argument "a" */
    b = (M_E + a)/M_E;
    recip_a = 1.0/a;
    for(;;) {
        u = ran3(&lidum);
        p = b*u;
        if(p > 1) {
            x = -log( (b-p)/a );
            if( ran3(&lidum) > pow(x, a-1)) continue;
            break;
        }
        else {
            x = pow(p, recip_a);
            if( ran3(&lidum) > exp(-x)) continue;
            break;
        }
    }
    return(x+y);
}


//****************************************************************
//MJJ 4/29/15
double beta_dev(double a, double b) {
    double x = gamma_dev(a);
    double y = gamma_dev(b);
    return x/(x+y);
}
