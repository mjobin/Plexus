//
//  rand.metal
//  Plexus
//
//  Created by matt on 3/16/17.
//  Copyright © 2017 Santa Clara University. All rights reserved.
//

#include <metal_stdlib>
#include "rand.h"
#define M_E 2.7182818284590452353602874713527f
using namespace metal;


uint wang_hash(uint seed)
{
    seed = (seed ^ 61) ^ (seed >> 16);
    seed *= 9;
    seed = seed ^ (seed >> 4);
    seed *= 0x27d4eb2d;
    seed = seed ^ (seed >> 15);
    return seed;
}

uint rand_xorshift(thread uint *rng_state)
{
    // Xorshift algorithm from George Marsaglia's paper
    *rng_state ^= (*rng_state << 13);
    *rng_state ^= (*rng_state >> 17);
    *rng_state ^= (*rng_state << 5);
    return (*rng_state);
}

float xorfloat(thread uint *rng_state)
{
    return rand_xorshift(rng_state)*(1.0/4294967295.0);
    /* divided by 2^32-1 */
}

uint randomx(thread uint *rng_state, uint s)
{
    return xorfloat(rng_state)*s;
}

uint pointroll(thread uint *rng_state, float threshold)
{
    if(xorfloat(rng_state) < threshold) return 1;
    return 0;
    
}

float unidev (thread uint *rng_state, float v1, float v2)
{
    return (xorfloat(rng_state)*(v2-v1)) + v1;
    
}

float gasdev(thread uint *rng_state)
{
    
    int iset=0;
    float gset = 0.0;
    float fac,rsq,v1,v2;
    
    
    if  (iset == 0) {
        do {
            v1=2.0*xorfloat(rng_state)-1.0;
            v2=2.0*xorfloat(rng_state)-1.0;
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


float igamma_dev(thread uint *rng_state, int ia)
{
    int j;
    float am,e,s,v1,v2,x,y;
    
    
    if (ia < 1)
    {
        //        print("Error: arg of igamma_dev was <1\n");
        //         exit(1);
        return -999;
    }
    if (ia < 6)
    {
        x=1.0;
        for (j=0; j<ia; j++)
            x *= xorfloat(rng_state);
        x = -log(x);
    }else
    {
        do
        {
            do
            {
                do
                {                         // next 4 lines are equivalent
                    v1=2.0*xorfloat(rng_state)-1.0;       // to y = tan(Pi * uni()).
                    v2=2.0*xorfloat(rng_state)-1.0;
                }while (v1*v1+v2*v2 > 1.0);
                y=v2/v1;
                am=ia-1;
                s=sqrt(2.0*am+1.0);
                x=s*y+am;
            }while (x <= 0.0);
            e=(1.0+y*y)*exp(am*log(x/am)-s*y);
        }while (xorfloat(rng_state) > e);
    }
    return(x);
}


float gamma_dev(thread uint *rng_state, float a)
{
    
    int ia;
    float u, b, p, x, y=0.0, recip_a;
    
    if(a <= 0) {
        // print("\ngamma_dev: parameter must be positive\n");
        //  exit(1);
        return -999;
    }
    
    ia = (int) (floor(a));  // integer part
    a -= ia;        // fractional part
    if(ia > 0) {
        y = igamma_dev(rng_state, ia);  // gamma deviate w/ integer argument ia
        if(a==0.0) return(y);
    }
    
    // get gamma deviate with fractional argument "a"
    b = (M_E + a)/M_E;
    recip_a = 1.0/a;
    for(;;) {
        u = xorfloat(rng_state);
        p = b*u;
        if(p > 1) {
            x = -log( (b-p)/a );
            if(xorfloat(rng_state) > pow(x, a-1)) continue;
            break;
        }
        else {
            x = pow(p, recip_a);
            if(xorfloat(rng_state) > exp(-x)) continue;
            break;
        }
    }
    return(x+y);
}




float beta_dev(thread uint *rng_state, float a, float b)
{
    float x = gamma_dev(rng_state, a);
    float y = gamma_dev(rng_state, b);
    return x/(x+y);
}



/******************************************************************************/

float genbet (thread uint *rng_state, float aa, float bb )

/******************************************************************************/
/*
 Purpose:
 
 GENBET generates a beta random deviate.
 
 Discussion:
 
 This procedure returns a single random deviate from the beta distribution
 with parameters A and B.  The density is
 
 x^(a-1) * (1-x)^(b-1) / Beta(a,b) for 0 < x < 1
 
 Licensing:
 
 This code is distributed under the GNU LGPL license.
 
 Modified:
 
 19 September 2014
 
 Author:
 
 Original FORTRAN77 version by Barry Brown, James Lovato.
 C version by John Burkardt.
 
 Reference:
 
 Russell Cheng,
 Generating Beta Variates with Nonintegral Shape Parameters,
 Communications of the ACM,
 Volume 21, Number 4, April 1978, pages 317-322.
 
 Parameters:
 
 Input, float AA, the first parameter of the beta distribution.
 0.0 < AA.
 
 Input, float BB, the second parameter of the beta distribution.
 0.0 < BB.
 
 Output, float GENBET, a beta random variate.
 */
{
    float a;
    float alpha;
    float b;
    float beta;
    float delta;
    float gamma;
    float k1;
    float k2;
    const float log4 = 1.3862943611198906188;
    const float log5 = 1.6094379124341003746;
    float r;
    float s;
    float t;
    float u1;
    float u2;
    float v;
    float value;
    float w;
    float y;
    float z;
    
//    if ( aa <= 0.0 )
//    {
//        fprintf ( stderr, "\n" );
//        fprintf ( stderr, "GENBET - Fatal error!\n" );
//        fprintf ( stderr, "  AA <= 0.0\n" );
//        exit ( 1 );
//    }
//    
//    if ( bb <= 0.0 )
//    {
//        fprintf ( stderr, "\n" );
//        fprintf ( stderr, "GENBET - Fatal error!\n" );
//        fprintf ( stderr, "  BB <= 0.0\n" );
//        exit ( 1 );
//    }
    /*
     Algorithm BB
     */
    if ( 1.0 < aa && 1.0 < bb )
    {
        a = r4_min ( aa, bb );
        b = r4_max ( aa, bb );
        alpha = a + b;
        beta = sqrt ( ( alpha - 2.0 ) / ( 2.0 * a * b - alpha ) );
        gamma = a + 1.0 / beta;
        
        for ( ; ; )
        {
            u1 = unidev(rng_state, 0.0, 1.0);;
            u2 = unidev(rng_state, 0.0, 1.0);;
            v = beta * log ( u1 / ( 1.0 - u1 ) );
            /*
             exp ( v ) replaced by r4_exp ( v )
             */
            w = a * r4_exp ( v );
            
            z = u1 * u1 * u2;
            r = gamma * v - log4;
            s = a + r - w;
            
            if ( 5.0 * z <= s + 1.0 + log5 )
            {
                break;
            }
            
            t = log ( z );
            if ( t <= s )
            {
                break;
            }
            
            if ( t <= ( r + alpha * log ( alpha / ( b + w ) ) ) )
            {
                break;
            }
        }
    }
    /*
     Algorithm BC
     */
    else
    {
        a = r4_max ( aa, bb );
        b = r4_min ( aa, bb );
        alpha = a + b;
        beta = 1.0 / b;
        delta = 1.0 + a - b;
        k1 = delta * ( 1.0 / 72.0 + b / 24.0 )
        / ( a / b - 7.0 / 9.0 );
        k2 = 0.25 + ( 0.5 + 0.25 / delta ) * b;
        
        for ( ; ; )
        {
            u1 = unidev(rng_state, 0.0, 1.0);;
            u2 = unidev(rng_state, 0.0, 1.0);;
            
            if ( u1 < 0.5 )
            {
                y = u1 * u2;
                z = u1 * y;
                
                if ( k1 <= 0.25 * u2 + z - y )
                {
                    continue;
                }
            }
            else
            {
                z = u1 * u1 * u2;
                
                if ( z <= 0.25 )
                {
                    v = beta * log ( u1 / ( 1.0 - u1 ) );
                    w = a * exp ( v );
                    
                    if ( aa == a )
                    {
                        value = w / ( b + w );
                    }
                    else
                    {
                        value = b / ( b + w );
                    }
                    return value;
                }
                
                if ( k2 < z )
                {
                    continue;
                }
            }
            
            v = beta * log ( u1 / ( 1.0 - u1 ) );
            w = a * exp ( v );
            
            if ( log ( z ) <= alpha * ( log ( alpha / ( b + w ) ) + v ) - log4 )
            {
                break;
            }
        }
    }
    
    if ( aa == a )
    {
        value = w / ( b + w );
    }
    else
    {
        value = b / ( b + w );
    }
    return value;
}


/******************************************************************************/

float gengam (thread uint *rng_state, float a, float r )

/******************************************************************************/
/*
 Purpose:
 
 GENGAM generates a Gamma random deviate.
 
 Discussion:
 
 This procedure generates random deviates from the gamma distribution whose
 density is (A^R)/Gamma(R) * X^(R-1) * Exp(-A*X)
 
 Licensing:
 
 This code is distributed under the GNU LGPL license.
 
 Modified:
 
 01 April 2013
 
 Author:
 
 Original FORTRAN77 version by Barry Brown, James Lovato.
 C version by John Burkardt.
 
 Reference:
 
 Joachim Ahrens, Ulrich Dieter,
 Generating Gamma Variates by a Modified Rejection Technique,
 Communications of the ACM,
 Volume 25, Number 1, January 1982, pages 47-54.
 
 Joachim Ahrens, Ulrich Dieter,
 Computer Methods for Sampling from Gamma, Beta, Poisson and
 Binomial Distributions,
 Computing,
 Volume 12, Number 3, September 1974, pages 223-246.
 
 Parameters:
 
 Input, float A, the location parameter.
 
 Input, float R, the shape parameter.
 
 Output, float GENGAM, a random deviate from the distribution.
 */
{
    float value;
    
    value = sgamma (rng_state, r ) / a;
    
    return value;
}

/******************************************************************************/

float gennor (thread uint *rng_state, float av, float sd )

/******************************************************************************/
/*
 Purpose:
 
 GENNOR generates a normal random deviate.
 
 Discussion:
 
 This procedure generates a single random deviate from a normal distribution
 with mean AV, and standard deviation SD.
 
 Licensing:
 
 This code is distributed under the GNU LGPL license.
 
 Modified:
 
 01 April 2013
 
 Author:
 
 Original FORTRAN77 version by Barry Brown, James Lovato.
 C version by John Burkardt.
 
 Reference:
 
 Joachim Ahrens, Ulrich Dieter,
 Extensions of Forsythe's Method for Random
 Sampling from the Normal Distribution,
 Mathematics of Computation,
 Volume 27, Number 124, October 1973, page 927-937.
 
 Parameters:
 
 Input, float AV, the mean.
 
 Input, float SD, the standard deviation.
 
 Output, float GENNOR, a random deviate from the distribution.
 */
{
    float value;
    
    value = sd * snorm (rng_state) + av;
    
    return value;
}

/******************************************************************************/

float r4_exp ( float x )

/******************************************************************************/
/*
 Purpose:
 
 R4_EXP computes the exponential function, avoiding overflow and underflow.
 
 Discussion:
 
 For arguments of very large magnitude, the evaluation of the
 exponential function can cause computational problems.  Some languages
 and compilers may return an infinite value or a "Not-a-Number".
 An alternative, when dealing with a wide range of inputs, is simply
 to truncate the calculation for arguments whose magnitude is too large.
 Whether this is the right or convenient approach depends on the problem
 you are dealing with, and whether or not you really need accurate
 results for large magnitude inputs, or you just want your code to
 stop crashing.
 
 Licensing:
 
 This code is distributed under the GNU LGPL license.
 
 Modified:
 
 19 September 2014
 
 Author:
 
 John Burkardt
 
 Parameters:
 
 Input, float X, the argument of the exponential function.
 
 Output, float R4_EXP, the value of exp ( X ).
 */
{
    const float r4_huge = 1.0E+30;
    const float r4_log_max = +69.0776;
    const float r4_log_min = -69.0776;
    float value;
    
    if ( x <= r4_log_min )
    {
        value = 0.0;
    }
    else if ( x < r4_log_max )
    {
        value = exp ( x );
    }
    else
    {
        value = r4_huge;
    }
    
    return value;
}

/******************************************************************************/

float r4_max ( float x, float y )

/******************************************************************************/
/*
 Purpose:
 
 R4_MAX returns the maximum of two R4's.
 
 Licensing:
 
 This code is distributed under the GNU LGPL license.
 
 Modified:
 
 07 May 2006
 
 Author:
 
 John Burkardt
 
 Parameters:
 
 Input, float X, Y, the quantities to compare.
 
 Output, float R4_MAX, the maximum of X and Y.
 */
{
    float value;
    
    if ( y < x )
    {
        value = x;
    }
    else
    {
        value = y;
    }
    return value;
}
/******************************************************************************/

float r4_min ( float x, float y )

/******************************************************************************/
/*
 Purpose:
 
 R4_MIN returns the minimum of two R4's.
 
 Licensing:
 
 This code is distributed under the GNU LGPL license.
 
 Modified:
 
 07 May 2006
 
 Author:
 
 John Burkardt
 
 Parameters:
 
 Input, float X, Y, the quantities to compare.
 
 Output, float R4_MIN, the minimum of X and Y.
 */
{
    float value;
    
    if ( y < x )
    {
        value = y;
    }
    else
    {
        value = x;
    }
    return value;
}

/******************************************************************************/

float sexpo (thread uint *rng_state)

/******************************************************************************/
/*
 Purpose:
 
 SEXPO samples the standard exponential distribution.
 
 Discussion:
 
 This procedure corresponds to algorithm SA in the reference.
 
 Licensing:
 
 This code is distributed under the GNU LGPL license.
 
 Modified:
 
 01 April 2013
 
 Author:
 
 Original FORTRAN77 version by Barry Brown, James Lovato.
 C version by John Burkardt.
 
 Reference:
 
 Joachim Ahrens, Ulrich Dieter,
 Computer Methods for Sampling From the
 Exponential and Normal Distributions,
 Communications of the ACM,
 Volume 15, Number 10, October 1972, pages 873-882.
 
 Parameters:
 
 Output, float SEXPO, a random deviate from the standard
 exponential distribution.
 */
{
    float a;
    int i;
    const float q[8] = {
        0.6931472,
        0.9333737,
        0.9888778,
        0.9984959,
        0.9998293,
        0.9999833,
        0.9999986,
        0.9999999 };
    float u;
    float umin;
    float ustar;
    float value;
    
    a = 0.0;
    u =unidev(rng_state, 0.0, 1.0);
    
    for ( ; ; )
    {
        u = u + u;
        
        if ( 1.0 < u )
        {
            break;
        }
        a = a + q[0];
    }
    
    u = u - 1.0;
    
    if ( u <= q[0] )
    {
        value = a + u;
        return value;
    }
    
    i = 0;
    ustar = unidev(rng_state, 0.0, 1.0);
    umin = ustar;
    
    for ( ; ; )
    {
        ustar = unidev(rng_state, 0.0, 1.0);
        umin = r4_min ( umin, ustar );
        i = i + 1;
        
        if ( u <= q[i] )
        {
            break;
        }
    }
    
    value = a + umin * q[0];
    
    return value;
}

/******************************************************************************/

float sgamma (thread uint *rng_state, float a )

/******************************************************************************/
/*
 Purpose:
 
 SGAMMA samples the standard Gamma distribution.
 
 Discussion:
 
 This procedure corresponds to algorithm GD in the reference.
 
 Licensing:
 
 This code is distributed under the GNU LGPL license.
 
 Modified:
 
 01 April 2013
 
 Author:
 
 Original FORTRAN77 version by Barry Brown, James Lovato.
 C version by John Burkardt.
 
 Reference:
 
 Joachim Ahrens, Ulrich Dieter,
 Generating Gamma Variates by a Modified Rejection Technique,
 Communications of the ACM,
 Volume 25, Number 1, January 1982, pages 47-54.
 
 Parameters:
 
 Input, float A, the parameter of the standard gamma
 distribution.  0.0 < A < 1.0.
 
 Output, float SGAMMA, a random deviate from the distribution.
 */
{
    const float a1 =  0.3333333;
    const float a2 = -0.2500030;
    const float a3 =  0.2000062;
    const float a4 = -0.1662921;
    const float a5 =  0.1423657;
    const float a6 = -0.1367177;
    const float a7 =  0.1233795;
    float b;
    float c;
    float d;
    float e;
    const float e1 = 1.0;
    const float e2 = 0.4999897;
    const float e3 = 0.1668290;
    const float e4 = 0.0407753;
    const float e5 = 0.0102930;
    float p;
    float q;
    float q0;
    const float q1 =  0.04166669;
    const float q2 =  0.02083148;
    const float q3 =  0.00801191;
    const float q4 =  0.00144121;
    const float q5 = -0.00007388;
    const float q6 =  0.00024511;
    const float q7 =  0.00024240;
    float r;
    float s;
    float s2;
    float si;
    const float sqrt32 = 5.656854;
    float t;
    float u;
    float v;
    float value;
    float w;
    float x;
    
    if ( 1.0 <= a )
    {
        s2 = a - 0.5;
        s = sqrt ( s2 );
        d = sqrt32 - 12.0 * s;
        /*
         Immediate acceptance.
         */
        t = snorm (rng_state );
        x = s + 0.5 * t;
        value = x * x;
        
        if ( 0.0 <= t )
        {
            return value;
        }
        /*
         Squeeze acceptance.
         */
        u = unidev(rng_state, 0.0, 1.0);
        if ( d * u <= t * t * t )
        {
            return value;
        }
        
        r = 1.0 / a;
        q0 = (((((( q7
                   * r + q6 )
                  * r + q5 )
                 * r + q4 )
                * r + q3 )
               * r + q2 )
              * r + q1 )
        * r;
        /*
         Approximation depending on size of parameter A.
         */
        if ( 13.022 < a )
        {
            b = 1.77;
            si = 0.75;
            c = 0.1515 / s;
        }
        else if ( 3.686 < a )
        {
            b = 1.654 + 0.0076 * s2;
            si = 1.68 / s + 0.275;
            c = 0.062 / s + 0.024;
        }
        else
        {
            b = 0.463 + s + 0.178 * s2;
            si = 1.235;
            c = 0.195 / s - 0.079 + 0.16 * s;
        }
        /*
         Quotient test.
         */
        if ( 0.0 < x )
        {
            v = 0.5 * t / s;
            
            if ( 0.25 < fabs ( v ) )
            {
                q = q0 - s * t + 0.25 * t * t + 2.0 * s2 * log ( 1.0 + v );
            }
            else
            {
                q = q0 + 0.5 * t * t * (((((( a7
                                             * v + a6 )
                                            * v + a5 )
                                           * v + a4 )
                                          * v + a3 )
                                         * v + a2 )
                                        * v + a1 )
                * v;
            }
            
            if ( log ( 1.0 - u ) <= q )
            {
                return value;
            }
        }
        
        for ( ; ; )
        {
            e = sexpo (rng_state );
            u = 2.0 * unidev(rng_state, 0.0, 1.0); - 1.0;
            
            if ( 0.0 <= u )
            {
                t = b + fabs ( si * e );
            }
            else
            {
                t = b - fabs ( si * e );
            }
            /*
             Possible rejection.
             */
            if ( t < -0.7187449 )
            {
                continue;
            }
            /*
             Calculate V and quotient Q.
             */
            v = 0.5 * t / s;
            
            if ( 0.25 < fabs ( v ) )
            {
                q = q0 - s * t + 0.25 * t * t + 2.0 * s2 * log ( 1.0 + v );
            }
            else
            {
                q = q0 + 0.5 * t * t * (((((( a7
                                             * v + a6 )
                                            * v + a5 )
                                           * v + a4 )
                                          * v + a3 )
                                         * v + a2 )
                                        * v + a1 )
                *  v;
            }
            /*
             Hat acceptance.
             */
            if ( q <= 0.0 )
            {
                continue;
            }
            
            if ( 0.5 < q )
            {
                w = exp ( q ) - 1.0;
            }
            else
            {
                w = (((( e5 * q + e4 ) * q + e3 ) * q + e2 ) * q + e1 ) * q;
            }
            /*
             May have to sample again.
             */
            if ( c * fabs ( u ) <= w * exp ( e - 0.5 * t * t ) )
            {
                break;
            }
        }
        
        x = s + 0.5 * t;
        value = x * x;
        
        return value;
    }
    /*
     Method for A < 1.
     */
    else
    {
        b = 1.0 + 0.3678794 * a;
        
        for ( ; ; )
        {
            p = b * unidev(rng_state, 0.0, 1.0);
            
            if ( p < 1.0 )
            {
                value = exp ( log ( p ) / a );
                
                if ( value <= sexpo (rng_state ) )
                {
                    return value;
                }
                continue;
            }
            value = - log ( ( b - p ) / a );
            
            if ( ( 1.0 - a ) * log ( value ) <= sexpo (rng_state ) )
            {
                break;
            }
        }
    }
    return value;
}

/******************************************************************************/

float snorm (thread uint *rng_state)

/******************************************************************************/
/*
 Purpose:
 
 SNORM samples the standard normal distribution.
 
 Discussion:
 
 This procedure corresponds to algorithm FL, with M = 5, in the reference.
 
 Licensing:
 
 This code is distributed under the GNU LGPL license.
 
 Modified:
 
 01 April 2013
 
 Author:
 
 Original FORTRAN77 version by Barry Brown, James Lovato.
 C version by John Burkardt.
 
 Reference:
 
 Joachim Ahrens, Ulrich Dieter,
 Extensions of Forsythe's Method for Random
 Sampling from the Normal Distribution,
 Mathematics of Computation,
 Volume 27, Number 124, October 1973, page 927-937.
 
 Parameters:
 
 Output, float SNORM, a random deviate from the distribution.
 */
{
    const float a[32] = {
        0.0000000, 0.3917609E-01, 0.7841241E-01, 0.1177699,
        0.1573107, 0.1970991,     0.2372021,     0.2776904,
        0.3186394, 0.3601299,     0.4022501,     0.4450965,
        0.4887764, 0.5334097,     0.5791322,     0.6260990,
        0.6744898, 0.7245144,     0.7764218,     0.8305109,
        0.8871466, 0.9467818,     1.009990,      1.077516,
        1.150349,  1.229859,      1.318011,      1.417797,
        1.534121,  1.675940,      1.862732,      2.153875 };
    float aa;
    const float d[31] = {
        0.0000000, 0.0000000, 0.0000000, 0.0000000,
        0.0000000, 0.2636843, 0.2425085, 0.2255674,
        0.2116342, 0.1999243, 0.1899108, 0.1812252,
        0.1736014, 0.1668419, 0.1607967, 0.1553497,
        0.1504094, 0.1459026, 0.1417700, 0.1379632,
        0.1344418, 0.1311722, 0.1281260, 0.1252791,
        0.1226109, 0.1201036, 0.1177417, 0.1155119,
        0.1134023, 0.1114027, 0.1095039 };
    const float h[31] = {
        0.3920617E-01, 0.3932705E-01, 0.3950999E-01, 0.3975703E-01,
        0.4007093E-01, 0.4045533E-01, 0.4091481E-01, 0.4145507E-01,
        0.4208311E-01, 0.4280748E-01, 0.4363863E-01, 0.4458932E-01,
        0.4567523E-01, 0.4691571E-01, 0.4833487E-01, 0.4996298E-01,
        0.5183859E-01, 0.5401138E-01, 0.5654656E-01, 0.5953130E-01,
        0.6308489E-01, 0.6737503E-01, 0.7264544E-01, 0.7926471E-01,
        0.8781922E-01, 0.9930398E-01, 0.1155599,     0.1404344,
        0.1836142,     0.2790016,     0.7010474 };
    int i;
    float s;
    const float t[31] = {
        0.7673828E-03, 0.2306870E-02, 0.3860618E-02, 0.5438454E-02,
        0.7050699E-02, 0.8708396E-02, 0.1042357E-01, 0.1220953E-01,
        0.1408125E-01, 0.1605579E-01, 0.1815290E-01, 0.2039573E-01,
        0.2281177E-01, 0.2543407E-01, 0.2830296E-01, 0.3146822E-01,
        0.3499233E-01, 0.3895483E-01, 0.4345878E-01, 0.4864035E-01,
        0.5468334E-01, 0.6184222E-01, 0.7047983E-01, 0.8113195E-01,
        0.9462444E-01, 0.1123001,     0.1364980,     0.1716886,
        0.2276241,     0.3304980,     0.5847031 };
    float tt;
    float u;
    float ustar;
    float value;
    float w;
    float y;
    
    u = unidev(rng_state, 0.0, 1.0);
    if ( u <= 0.5 )
    {
        s = 0.0;
    }
    else
    {
        s = 1.0;
    }
    u = 2.0 * u - s;
    u = 32.0 * u;
    i = ( int ) ( u );
    if ( i == 32 )
    {
        i = 31;
    }
    /*
     Center
     */
    if ( i != 0 )
    {
        ustar = u - ( float ) ( i );
        aa = a[i-1];
        
        for ( ; ; )
        {
            if ( t[i-1] < ustar )
            {
                w = ( ustar - t[i-1] ) * h[i-1];
                
                y = aa + w;
                
                if ( s != 1.0 )
                {
                    value = y;
                }
                else
                {
                    value = -y;
                }
                return value;
            }
            u = unidev(rng_state, 0.0, 1.0);
            w = u * ( a[i] - aa );
            tt = ( 0.5 * w + aa ) * w;
            
            for ( ; ; )
            {
                if ( tt < ustar )
                {
                    y = aa + w;
                    if ( s != 1.0 )
                    {
                        value = y;
                    }
                    else
                    {
                        value = -y;
                    }
                    return value;
                }
                
                u = unidev(rng_state, 0.0, 1.0);
                
                if ( ustar < u )
                {
                    break;
                }
                tt = u;
                ustar = unidev(rng_state, 0.0, 1.0);
            }
            ustar = unidev(rng_state, 0.0, 1.0);
        }
    }
    /*
     Tail
     */
    else
    {
        i = 6;
        aa = a[31];
        
        for ( ; ; )
        {
            u = u + u;
            
            if ( 1.0 <= u )
            {
                break;
            }
            aa = aa + d[i-1];
            i = i + 1;
        }
        
        u = u - 1.0;
        w = u * d[i-1];
        tt = ( 0.5 * w + aa ) * w;
        
        for ( ; ; )
        {
            ustar = unidev(rng_state, 0.0, 1.0);
            
            if ( tt < ustar )
            {
                y = aa + w;
                if ( s != 1.0 )
                {
                    value = y;
                }
                else
                {
                    value = -y;
                }
                return value;
            }
            
            u = unidev(rng_state, 0.0, 1.0);
            
            if ( u <= ustar )
            {
                tt = u;
            }
            else
            {
                u = unidev(rng_state, 0.0, 1.0);
                w = u * d[i-1];
                tt = ( 0.5 * w + aa ) * w;
            }
        }
    }
}
