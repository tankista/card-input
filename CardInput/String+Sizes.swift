//
//  String+Sizes.swift
//  CardInput
//
//  Created by Peter Stajger on 17/04/2018.
//  Copyright © 2018 UITouch. All rights reserved.
//

import UIKit

extension String {
    
    ///
    /// Computes height of rendered string based on provided attributes and constraining width. You can also specify options (.usesLineFragmentOrigin by default)
    ///
    func textHeight(for attributes: [NSAttributedStringKey: Any], constraintToWidth width: CGFloat = .greatestFiniteMagnitude, options: NSStringDrawingOptions = .usesLineFragmentOrigin) -> CGFloat {
        return self.textSize(
            for: attributes,
            constraintToSize: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: options
            ).height
    }
    
    ///
    /// Computes size of rendered string based on provided text attributes and constraining size. You can also specify options.
    ///
    /// - parameter attributes: text attributes dictionary with font (NSFontAttributeName)
    /// - parameter size: constraining size, by default infinite width and height
    /// - parameter options: string drawing options (.usesLineFragmentOrigin by default)
    ///
    func textSize(for attributes: [NSAttributedStringKey: Any], constraintToSize size: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions = .usesLineFragmentOrigin) -> CGSize {
        return NSString(string: self).boundingRect(
            with: size,
            options: options,
            attributes: attributes,
            context: nil
            ).integral.size
    }
    
}
