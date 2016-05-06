//
//  GPUImagePixelFormatConverter.m
//  PanelRenderTests
//
//  Created by Tom Montgomery on 24/04/2016.
//  Copyright © 2016 AkzoNobel. All rights reserved.
//

#import "GPUImagePixelFormatConverter.h"
//#import <OpenGLES/ES2/gl.h>

// -15 stored using a single precision bias of 127
static const unsigned int HALF_FLOAT_MIN_BIASED_EXP_AS_SINGLE_FP_EXP = 0x38000000; // max exponent value in single precision that will be converted

// to Inf or Nan when stored as a half-float
static const unsigned int HALF_FLOAT_MAX_BIASED_EXP_AS_SINGLE_FP_EXP = 0x47800000;

// 255 is the max exponent biased value
static const unsigned int FLOAT_MAX_BIASED_EXP = (0xFF << 23);
static const unsigned int HALF_FLOAT_MAX_BIASED_EXP = (0x1F << 10);

@implementation GPUImagePixelFormatConverter

#pragma mark - Converting format of floats to half floats

+ (hfloat)halfFloatFromFloat:(float)floatToConvert
{
    float f = floatToConvert;
    float *fp = &f;
    unsigned int x = *(unsigned int *)fp;
    unsigned int sign = (unsigned short)(x >> 31);
    unsigned int mantissa;
    unsigned int exp;
    hfloat hf;

    // get mantissa
    mantissa = x & ((1 << 23) - 1);

    // get exponent bits
    exp = x & FLOAT_MAX_BIASED_EXP;
    if (exp >= HALF_FLOAT_MAX_BIASED_EXP_AS_SINGLE_FP_EXP) {
        // check if the original single precision float number is a NaN
        mantissa = mantissa && (exp == FLOAT_MAX_BIASED_EXP) ? (1 << 23) - 1 : 0;
        hf = (((hfloat)sign) << 15) | (hfloat)(HALF_FLOAT_MAX_BIASED_EXP) | (hfloat)(mantissa >> 13);
    } else if (exp <= HALF_FLOAT_MIN_BIASED_EXP_AS_SINGLE_FP_EXP) {
        exp = (HALF_FLOAT_MIN_BIASED_EXP_AS_SINGLE_FP_EXP - exp) >> 23;
        mantissa >>= (14 + exp);
        hf = (((hfloat)sign) << 15) | (hfloat)(mantissa);
    } else {
        hf = (((hfloat)sign) << 15) | (hfloat)((exp - HALF_FLOAT_MIN_BIASED_EXP_AS_SINGLE_FP_EXP) >> 13) | (hfloat)(mantissa >> 13);
    }
    return hf;
}

+ (float)floatFromHalfFloat:(hfloat)hf
{
    unsigned int sign = (unsigned int)(hf >> 15);
    unsigned int mantissa = (unsigned int)(hf & ((1 << 10) - 1));
    unsigned int exp = (unsigned int)(hf & HALF_FLOAT_MAX_BIASED_EXP);
    unsigned int f;

    if (exp == HALF_FLOAT_MAX_BIASED_EXP) {
        // we have a half-float NaN or Inf
        // half-float NaNs will be converted to a single precision NaN // half-float Infs will be converted to a single precision Inf exp = FLOAT_MAX_BIASED_EXP;
        if (mantissa) {
            mantissa = (1 << 23) - 1;
        }
    } else if (exp == 0x0) {
        // set all bits to indicate a NaN
        // convert half-float zero/denorm to single precision value
        if (mantissa) {
            mantissa <<= 1;
            exp = HALF_FLOAT_MIN_BIASED_EXP_AS_SINGLE_FP_EXP; // check for leading 1 in denorm mantissa
            while ((mantissa & (1 << 10)) == 0) {
                // for every leading 0, decrement single precision exponent by 1 // and shift half-float mantissa value to the left
                mantissa <<= 1;
                exp -= (1 << 23);
            }
            // clamp the mantissa to 10-bits
            mantissa &= ((1 << 10) - 1);
            // shift left to generate single-precision mantissa of 23-bits mantissa <<= 13;
            // shift left to
            mantissa <<= 13;
        }
    } else {
        // generate single precision biased exponent value
        mantissa <<= 13;
        exp = (exp << 13) + HALF_FLOAT_MIN_BIASED_EXP_AS_SINGLE_FP_EXP;
    }
    f = (sign << 31) | exp | mantissa;
    return *((float *)&f);
}

+ (hfloat)halfFloatFromByte:(UInt8)byte
{
    return [self halfFloatFromFloat:(float)(byte / 255.0)];
}

+ (UInt8)byteFromHalfFloat:(hfloat)hfloat
{
    return (UInt8)(roundf([self floatFromHalfFloat:hfloat] * 255.0));
}

#pragma mark - Converting format of pixels arrays

+ (FloatPixel *)floatPixelsFromBytePixels:(BytePixel *)bytePixels numberOfPixels:(NSUInteger)numberOfPixels
{
    FloatPixel *floatPixels = (FloatPixel *)malloc(numberOfPixels * sizeof(FloatPixel));
    for (NSUInteger idx = 0; idx < numberOfPixels; ++idx) {
        BytePixel bytePixel = bytePixels[idx];
        floatPixels[idx] = (FloatPixel){(float)(bytePixel.r / 255.0),
                                        (float)(bytePixel.g / 255.0),
                                        (float)(bytePixel.b / 255.0),
                                        (float)(bytePixel.a / 255.0)};
    }
    return floatPixels;
}

+ (FloatPixel *)floatPixelsFromHalfFloatPixels:(HalfFloatPixel *)halfFloatPixels numberOfPixels:(NSUInteger)numberOfPixels
{
    FloatPixel *floatPixels = (FloatPixel *)malloc(numberOfPixels * sizeof(FloatPixel));
    for (NSUInteger idx = 0; idx < numberOfPixels; ++idx) {
        HalfFloatPixel halfFloatPixel = halfFloatPixels[idx];
        floatPixels[idx] = (FloatPixel) {[self floatFromHalfFloat:halfFloatPixel.r],
                                         [self floatFromHalfFloat:halfFloatPixel.g],
                                         [self floatFromHalfFloat:halfFloatPixel.b],
                                         [self floatFromHalfFloat:halfFloatPixel.a]};
    }
    return floatPixels;
}

+ (HalfFloatPixel *)halfFloatFromBytePixels:(BytePixel *)bytePixels numberOfPixels:(NSUInteger)numberOfPixels
{
    HalfFloatPixel *halfFloatPixels = (HalfFloatPixel *)malloc(numberOfPixels * sizeof(HalfFloatPixel));
    for (NSUInteger idx = 0; idx < numberOfPixels; ++idx) {
        BytePixel bytePixel = bytePixels[idx];
        halfFloatPixels[idx] = (HalfFloatPixel) {[self halfFloatFromByte:bytePixel.r],
                                                 [self halfFloatFromByte:bytePixel.g],
                                                 [self halfFloatFromByte:bytePixel.b],
                                                 [self halfFloatFromByte:bytePixel.a]};
    }
    return halfFloatPixels;
}

+ (BytePixel *)bytePixelsFromHalfFloatPixels:(HalfFloatPixel *)halfFloatPixels numberOfPixels:(NSUInteger)numberOfPixels
{
    BytePixel *bytePixels = (BytePixel *)malloc(numberOfPixels * sizeof(BytePixel));
    for (NSUInteger idx = 0; idx < numberOfPixels; ++idx) {
        HalfFloatPixel halfFloatPixel = halfFloatPixels[idx];
        bytePixels[idx] = (BytePixel) {[self byteFromHalfFloat:halfFloatPixel.r],
                                       [self byteFromHalfFloat:halfFloatPixel.g],
                                       [self byteFromHalfFloat:halfFloatPixel.b],
                                       [self byteFromHalfFloat:halfFloatPixel.a]};
    }
    return bytePixels;
}

@end
