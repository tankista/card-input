//
//  CreditCardIconView.swift
//  ViewKit
//
//  Created by Peter Stajger on 21/09/15.
//  Copyright © 2015 Goodtime Labs, Inc. All rights reserved.
//

import Foundation
import UIKit

public protocol CardIconButtonDelegate : class {
    func cardIconButtonDidBeginEditing(_ view: CardIconButton)
}

///
/// A button, that shows a credit card type icon, such as apple pay, visa,
/// mastercard, etc. This view is used as subview of `CardInputView` to indicate
/// a card type that user is inputting. It shows also type `scan` that can
/// open an OCR scanner. Transition between icon types can be animated.
///
public final class CardIconButton: UIControl {
    
    fileprivate var currentButton: UIButton?
    
    public var iconTypes: [IconType: String]?   //button key and image asset name
    public weak var delegate: CardIconButtonDelegate?
    
    fileprivate(set) var currentIconType: IconType?
    
    public enum Animation {
        case flipLeft, flipRight, crossFade
        case none
    }
    
    public enum IconType: String {
        case Scan, Unknown, CVC, CVCAmex
        case ApplePay, AmericanExpress, Discover, Visa, MasterCard, DinersClub, JCB
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public func setIconType(_ type: IconType, animation: Animation = .none) {
        
        func createButton() -> UIButton {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
            button.addTarget(self, action: #selector(buttonTouched), for: .touchUpInside)
            return button
        }
        
        guard let assetKey = iconTypes?[type] else {
            fatalError("could not match button asset for given key (\(type.rawValue)). Please set iconTypes dictionary.")
        }
        
        //do nothing when trying to set existing card type
        if type == currentIconType {
            return
        }
        
        let image = UIImage(named: assetKey, in: Bundle(for: CardIconButton.self), compatibleWith: nil)
        if image == nil {
            debugPrint("warning: missing image asset for key \(assetKey)")
        }
        
        if currentButton == nil {
            currentButton = createButton()
            currentButton!.setBackgroundImage(image, for: .normal)
            addSubview(currentButton!)
        }
        else {
            
            let duration = Animations.defaultAnimationDuration
            let options: UIViewAnimationOptions?
            
            switch (animation) {
            case .flipLeft:     options = [UIViewAnimationOptions.transitionFlipFromLeft]
            case .flipRight:    options = [UIViewAnimationOptions.transitionFlipFromRight]
            case .crossFade:    options = [UIViewAnimationOptions.transitionCrossDissolve]
            default:            options = nil
            }
            
            if let options = options {
                
                let nextButton = createButton()
                nextButton.setBackgroundImage(image, for: .normal)
                
                let completion: (Bool) -> Void = { [unowned self] (_) in
                    self.currentButton?.removeFromSuperview()
                    self.currentButton = nextButton
                }
                
                UIView.transition(from: currentButton!, to: nextButton, duration: duration, options: options, completion: completion)
            }
            
            else {
                currentButton!.setBackgroundImage(image, for: .normal)
            }
        }
        
        currentIconType = type
    }
    
    //we support only touch up inside, if there is a need, we can properly implement all targets and actions
    @objc func buttonTouched() {
        sendActions(for: .touchUpInside)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        currentButton?.frame = bounds
    }
    
    fileprivate var currentInputView: UIView?
    fileprivate var currentInputAccessoryView: UIView?
}

extension CardIconButton {

    override public var canBecomeFirstResponder : Bool {
        return true
    }
    
    override public func becomeFirstResponder() -> Bool {
        
        let result = super.becomeFirstResponder()
        if result == false {
            return result
        }
        
        delegate?.cardIconButtonDidBeginEditing(self)
        
        return result
    }
    
    override public func resignFirstResponder() -> Bool {
        return super.resignFirstResponder()
    }
    
    override public var inputView: UIView? {
        get { return currentInputView }
        set { currentInputView = newValue }
    }

    override public var inputAccessoryView: UIView? {
        get { return currentInputAccessoryView }
        set { currentInputAccessoryView = newValue }
    }
}
