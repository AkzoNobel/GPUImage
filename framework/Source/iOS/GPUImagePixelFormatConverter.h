//
//  GPUImagePixelFormatConverter.h
//  PanelRenderTests
//
//  Created by Tom Montgomery on 24/04/2016.
//  Copyright © 2016 AkzoNobel. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    float r;
    float g;
    float b;
    float a;
} FloatPixel;

typedef unsigned short hfloat;
typedef struct {
    hfloat r;
    hfloat g;
    hfloat b;
    hfloat a;
} HalfFloatPixel;

typedef struct {
    UInt8 r;
    UInt8 g;
    UInt8 b;
    UInt8 a;
} BytePixel;

@interface GPUImagePixelFormatConverter : NSObject

// Conversion between raw pixel arrays
+ (FloatPixel *)floatPixelsFromBytePixels:(BytePixel *)bytePixels numberOfPixels:(NSUInteger)numberOfPixels;
+ (FloatPixel *)floatPixelsFromHalfFloatPixels:(HalfFloatPixel *)halfFloatPixels numberOfPixels:(NSUInteger)numberOfPixels;
+ (HalfFloatPixel *)halfFloatFromBytePixels:(BytePixel *)bytePixels numberOfPixels:(NSUInteger)numberOfPixels;
+ (BytePixel *)bytePixelsFromHalfFloatPixels:(HalfFloatPixel *)halfFloatPixels numberOfPixels:(NSUInteger)numberOfPixels;

@end
