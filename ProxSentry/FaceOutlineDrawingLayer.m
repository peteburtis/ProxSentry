//
//  FaceOutlineDrawingLayer.m
//  ProxSentry
//
/*
 https://github.com/peteburtis/ProxSentry
 
 Copyright (C) 2012 Peter Burtis
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "FaceOutlineDrawingLayer.h"

@implementation FaceOutlineDrawingLayer

-(id)init
{
    self = [super init];
    if (self) {
        /*
         Setup a transform that mirrors the contents of this layer, matching the video layer this layer will be placed over.
         */
        self.transform = CATransform3DMakeScale(-1, 1, 1);
    }
    return self;
}

-(void)setFaces:(NSArray *)faces
{
    if (faces != _faces) {
        _faces = faces;
        [self setNeedsDisplay];
    }
}

-(void)updateScaleFactor
{
    CGRect bounds = self.bounds;
    if (bounds.size.width == 0 || bounds.size.height == 0) return;
    
    CGFloat scalex = bounds.size.width / _sourceFrameSize.width;
    CGFloat scaley = bounds.size.height / _sourceFrameSize.height;
    
    scaleFactor = (scalex > scaley ? scalex : scaley);
}

-(void)setSourceFrameSize:(CGSize)sourceFrameSize
{
    _sourceFrameSize = sourceFrameSize;
    [self updateScaleFactor];
}

-(void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self updateScaleFactor];
}

-(CGRect)scaleRectToMatchSourceScale:(CGRect)rect
{
    rect.size.width = rect.size.width * scaleFactor;
    rect.size.height = rect.size.height * scaleFactor;
    rect.origin.x = rect.origin.x * scaleFactor;
    rect.origin.y = rect.origin.y * scaleFactor;
    
    return rect;
}

-(void)drawInContext:(CGContextRef)ctx
{
    // Figure out the multiplier to translate a point from image space to layer space
    CGContextSetStrokeColorWithColor(ctx, [[NSColor blueColor] CGColor]);
    CGContextSetLineWidth(ctx, 4);
    
    for (CIFeature *feature in _faces) {
        CGContextStrokeRect(ctx, [self scaleRectToMatchSourceScale:feature.bounds]);
    }
}

@end
