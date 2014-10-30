//
//  CGPath+Arrow.swift
//  Plexus
//
//  Created by matt on 10/3/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa


extension CGPath {
    
    class func getAxisAlignedArrowPoints(inout points: Array<CGPoint>, forLength: CGFloat, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat ) {
        
        let tailLength = forLength - headLength
        println(tailLength)
        points.append(CGPointMake(0, tailWidth/2))
        points.append(CGPointMake(tailLength, tailWidth/2))
        points.append(CGPointMake(tailLength, headWidth/2))
        points.append(CGPointMake(forLength, 0))
        points.append(CGPointMake(tailLength, -headWidth/2))
        points.append(CGPointMake(tailLength, -tailWidth/2))
        points.append(CGPointMake(0, -tailWidth/2))
        
    }
    
    
    class func getShiftedAxisAlignedArrowPoints(inout points: Array<CGPoint>, forLength: CGFloat, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat, distanceAlong: CGFloat ) {
        
        let tailLength = forLength*distanceAlong

        points.append(CGPointMake(0, tailWidth/2))
        points.append(CGPointMake(tailLength, tailWidth/2))
        points.append(CGPointMake(tailLength, headWidth/2))
        points.append(CGPointMake((tailLength+headLength), tailWidth/2))
        points.append(CGPointMake(forLength, tailWidth/2))
        points.append(CGPointMake(forLength, -tailWidth/2))
        points.append(CGPointMake((tailLength+headLength), -tailWidth/2))
        points.append(CGPointMake(tailLength, -headWidth/2))
        points.append(CGPointMake(tailLength, -tailWidth/2))
        points.append(CGPointMake(0, -tailWidth/2))
    }
    
    class func getAxisAlignedDoubleArrowPoints(inout points: Array<CGPoint>, forLength: CGFloat, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat, distance1: CGFloat, distance2: CGFloat ) {
        
        let tailLength = forLength*distance1
        let middleLength = forLength*distance2
        
        points.append(CGPointMake(0, tailWidth/2))
        points.append(CGPointMake(tailLength, tailWidth/2))
        points.append(CGPointMake(tailLength, headWidth/2))
        points.append(CGPointMake((tailLength+headLength), tailWidth/2))
        points.append(CGPointMake(middleLength, tailWidth/2))
        points.append(CGPointMake(middleLength, headWidth/2))
        points.append(CGPointMake((middleLength+headLength), tailWidth/2))
        points.append(CGPointMake(forLength, tailWidth/2))
        points.append(CGPointMake(forLength, -tailWidth/2))
        points.append(CGPointMake((middleLength+headLength), -tailWidth/2))
        points.append(CGPointMake(middleLength, -headWidth/2))
        points.append(CGPointMake(middleLength, -tailWidth/2))
        points.append(CGPointMake((tailLength+headLength), -tailWidth/2))
        points.append(CGPointMake(tailLength, -headWidth/2))
        points.append(CGPointMake(tailLength, -tailWidth/2))
        points.append(CGPointMake(0, -tailWidth/2))
    }
    
    
    class func transformForStartPoint(startPoint: CGPoint, endPoint: CGPoint, length: CGFloat) -> CGAffineTransform{
        let cosine: CGFloat = (endPoint.x - startPoint.x)/length
        let sine: CGFloat = (endPoint.y - startPoint.y)/length
        
        return CGAffineTransformMake(cosine, sine, -sine, cosine, startPoint.x, startPoint.y)
    }
    
    
    class func bezierPathWithArrowFromPoint(startPoint:CGPoint, endPoint: CGPoint, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat) -> CGPath {
        
        let xdiff: Float = Float(endPoint.x) - Float(startPoint.x)
        let ydiff: Float = Float(endPoint.y) - Float(startPoint.y)
        let length = hypotf(xdiff, ydiff)
        
        var points = [CGPoint]()
       // self.getAxisAlignedArrowPoints(&points, forLength: CGFloat(length), tailWidth: tailWidth, headWidth: headWidth, headLength: headLength)
        self.getAxisAlignedDoubleArrowPoints(&points, forLength: CGFloat(length), tailWidth: tailWidth, headWidth: headWidth, headLength: headLength, distance1: 0.33, distance2: 0.66)
        
        var transform: CGAffineTransform = self.transformForStartPoint(startPoint, endPoint: endPoint, length:  CGFloat(length))
        
        var cgPath: CGMutablePathRef = CGPathCreateMutable()
        //CGPathAddLines(cgPath, &transform, points, 7)
        CGPathAddLines(cgPath, &transform, points, 16)
        CGPathCloseSubpath(cgPath)
        
        // var uiPath: NSBezierPath = NSBezierPath(CGPath: cgPath)
        
        return cgPath
    }
}
