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
@objcMembers
public final class CardIconButton: UIControl {
    
    /// user specified icon images for each icon type
    public dynamic var iconTypes: [IconType: UIImage]? {
        didSet {
            //whenever new icon types are set, we need to reload existing images in case it's chnaged
            if let currentType = currentIconType, let newImage = iconTypes?[currentType] {
                currentButton?.setBackgroundImage(newImage, for: .normal)
            }
        }
    }
    
    public weak var delegate: CardIconButtonDelegate?
    
    public enum Animation {
        case flipLeft, flipRight, crossFade
        case none
    }
    
    public enum IconType: String {
        case scan               = "icon_card_scan"
        case unknown            = "icon_card_default"
        case CVC                = "icon_card_cvc"
        case CVCAmex            = "icon_card_cvc_amex"
        case AmericanExpress    = "icon_card_amex"
        case Discover           = "icon_card_discover"
        case Visa               = "icon_card_visa"
        case MasterCard         = "icon_card_mastercard"
        case DinersClub         = "icon_card_diners"
        case JCB                = "icon_card_jcb"
    }
    
    fileprivate var currentButton: UIButton?
    fileprivate(set) var currentIconType: IconType?
    
    fileprivate var currentInputView: UIView?
    fileprivate var currentInputAccessoryView: UIView?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        currentButton?.frame = bounds
    }
    
    // MARK: Public Methods
    
    public func setIconType(_ type: IconType, animation: Animation = .none) {
        
        func createButton() -> UIButton {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
            button.addTarget(self, action: #selector(buttonTouched), for: .touchUpInside)
            return button
        }
        
        //do nothing when trying to set existing card type
        if type == currentIconType {
            return
        }
        
        //try to load user defined icon first, if not specified use default image
        let image = iconTypes?[type] ?? UIImage(named: type.rawValue, in: Bundle(for: CardIconButton.self), compatibleWith: nil)
        if image == nil {
            debugPrint("warning: missing image asset for key \(type.rawValue)")
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
            case .flipLeft:     options = [.transitionFlipFromLeft]
            case .flipRight:    options = [.transitionFlipFromRight]
            case .crossFade:    options = [.transitionCrossDissolve]
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
    
    // MARK: - Private Methods
    
    //we support only touch up inside, if there is a need, we can properly implement all targets and actions
    @objc private func buttonTouched() {
        sendActions(for: .touchUpInside)
    }
    
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
