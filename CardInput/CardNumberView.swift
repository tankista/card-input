//
//  CardNumberView.swift
//  CardInput
//
//  Created by Peter Stajger on 17/04/2018.
//  Copyright © 2018 UITouch. All rights reserved.
//

import Foundation
import UIKit

public protocol CardNumberViewDelegate: NSObjectProtocol {
    func cardNumberView(_ view: CardNumberView, didChangeText: String, inRange: NSRange)
    func cardNumberView(_ view: CardNumberView, shouldChangeText: String, inRange: NSRange) -> Bool
    func cardNumberViewShouldBeginEditing(_ view: CardNumberView) -> Bool
    func cardNumberViewDidBeginEditing(_ view: CardNumberView)
}

/**
    View that displays credit card number as it's content. 

    It groups 16 digits in 4 groups of 4 digits. If view is in editing mode you 
    can add and remove digits at will. Each digit that is removed is replaced by 
    a placeholder character.
 */
@objcMembers
public final class CardNumberView : UIView {
    
    public weak var delegate: CardNumberViewDelegate?
    
    ///A string representing view's content. Use this property to access actual credit card number or to fill view with new.
    public var text: String {
        get {
            return textStorage?.string.trimmingCharacters(in: CharacterSet(charactersIn: String(describing: placeholderCharacter))) ?? ""
        }
        set {
            setText(newValue, needsRedraw: true, informDelegate: true)
        }
    }
    
    ///Text that is shown when no text is set. Width of this text affects sizeThatFits().
    public var placeholderText: String? {
        didSet {
            contentSize = nil
            invalidateIntrinsicContentSize()
        }
    }
    
    ///Placeholder character. Default character is "•". Setting this property will result in resetting current string.
    public var placeholderCharacter: Character? = "•" {
        didSet {
            //second redraw content (will erase existing text storage)
            setText(defaultPlaceholder(), needsRedraw: true, informDelegate: false)
            
            //update cursor
            updateCursor()
        }
    }
    
    ///Padding between groups of digits. Default is 10.
    public var groupPadding: CGFloat = 10 {
        didSet {
            contentSize = nil
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    
    ///Format of drawed glyphs. Examples [4, 4, 4, 4] or [4, 6, 5] or [4, 4, 4, 2], [4], etc.
    public var numberFormat: [Int] = [4, 4, 4, 4] {
        didSet {
            contentSize = nil
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    
    ///Total number of text containers that will be drawn.
    public var numberOfCharacters: Int {
        return numberFormat.reduce(0, +)
    }
    
    ///Max width of a glyph
    public var maxAdvancement: CGFloat = 10 {  //this can be computed based on given font
        didSet {
            contentSize = nil
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    
    var debugIdentifier: String!
    
    ///Text attributes of input characters.
    dynamic public var textAttributes: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: 17)] {
        didSet {
            contentSize = nil
            invalidateIntrinsicContentSize()
            setText(text, needsRedraw: true, informDelegate: false)
        }
    }
    
    ///Text attributes of placeholder character.
    dynamic public var placeholderCharacterAttributes: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: 17)] {
        didSet {
            contentSize = nil
            invalidateIntrinsicContentSize()
            setText(text, needsRedraw: true, informDelegate: false)
        }
    }
    
    ///Text attributes of input characters when error state is set
    dynamic public var errorTextAttributes: [NSAttributedStringKey: Any] = [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: UIColor.red]
    
    ///If true, sets errorTextAttributes otherwise normal text attributes. Animation will jiggle.
    var errorState = false {
        didSet {
            contentSize = nil
            invalidateIntrinsicContentSize()
            setText(text, needsRedraw: true, informDelegate: false)
        }
    }

    // MARK: Private Properties
    
    //methods for managing text
    fileprivate var textStorage: NSTextStorage?
    fileprivate var layoutManager: NSLayoutManager = NSLayoutManager()
    fileprivate var textContainerOrigins = [NSTextContainer: CGPoint]()
    fileprivate var contentSize: CGSize?
    fileprivate var cursorLayer: CursorLayer?
    fileprivate var currentInputAccessoryView: UIView?
    
    fileprivate var currentTextAttributes: [NSAttributedStringKey: Any] {
        return errorState ? errorTextAttributes : textAttributes
    }
    
    // MARK: View Life Cycle Methods
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setText(defaultPlaceholder(), needsRedraw: false, informDelegate: false)
        updateCursor()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setText(defaultPlaceholder(), needsRedraw: false, informDelegate: false)
        updateCursor()
    }
    
    override public func layoutSubviews() {
        setNeedsDisplay()
    }
    
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return calculateContentSize()
    }
    
    public override var intrinsicContentSize: CGSize {
        return calculateContentSize()
    }
    
    override public func draw(_ rect: CGRect) {
        
        //make sure we have a background color (red default)
        (backgroundColor ?? UIColor.red).setFill()
        UIGraphicsGetCurrentContext()?.fill(rect)
        
        //draw placeholder text only if this condition is met
        //1. there is no text and self is not first responder
        //2. there is no text and self is first responder but has no placeholder char
        if let placeholder = placeholderText , self.text.isEmpty && (self.isFirstResponder == false || placeholderCharacter == nil) {
            //this is not placed very well, make sure that it's baselined with view's real text
            (placeholder as NSString).draw(at: CGPoint.zero, withAttributes: placeholderCharacterAttributes)
        }
        else {
            var lastRenderedGlyph: Int = 0
            
            while lastRenderedGlyph < layoutManager.numberOfGlyphs {
                
                guard let containerRect = rectForTextContainerForGlyphAtIndex(lastRenderedGlyph) else {
                    fatalError("Trying to render container for index out of bounds.")
                }
                
                let container = NSTextContainer(size: containerRect.size)
                container.lineFragmentPadding = 0
                layoutManager.addTextContainer(container)
                
                let range = layoutManager.glyphRange(for: container)
                layoutManager.drawGlyphs(forGlyphRange: range, at: containerRect.origin)
                
                lastRenderedGlyph = NSMaxRange(range)
            }
            
            layoutManager.invalidateLayout(forCharacterRange: NSMakeRange(0, layoutManager.numberOfGlyphs), actualCharacterRange: nil)
            layoutManager.removeAllTextContainers()
        }
    }
    
    // MARK: Public Methods
    
    func pushNumber(_ char: String) {
        updateTextWithCharacter(char, pushedCharacter: true)
    }
    
    func popLastNumber() {
        updateTextWithCharacter(nil, pushedCharacter: false, popedCharacter: true)
    }
    
    func reset() {
        setText("", needsRedraw: true, informDelegate: true)
    }
    
    // MARK: Private Methods
    
    //Sets text as complete value, appends placeholder chars if not full lenght
    fileprivate func setText(_ text: String, needsRedraw: Bool, informDelegate: Bool, pushedCharacter: Bool = false, popedCharacter: Bool = false) {
        
        //save previous text count
        let oldCount = self.text.count
        let newCount = text.count
        
        contentMode = newCount > oldCount ? .left : .right
        
        let range = NSMakeRange((popedCharacter && newCount == 0 && oldCount == 0) ? -1 : 0, newCount)
        
        if informDelegate && delegate?.cardNumberView(self, shouldChangeText: text, inRange: range) == false {
            return
        }
        
        //add missing placeholder characters if needed to inserting string
        let numberOfPlaceholderCharacters = placeholderCharacter == nil ? 0 : numberOfCharacters - newCount
        let value = text + defaultPlaceholder(numberOfPlaceholderCharacters)
        
        //create new text storage
        textStorage = NSTextStorage()
        textStorage!.delegate = self
        textStorage!.addLayoutManager(layoutManager)
        textStorage!.append(NSAttributedString(string: value, attributes: nil))
        
        //draw stuff and position cusor
        if needsRedraw == true {
            
            //redraw stuff
            setNeedsDisplay()
            
            //move cursor to new position
            if let position = rectForTextContainerForGlyphAtIndex(newCount, allowCursor: true)?.origin {
                cursorLayer?.setPosition(position, animated: false)
            }
            
            //set cursor visible/hidden if cursor is out of bounds for last character
            if isFirstResponder {
                cursorLayer?.setHidden(newCount == numberOfCharacters, animated: false)
            }
        }
        
        //inform delegate (we return cleaned text with no placeholder characters)
        if informDelegate {
            delegate?.cardNumberView(self, didChangeText: self.text, inRange: range)
        }
    }

    //Creates new card number string by appending or removing new char from string's end
    fileprivate func updateTextWithCharacter(_ char: String?, pushedCharacter: Bool = false, popedCharacter: Bool = false) {
        
        var currentText = self.text
        
        if char != nil {
            currentText += char!
        }
        else {
            currentText = String(currentText.dropLast())
        }
        
        setText(currentText, needsRedraw: true, informDelegate: true, pushedCharacter: pushedCharacter, popedCharacter: popedCharacter)
    }
    
    fileprivate func updateCursor() {
        cursorLayer?.removeFromSuperlayer()
        cursorLayer = CursorLayer(placeholder: placeholderCharacter, size: sizeForTextContainer())
        layer.addSublayer(cursorLayer!)
    }
    
    fileprivate func defaultPlaceholder(_ count: Int? = nil) -> String {
        if placeholderCharacter == nil {
            return ""
        }
        return String(Array(repeating: placeholderCharacter!, count: max(0, count ?? numberOfCharacters)))
    }
    
    //cache this, or optionally see font traits to find out line height
    fileprivate func sizeForTextContainer() -> CGSize {
        let lineHeight = currentTextAttributes.lineHeight()
        return CGSize(width: maxAdvancement, height: lineHeight)
    }
    
    //cursor can be drawn out of bounds of text (but only for 1 extra index if it's very last group)
    fileprivate func indexOfGroupForGlyphAtIndex(_ index: Int, allowCursor: Bool = false) -> Int? {
        
        var lastGroupMaxIndex = -1
        for groupIndex in 0 ..< numberFormat.count {
            let elementsInGroup = numberFormat[groupIndex]
            var maxElementIndex = lastGroupMaxIndex + elementsInGroup
            
            //for cursor in the last group allow 1 exta glyph
            if groupIndex == numberFormat.count - 1 && allowCursor == true {
                maxElementIndex += 1
            }
            
            if index <= maxElementIndex {
                return groupIndex
            }
            lastGroupMaxIndex = maxElementIndex
        }
        return nil
    }
    
    fileprivate func rectForTextContainerForGlyphAtIndex(_ index: Int, allowCursor: Bool = false) -> CGRect? {
        
        guard let indexOfGroup = indexOfGroupForGlyphAtIndex(index, allowCursor: allowCursor) else {
            return nil
        }
        
        let size = sizeForTextContainer()
        let x: CGFloat = CGFloat(index) * size.width + CGFloat(indexOfGroup) * groupPadding
        return CGRect(x: x, y: 0, width: size.width, height: size.height)
    }

    fileprivate func rectForEffectiveText() -> CGRect {
        if self.text.count == 0 {
            return CGRect.zero
        }
        
        guard let lastCharacterRect = rectForTextContainerForGlyphAtIndex(text.count-1, allowCursor: false) else {
            return CGRect.zero
        }
        
        return lastCharacterRect
    }
    
    fileprivate func calculateContentSize() -> CGSize {
        if contentSize == nil {
            
            //check width of text
            let containerSize = sizeForTextContainer()
            let maxTextWidth = (rectForTextContainerForGlyphAtIndex(numberOfCharacters - 1) ?? CGRect.zero).maxX
            let height = containerSize.height
            
            //check width of placeholder text
            let placeholderWidth = placeholderText == nil ? 0 : placeholderText!.textSize(for: placeholderCharacterAttributes).width
            
            contentSize = CGSize(width: max(maxTextWidth, placeholderWidth), height: height)
        }
        return contentSize!
    }
}

extension CardNumberView {

    override public var canBecomeFirstResponder : Bool {
        return delegate?.cardNumberViewShouldBeginEditing(self) ?? true
    }
    
    override public func becomeFirstResponder() -> Bool {
    
        let result = super.becomeFirstResponder()
        if result == false { return result }
        
        //need to redraw to show or hide placeholder
        if placeholderText != nil {
            setNeedsDisplay()
        }
        
        //show cursor
        cursorLayer?.setHidden(false, animated: false)
        
        //inform delegate
        if result == true {
            delegate?.cardNumberViewDidBeginEditing(self)
        }
        
        return result
    }
    
    override public func resignFirstResponder() -> Bool {
        
        let result = super.resignFirstResponder()
        if result == false { return result }
        
        //need to redraw to show or hide placeholder
        if placeholderText != nil {
            setNeedsDisplay()
        }
        
        //hide cursor
        cursorLayer?.setHidden(true, animated: false)
        
        return result
    }
    
    //This is causing this issue: https://trello.com/c/C2wlGq2c
    override public var inputAccessoryView: UIView? {
        set { currentInputAccessoryView = newValue }
        get { return currentInputAccessoryView }
    }
    
    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        if [#selector(NSObject.copy), #selector(paste(_:))].contains(action) == false {
            return false
        }
        
        switch action {
        case #selector(NSObject.copy) where text.isEmpty:
            return false
        case #selector(paste(_:)) where (UIPasteboard.general.string ?? "").isEmpty:
            return false
        default:
            return true
        }
    }
    
    override public func copy(_ sender: Any?) {
        UIPasteboard.general.string = text
    }
    
    override public func paste(_ sender: Any?) {
        text = UIPasteboard.general.string ?? ""
    }
}

extension CardNumberView: NSTextStorageDelegate {
    
    var commonTextAttributes: [NSAttributedStringKey: Any] {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        return [.paragraphStyle: style, .kern: 0 as AnyObject]
    }
    
    public func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        
        let editedText = (textStorage.string as NSString).substring(with: editedRange)

        //add common text attributes
        textStorage.addAttributes(commonTextAttributes, range: editedRange)
        
        //add specific attributes to content
        for (index, character) in editedText.enumerated() {
            let updateRange = NSMakeRange(editedRange.location + index, 1)
            if character == placeholderCharacter {
                textStorage.addAttributes(placeholderCharacterAttributes, range: updateRange)
            }
            else {
                textStorage.addAttributes(currentTextAttributes, range: updateRange)
            }
        }
    }
}

extension NSLayoutManager {
    func removeAllTextContainers() {
        for idx in (0..<textContainers.count).reversed() {
            removeTextContainer(at: idx)
        }
    }
}

class CursorLayer: CAShapeLayer {

    let placeholder: Character?
    
    init(placeholder char: Character?, size: CGSize) {
        placeholder = char
        super.init()
        
        transaction(animated: false) {
            self.isHidden = true
            self.path = self.pathForCursorType(size).cgPath
            self.fillColor = UIColor.blue.cgColor //TODO: make this stylable 
            self.backgroundColor = UIColor.white.cgColor
        }
    }

    fileprivate func pathForCursorType(_ size: CGSize) -> UIBezierPath {

        if let _ = placeholder {
            //this is hardcoded, we need glyph
            let dotSize: CGFloat = 7
            let center = CGPoint(x: (size.width-dotSize)/2, y: (size.height-dotSize)/2+1) //This +1 is hardcoded to match exact position, will not work for different fonts
            return UIBezierPath(ovalIn: CGRect(x: center.x, y: center.y, width: dotSize, height: dotSize))
            
            //create path for character, this does not work correctly, dont know how to place glyph to proper place, perhaps it needs layout manager
//            let cffont = Styles.Font.medium(ofSize: Styles.Font.Size.XLarge) as CTFontRef
//            let character = (String(char) as NSString).characterAtIndex(0) as UniChar
//            var glyphs = Array<CGGlyph>(count: 1, repeatedValue: 0)
//            CTFontGetGlyphsForCharacters(cffont, [character], &glyphs, 1)
//            var transform = CGAffineTransformMake(1, 0, 0, -1, 0, size.height/2) //CGAffineTransformMakeRotation(CGFloat(M_PI))
//            let pathReft = CTFontCreatePathForGlyph(cffont, glyphs.first!, &transform)
//            return UIBezierPath(CGPath: pathReft!)
        }
        else {
            return UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2, height: size.height), byRoundingCorners: UIRectCorner.allCorners, cornerRadii: size)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setPosition(_ position: CGPoint, animated: Bool) {
        startBlinking()
        transaction(animated: animated) {
            self.position = position
        }
    }
    
    func setHidden(_ hidden: Bool, animated: Bool) {
        transaction(animated: animated) {
            self.isHidden = hidden
        }
        hidden ? stopBlinking() : startBlinking()
    }
    
    fileprivate func startBlinking() {
        
        if isHidden { return }
        
        stopBlinking()
        
        //cachce this animations??
        let blinkAnimation = CAKeyframeAnimation(keyPath: "opacity")
        blinkAnimation.values = [1.0, 0.0]
        blinkAnimation.keyTimes = [0.2, 0.5]
        blinkAnimation.timingFunctions = [CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn), CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)]
        blinkAnimation.repeatCount = Float.infinity
        blinkAnimation.duration = 1
        
        add(blinkAnimation, forKey: "blink")
    }
    
    fileprivate func stopBlinking() {
        removeAnimation(forKey: "blink")
    }
    
    fileprivate func transaction(animated: Bool, block: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        block()
        CATransaction.commit()
    }
    
}
