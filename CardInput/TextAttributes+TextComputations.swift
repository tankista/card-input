//
//  TextAttributes+TextComputations.swift
//  CardInput
//
//  Created by Peter Stajger on 17/04/2018.
//  Copyright © 2018 UITouch. All rights reserved.
//

import UIKit

extension Collection where Iterator.Element == (key: NSAttributedStringKey, value: Any) {
    
    func lineHeight(withOptions options: NSStringDrawingOptions? = nil) -> CGFloat {
        return ceil(NSString(string: " ").boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: options ?? [],
            attributes: self as? [NSAttributedStringKey: Any],
            context: nil
            ).size.height)
    }
    
}
