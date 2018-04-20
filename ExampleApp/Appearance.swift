//
//  StyleAppearance.swift
//  ExampleApp
//
//  Created by Peter Stajger on 19/04/2018.
//  Copyright © 2018 UITouch. All rights reserved.
//

import UIKit
import CardInput

final class Appearance {
    
    class func style() {
        styleCardInputView()
        styleCardNumberView()
    }
    
    private class func styleCardInputView() {
        let appearance = CardInputView.appearance()
        appearance.backgroundColor = UIColor.white
    }
    
    private class func styleCardNumberView() {
        let appearance = CardNumberView.appearance()
        appearance.groupPadding = 10
        appearance.maxAdvancement = 10
        appearance.textAttributes = [.font: Fonts.Circular.book(ofSize: 18), .foregroundColor: Colors.darkText]
        appearance.placeholderCharacterAttributes = [.font: Fonts.Circular.book(ofSize: 17), .foregroundColor: Colors.lightText]
        appearance.errorTextAttributes = [.font: Fonts.Circular.book(ofSize: 18), .foregroundColor: Colors.dangerText]
    }
    
}

struct Fonts {
    
    struct Circular {
        
        enum Weight: String {
            case book = "Circular-Book"
            case medium = "Circular-Medium"
        }
        
        static func book(ofSize: CGFloat) -> UIFont {
            return UIFont(name: Weight.book.rawValue, size: ofSize)!
        }
        
        static func medium(ofSize: CGFloat) -> UIFont {
            return UIFont(name: Weight.medium.rawValue, size: ofSize)!
        }
    }
}

struct Colors {
    
    /// (57, 60, 61)
    static let darkText = UIColor(red: 57/255, green: 60/255, blue: 61/255, alpha: 1)
    
    /// (156, 158, 160)
    static let lightText = UIColor(red: 156/255, green: 158/255, blue: 160/255, alpha: 1)
    
    /// (245, 69, 69)
    static let dangerText = UIColor(red: 245/255, green: 69/255, blue: 69/255, alpha: 1)
    
    /// (164, 175, 186)
    static let greyDimmed = UIColor(red: 164/255, green: 175/255, blue: 168/255, alpha: 1)
}
