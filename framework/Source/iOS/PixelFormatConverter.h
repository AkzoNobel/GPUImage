//
//  PixelFormatConverter.h
//  PanelRenderTests
//
//  Created by Tom Montgomery on 24/04/2016.
//  Copyright © 2016 Tom Montgomery. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@interface PixelFormatConverter : NSObject

// Conversion between raw pixel arrays

+ (void)convertHalfFloatPixels:(HalfFloatPixel *)halfFloatPixels toBytePixels:(BytePixel *)bytePixels numberOfPixels:(NSUInteger)numberOfPixels;

+ (void)convertBytePixels:(BytePixel *)bytePixels toHalfFloatPixels:(HalfFloatPixel *)halfFloatPixels numberOfPixels:(NSUInteger)numberOfPixels;

@end
