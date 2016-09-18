//
//  CGPath+Arrow.swift
//  Plexus
//
//  Created by matt on 10/3/14.
//  Copyright (c) 2014 Santa Clara University. All rights reserved.
//

import Cocoa


extension CGPath {
    
    class func getAxisAlignedArrowPoints(_ points: inout Array<CGPoint>, forLength: CGFloat, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat ) {
        
        let tailLength = forLength - headLength
        print(tailLength)
        points.append(CGPoint(x: 0, y: tailWidth/2))
        points.append(CGPoint(x: tailLength, y: tailWidth/2))
        points.append(CGPoint(x: tailLength, y: headWidth/2))
        points.append(CGPoint(x: forLength, y: 0))
        points.append(CGPoint(x: tailLength, y: -headWidth/2))
        points.append(CGPoint(x: tailLength, y: -tailWidth/2))
        points.append(CGPoint(x: 0, y: -tailWidth/2))
        
    }
    
    
    class func getShiftedAxisAlignedArrowPoints(_ points: inout Array<CGPoint>, forLength: CGFloat, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat, distanceAlong: CGFloat ) {
        
        let tailLength = forLength*distanceAlong

        points.append(CGPoint(x: 0, y: tailWidth/2))
        points.append(CGPoint(x: tailLength, y: tailWidth/2))
        points.append(CGPoint(x: tailLength, y: headWidth/2))
        points.append(CGPoint(x: (tailLength+headLength), y: tailWidth/2))
        points.append(CGPoint(x: forLength, y: tailWidth/2))
        points.append(CGPoint(x: forLength, y: -tailWidth/2))
        points.append(CGPoint(x: (tailLength+headLength), y: -tailWidth/2))
        points.append(CGPoint(x: tailLength, y: -headWidth/2))
        points.append(CGPoint(x: tailLength, y: -tailWidth/2))
        points.append(CGPoint(x: 0, y: -tailWidth/2))
    }
    
    class func getAxisAlignedDoubleArrowPoints(_ points: inout Array<CGPoint>, forLength: CGFloat, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat, distance1: CGFloat, distance2: CGFloat ) {
        
        let tailLength = forLength*distance1
        let middleLength = forLength*distance2
        
        points.append(CGPoint(x: 0, y: tailWidth/2))
        points.append(CGPoint(x: tailLength, y: tailWidth/2))
        points.append(CGPoint(x: tailLength, y: headWidth/2))
        points.append(CGPoint(x: (tailLength+headLength), y: tailWidth/2))
        points.append(CGPoint(x: middleLength, y: tailWidth/2))
        points.append(CGPoint(x: middleLength, y: headWidth/2))
        points.append(CGPoint(x: (middleLength+headLength), y: tailWidth/2))
        points.append(CGPoint(x: forLength, y: tailWidth/2))
        points.append(CGPoint(x: forLength, y: -tailWidth/2))
        points.append(CGPoint(x: (middleLength+headLength), y: -tailWidth/2))
        points.append(CGPoint(x: middleLength, y: -headWidth/2))
        points.append(CGPoint(x: middleLength, y: -tailWidth/2))
        points.append(CGPoint(x: (tailLength+headLength), y: -tailWidth/2))
        points.append(CGPoint(x: tailLength, y: -headWidth/2))
        points.append(CGPoint(x: tailLength, y: -tailWidth/2))
        points.append(CGPoint(x: 0, y: -tailWidth/2))
    }
    
    
    class func transformForStartPoint(_ startPoint: CGPoint, endPoint: CGPoint, length: CGFloat) -> CGAffineTransform{
        let cosine: CGFloat = (endPoint.x - startPoint.x)/length
        let sine: CGFloat = (endPoint.y - startPoint.y)/length
        
        return CGAffineTransform(a: cosine, b: sine, c: -sine, d: cosine, tx: startPoint.x, ty: startPoint.y)
    }
    
    
    class func bezierPathWithArrowFromPoint(_ startPoint:CGPoint, endPoint: CGPoint, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat, d1: CGFloat, d2: CGFloat) -> CGPath {
        
        let xdiff: Float = Float(endPoint.x) - Float(startPoint.x)
        let ydiff: Float = Float(endPoint.y) - Float(startPoint.y)
        let length = hypotf(xdiff, ydiff)
        
        var points = [CGPoint]()
       // self.getAxisAlignedArrowPoints(&points, forLength: CGFloat(length), tailWidth: tailWidth, headWidth: headWidth, headLength: headLength)
        self.getAxisAlignedDoubleArrowPoints(&points, forLength: CGFloat(length), tailWidth: tailWidth, headWidth: headWidth, headLength: headLength, distance1: d1, distance2: d2)
        
        let transform: CGAffineTransform = self.transformForStartPoint(startPoint, endPoint: endPoint, length:  CGFloat(length))
        
        let cgPath: CGMutablePath = CGMutablePath()
        //CGPathAddLines(cgPath, &transform, points, 7)
        cgPath.addLines(between: points, transform: transform)
        //CGPathAddLines(cgPath, &transform, points, 16)
        cgPath.closeSubpath()
        
        // var uiPath: NSBezierPath = NSBezierPath(CGPath: cgPath)
        
        return cgPath
    }
}
