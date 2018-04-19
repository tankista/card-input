//
//  CardInputView.swift
//  CardInput
//
//  Created by Peter Stajger on 17/04/2018.
//  Copyright © 2018 UITouch. All rights reserved.
//

import UIKit

public enum PaymentMethodType: String {
    case ApplePay, Discover, Visa, MasterCard, JCB
    case AmericanExpress = "American Express"
    case DinersClub = "Diners Club"
    case Unknown
}

public protocol CardInputViewDelegate : class {
    
    ///Called each time editing state is about to be changed, giving a chance to delegate to validate given input.
    ///Return false if input is not valid, this will also set field into error state. Return true if input is valid in order to move to next step.
    func cardInputView(_ view: CardInputView, validateInput: String?, forEditingState state: CardInputView.EditingState) -> Bool
    
    ///Based on given partial card number, determine card type and return corresponding icon type and number format.
    func cardInputView(_ view: CardInputView, determineCardTraitsFor partialCardNumber: String) -> (PaymentMethodType, [Int], Int)
    
    ///Called when cvc card is filled and all other fields are filled. It is up to delegate to validate inputs again. Check property "currentCard" for actual card values
    func cardInputViewDidFinishWithCard(_ view: CardInputView)
}

/**
    This view encapsulates and manages all credit card related views:
    - credit card icon button
    - credit card number view
    - credit card date view
    - credit card cvc view
    Animations and states, interaction, etc..
*/
public class CardInputView : UIControl {
    
    ///Each card can be destribed by it's icon type, number format and cvc length
    public typealias CardData   = (String, String, String)
    
    public let cardIconButton: CardIconButton
    public let cardNumberView: CardNumberView
    public let cardExpirationView: CardNumberView
    public let cardCVCView: CardNumberView
    
    public weak var delegate: CardInputViewDelegate!   //delegate must be set at some point
    public var contentInset: UIEdgeInsets = UIEdgeInsetsMake(12.5, 10, 12.5, 0)
    
    ///Returns a tuple of current state. Card number, expiration (12/18), CVC
    public var currentCard: CardData {
        return (cardNumberView.text, cardExpirationView.text, cardCVCView.text)
    }
    
    public enum EditingState {
        case scan
        case number, expiration, cvc
        case none, done
    }
    
    public var editingState: EditingState {
        get { return _editingState ?? .none }
        set { setEditingState(newValue, animated: false) }
    }
    
    override public var backgroundColor: UIColor? {
        didSet {
            cardIconButton.backgroundColor = backgroundColor
            cardNumberView.backgroundColor = backgroundColor
            cardExpirationView.backgroundColor = backgroundColor
            cardCVCView.backgroundColor = backgroundColor
            cardIconMaskingView.backgroundColor = backgroundColor
            
            if let color = backgroundColor {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                cardIconMaskingViewGradient.colors = [color.cgColor, UIColor(white: 1, alpha: 0).cgColor]
                cardIconMaskingViewGradient.startPoint = CGPoint(x: 0, y: 0)
                cardIconMaskingViewGradient.endPoint = CGPoint(x: 1, y: 0)
                CATransaction.commit()
            }
        }
    }

    fileprivate var _editingState: EditingState? //this is a backing value for editingState
    fileprivate var cardIconMaskingView: UIView
    fileprivate let cardIconMaskingViewGradient: CAGradientLayer
    
    override public init(frame: CGRect) {
        
        cardNumberView = CardNumberView(frame: CGRect.zero)
        cardIconButton = CardIconButton(frame: CGRect.zero)
        cardExpirationView = CardNumberView(frame: CGRect.zero)
        cardCVCView = CardNumberView(frame: CGRect.zero)
        cardIconMaskingView = UIView(frame: CGRect.zero)
        cardIconMaskingViewGradient = CAGradientLayer()
        
        super.init(frame: frame)
        
        commonSetup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        cardNumberView = CardNumberView(frame: CGRect.zero)
        cardIconButton = CardIconButton(frame: CGRect.zero)
        cardExpirationView = CardNumberView(frame: CGRect.zero)
        cardCVCView = CardNumberView(frame: CGRect.zero)
        cardIconMaskingView = UIView(frame: CGRect.zero)
        cardIconMaskingViewGradient = CAGradientLayer()
        
        super.init(coder: aDecoder)
        
        commonSetup()
    }
    
    private func commonSetup() {
        
        addSubview(cardNumberView)
        addSubview(cardExpirationView)
        addSubview(cardCVCView)
        addSubview(cardIconMaskingView)
        addSubview(cardIconButton)
        cardIconMaskingView.layer.addSublayer(cardIconMaskingViewGradient)
        
        clipsToBounds = true
        
        cardNumberView.placeholderText = "Type card number" //TODO: make this as parameter
        cardNumberView.delegate = self
        
        cardIconButton.addTarget(self, action: #selector(creditCardIconTapped(_:)), for: .touchUpInside)
        cardIconButton.iconTypes = [
            .AmericanExpress: "icon_card_amex",
            .ApplePay: "icon_card_applepay",
            .CVC: "icon_card_cvc",
            .CVCAmex: "icon_card_amex_cvc",
            .Discover: "icon_card_discover",
            .MasterCard: "icon_card_mastercard",
            .Scan: "icon_card_scan",
            .Visa: "icon_card_visa",
            .Unknown: "icon_card_default",
            .DinersClub: "icon_card_diners",
            .JCB: "icon_card_jcb"
        ]
        cardIconButton.setIconType(.Scan)
        cardIconButton.delegate = self
        
        cardExpirationView.placeholderText = "MM/YY"
        cardExpirationView.placeholderCharacter = nil
        cardExpirationView.numberFormat = [5]
        cardExpirationView.delegate = self
        
        cardCVCView.placeholderText = "CVC"
        cardCVCView.placeholderCharacter = nil
        cardCVCView.numberFormat = [3]
        cardCVCView.delegate = self
        
        cardNumberView.debugIdentifier = "number"
        cardExpirationView.debugIdentifier = "expiration"
        cardCVCView.debugIdentifier = "cvc"
        
        //set initial state
        setEditingState(.none, animated: false)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CardInputView.tapDetected(_:)))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        let margin: CGFloat = 20
        
        cardIconButton.frame = CGRect(x: contentInset.left, y: 0, width: 40, height: 25)
        cardIconButton.center.y = bounds.height/2
        
        cardIconMaskingView.frame = CGRect(x: 0, y: 0, width: cardIconButton.frame.maxX, height: bounds.height)
        cardIconMaskingViewGradient.frame = CGRect(x: cardIconMaskingView.frame.maxX, y: 0, width: margin/2, height: cardIconMaskingView.frame.height)
        
        cardNumberView.sizeToFit()
        cardNumberView.center.y = bounds.height/2
        
        cardExpirationView.sizeToFit()
        cardExpirationView.center.y = bounds.height/2
        
        cardCVCView.sizeToFit()
        cardCVCView.center.y = bounds.height/2
        
        switch editingState {
        case .none:
            fallthrough
        case .number, .scan:
            cardNumberView.frame.origin.x = cardIconButton.frame.maxX + margin/2
        case .expiration, .done, .cvc:
            let groupWidth = cardNumberView.maxAdvancement * CGFloat(cardNumberView.numberFormat.last!)
            cardNumberView.frame.origin.x = cardIconButton.frame.maxX + margin/2 - cardNumberView.frame.width + groupWidth
        }
        
        cardExpirationView.frame.origin.x = cardNumberView.frame.maxX + margin
        cardCVCView.frame.origin.x = cardExpirationView.frame.maxX + margin
    }
    
    // MARK: Public Methods
    
    public func reset() {
        cardNumberView.reset()
        cardExpirationView.reset()
        cardCVCView.reset()
        cardIconButton.setIconType(iconTypeForCurrentCardNumber(), animation: .none)
        if textViewsAreFirstResponder() {
            _ = cardNumberView.becomeFirstResponder()
        }
    }
    
    // MARK: Private Methods
    
    fileprivate func setEditingState(_ newState: EditingState, animated: Bool) {
        
        if _editingState == newState {
            return
        }
        
        //udpate icon
        switch (self.editingState, newState) {
            
        case (.done, .cvc):
            fallthrough
        case (.expiration, .cvc):
            let cardIsAmex: Bool = iconTypeForCurrentCardNumber() == .AmericanExpress
            let animation: CardIconButton.Animation = cardIsAmex ? .crossFade : .flipLeft
            let icon: CardIconButton.IconType = cardIsAmex ? .CVCAmex : .CVC
            cardIconButton.setIconType(icon, animation: animated ? animation : .none)
        case (.cvc, .number):
            fallthrough
        case (.cvc, .expiration):
            fallthrough
        case (.cvc, .done):
            let animation: CardIconButton.Animation = iconTypeForCurrentCardNumber() == CardIconButton.IconType.AmericanExpress ? .crossFade : .flipRight
            cardIconButton.setIconType(iconTypeForCurrentCardNumber(), animation: animated ? animation : .none)
        case (.done, .number):
            fallthrough
        case (.done, .expiration):
            fallthrough
        case (.number, .expiration):
            fallthrough
        case (.expiration, .number):
            fallthrough
        case (.scan, .number):
            fallthrough
        case (.none, .number):
            cardIconButton.setIconType(iconTypeForCurrentCardNumber(), animation: animated ? .crossFade : .none)
        default:
            cardIconButton.setIconType(.Scan, animation: animated ? .crossFade : .none)
        }
        
        _editingState = newState

        let animationBlock = { [unowned self] in
        
            switch self.editingState {
            case .none:
                fallthrough
            case .number, .scan:
                self.cardExpirationView.alpha = 0
                self.cardExpirationView.isUserInteractionEnabled = false
                self.cardCVCView.alpha = 0
                self.cardCVCView.isUserInteractionEnabled = false
            case .expiration, .cvc, .done:
                self.cardExpirationView.alpha = 1
                self.cardExpirationView.isUserInteractionEnabled = true
                self.cardCVCView.alpha = 1
                self.cardCVCView.isUserInteractionEnabled = true
            }
            
            self.layoutIfNeeded()
        }
        
        setNeedsLayout()
        if animated {
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                options: UIViewAnimationOptions(),
                animations: animationBlock,
                completion: nil
            )
        }
        else {
            animationBlock()
        }
        
        switch (self.editingState) {
        case .done:
            sendActions(for: .editingChanged)
            sendActions(for: .editingDidEnd)
        default:
            sendActions(for: .editingChanged)
        }
    }
    
    ///Returns icon type that is suitable for current card number
    fileprivate func iconTypeForCurrentCardNumber() -> CardIconButton.IconType {
        return iconTypeForCardNumber(cardNumberView.text)
    }
    
    ///Returns icon type that is suitable for given card number
    fileprivate func iconTypeForCardNumber(_ number: String) -> CardIconButton.IconType {
        switch number.count {
        case 0, 1: return .Scan //we hardcode scan icon for anything less then 2
        default: return convertCardVendorToButtonIconType(cardTraitsForPartialCardNumber(number).0)
        }
    }

    
    //this is temporary convert func
    fileprivate func convertCardVendorToButtonIconType(_ cardType: PaymentMethodType) -> CardIconButton.IconType {
        switch cardType {
        case .AmericanExpress: return .AmericanExpress
        case .DinersClub: return .DinersClub
        case .Discover: return .Discover
        case .JCB: return .JCB
        case .MasterCard: return .MasterCard
        case .Visa: return .Visa
        default: return .Unknown
        }
    }
    
    //asks delegate for icon type
    fileprivate func cardTraitsForPartialCardNumber(_ number: String) -> (PaymentMethodType, [Int], Int) {
        return delegate.cardInputView(self, determineCardTraitsFor: number)
    }
    
    @objc fileprivate func tapDetected(_ recognizer: UITapGestureRecognizer) {
        
        let location = recognizer.location(in: self)
        let numberRect = cardNumberView.frame.insetBy(dx: -10, dy: -10)
        let expirationRect = cardExpirationView.frame.insetBy(dx: -10, dy: -10)
        let cvcRect = cardCVCView.frame.insetBy(dx: -10, dy: -10)
        
        var possibleFirstResponder: CardNumberView?
        if numberRect.contains(location) {
            possibleFirstResponder = cardNumberView
        }
        else if expirationRect.contains(location) {
            possibleFirstResponder = cardExpirationView
        }
        else if cvcRect.contains(location) {
            possibleFirstResponder = cardCVCView
        }
        
        if let firstResponder = possibleFirstResponder , firstResponder.isFirstResponder {
            let menuController = UIMenuController.shared
            menuController.setTargetRect(firstResponder.bounds, in: firstResponder)
            menuController.setMenuVisible(!menuController.isMenuVisible, animated:true)
        }
        else if let firstResponder = possibleFirstResponder , firstResponder.isUserInteractionEnabled == true {
            _ = possibleFirstResponder?.becomeFirstResponder()
        }
    }
    
    @objc func creditCardIconTapped(_ sender: CardIconButton) {

    }
}

extension CardInputView {
    
    fileprivate func findFirstResponser() -> UIResponder? {
        if cardNumberView.isFirstResponder { return cardNumberView }
        if cardExpirationView.isFirstResponder { return cardExpirationView }
        if cardCVCView.isFirstResponder { return cardCVCView }
        if cardIconButton.isFirstResponder { return cardIconButton }
        return nil
    }
    
    //this can use findFirsReponder() func
    override public var isFirstResponder : Bool {
        return cardNumberView.isFirstResponder || cardExpirationView.isFirstResponder || cardCVCView.isFirstResponder || cardIconButton.isFirstResponder
    }
    
    public func textViewsAreFirstResponder() -> Bool {
        return cardNumberView.isFirstResponder || cardExpirationView.isFirstResponder || cardCVCView.isFirstResponder
    }
    
    override public var canBecomeFirstResponder : Bool {
        return cardNumberView.canBecomeFirstResponder
    }
    
    override public func becomeFirstResponder() -> Bool {
        return cardNumberView.becomeFirstResponder()
    }
    
    override public func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if let firstResponnder = findFirstResponser() {
            sendActions(for: .editingDidEndOnExit)
            return firstResponnder.resignFirstResponder()
        }
        else {
            return result
        }
    }
}

extension CardInputView : CardNumberViewDelegate {

    public func cardNumberViewShouldBeginEditing(_ view: CardNumberView) -> Bool {
        switch (view) {
        
        case cardCVCView:
            let expirationValid = delegate.cardInputView(self, validateInput: cardExpirationView.text, forEditingState: editingState)
            return expirationValid
        
        default:
            return true
        }
    }
    
    public func cardNumberViewDidBeginEditing(_ view: CardNumberView) {
        switch (view) {
        case cardNumberView:        setEditingState(.number, animated: true)
        case cardExpirationView:    setEditingState(.expiration, animated: true)
        case cardCVCView:           setEditingState(.cvc, animated: true)
        default: break
        }
    }
    
    public func cardNumberView(_ view: CardNumberView, shouldChangeText newText: String, inRange: NSRange) -> Bool {
        
        //hide menu item if visible
        let menuController = UIMenuController.shared
        menuController.setMenuVisible(false, animated:true)
        
        let validCharacterSet = NSMutableCharacterSet.decimalDigit()
        let oldCount: Int = view.text.count
        let newCount: Int = newText.count
        
        //this will make sure that "/" char is properly added and replaced for expiration text field when typing by 1 character
        if view == cardExpirationView {
            validCharacterSet.addCharacters(in: "/")
            
            if newCount == 2 && newCount > oldCount {
                view.text =  newText + "/"
                return false
            }
            else if newCount == 2 && newCount < oldCount {
                view.text =  String(newText.dropLast(1))
                return false
            }
        }
        
        //validate characters
        if newText.rangeOfCharacter(from: validCharacterSet.inverted) != nil {
            return false
        }
        
        //only card number change actually can change formats of number and CVC
        if view == cardNumberView {
            var cardTraits: (PaymentMethodType, [Int], Int)
            cardTraits = cardTraitsForPartialCardNumber(newText)
            
            cardIconButton.setIconType(iconTypeForCardNumber(newText), animation: .crossFade)
            cardNumberView.numberFormat = cardTraits.1
            cardCVCView.numberFormat = [cardTraits.2]
            
            setNeedsLayout()
        }
        
        //check if card number or CVC is out of bounds, if so trim to allowed text length
        if (view == cardNumberView || view == cardCVCView) && newCount > view.numberOfCharacters {
            //view.text = newText.substring(to: newText.index(newText.startIndex, offsetBy: view.numberOfCharacters))
            view.text = String(newText.prefix(upTo: newText.index(newText.startIndex, offsetBy: view.numberOfCharacters)))
            return false
        }
        
        //check if expiration field is out of bounds, trim and add / character if not present
        if (view == cardExpirationView && ((newCount > 2 && newText.contains(Character("/")) == false) || newCount > 5)) {
            //remove "/" regardless it's position
            var expirationText: String = newText.replacingOccurrences(of: "/", with: "")
            
            //insert "/" precizely on 2. index
            expirationText.insert(Character("/"), at: expirationText.index(expirationText.startIndex, offsetBy: 2))
            
            //trim remaining string to exactly 5 characters (counting with "/")
            if expirationText.count > 5 {
                expirationText = String(newText.prefix(upTo: expirationText.index(expirationText.startIndex, offsetBy: 5)))
            }
            
            view.text = expirationText
            return false
        }
        
        return true
    }
    
    public func cardNumberView(_ view: CardNumberView, didChangeText text: String, inRange range: NSRange) {
        
        sendActions(for: .valueChanged)
        
        switch (view, text.count) {
        case (cardNumberView, cardNumberView.numberOfCharacters):
            
            //delegate validates input or default is valid
            let inputValid = delegate?.cardInputView(self, validateInput: text, forEditingState: editingState) ??  true
            
            if inputValid {
                _ = cardExpirationView.becomeFirstResponder()
            }
            else {
                cardNumberView.errorState = true
            }
            
        case (cardExpirationView, cardExpirationView.numberOfCharacters):
            
            //expiration field is supposed to be validated by input view itself
            let inputValid = delegate.cardInputView(self, validateInput: text, forEditingState: editingState) 
            if inputValid {
                _ = cardCVCView.becomeFirstResponder()
            }
            else {
                cardExpirationView.errorState = true
            }
            
        case (cardCVCView, cardCVCView.numberOfCharacters):
            
            //check if all fields are filled and inform delegate that input is finished
            let numberField = cardNumberView.text.count == cardNumberView.numberOfCharacters
            let expirationField = cardExpirationView.text.count == cardExpirationView.numberOfCharacters
            if numberField && expirationField {
                delegate?.cardInputViewDidFinishWithCard(self)
                setEditingState(.done, animated: true)
            }
        case (cardCVCView, cardCVCView.numberOfCharacters-1):   //if user deltes last CVC character, need to set CVC state back again
            setEditingState(.cvc, animated: true)
        case (cardCVCView, 0) where range.location == -1:
            _ = cardExpirationView.becomeFirstResponder()
            if cardExpirationView.text.count > 4 {
                cardExpirationView.deleteBackward()
            }
            
        case (cardExpirationView, 0) where range.location == -1:
            cardNumberView.deleteBackward()
            _ = cardNumberView.becomeFirstResponder()
            
        default:
            //reset error state if needed
            if cardNumberView.errorState == true {
                cardNumberView.errorState = false
            }
            if cardExpirationView.errorState == true {
                cardExpirationView.errorState = false
            }
        }
    }
}

extension CardInputView : CardIconButtonDelegate {
    
    public func cardIconButtonDidBeginEditing(_ view: CardIconButton) {
        setEditingState(.scan, animated: true)
    }
    
}

extension CardNumberView : UIKeyInput {
    
    @objc public var keyboardType: UIKeyboardType {
        get { return .numberPad }
        set { }
    }
    
    public var hasText : Bool {
        return !text.isEmpty
    }
    
    public func insertText(_ text: String) {
        pushNumber(text)
    }
    
    public func deleteBackward() {
        popLastNumber()
    }
    
}

