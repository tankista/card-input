//
//  Animations.swift
//  CardInput
//
//  Created by Peter Stajger on 17/04/2018.
//  Copyright © 2018 UITouch. All rights reserved.
//

import UIKit

let UIViewAnimationOptionsNone = UIViewAnimationOptions.init(rawValue: 0)

struct Animations {
    static let defaultAnimationDuration: CFTimeInterval = 0.25
}

extension Animations {
    
    public static func wiggle(aroundPoint point: CGPoint, beginTime: CFTimeInterval = CACurrentMediaTime()) -> CAAnimation {
        
        let animation = CAKeyframeAnimation(keyPath: "position.x")
        animation.beginTime = beginTime + 0.01
        animation.duration = defaultAnimationDuration + 0.2;
        animation.repeatCount = 1
        animation.isRemovedOnCompletion = true
        animation.values = [point.x, point.x-8, point.x+6, point.x-4, point.x+3, point.x-2, point.x]
        
        return animation
    }
    
}
