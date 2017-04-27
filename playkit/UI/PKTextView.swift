//
//  PKTextView.swift
//  playkit
//
//  Created by Tbxark on 27/04/2017.
//  Copyright © 2017 Tbxark. All rights reserved.
//

import UIKit

@IBDesignable
public class PKTextView: UITextView {

    @IBInspectable  public let placeholderLabel: PKLabel = PKLabel()
    
    @IBInspectable  public var placeholder: String = "" {
        didSet {
            placeholderLabel.text = placeholder
        }
    }
    
    @IBInspectable  public var placeholderColor: UIColor = UIColor.lightGray {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }
    
    @IBInspectable  public override  var font: UIFont! {
        didSet {
            placeholderLabel.font = font
        }
    }
    
    @IBInspectable  public override  var textAlignment: NSTextAlignment {
        didSet {
            placeholderLabel.textAlignment = textAlignment
        }
    }
    
    @IBInspectable  public override  var text: String! {
        didSet {
            textDidChange()
        }
    }
    
    @IBInspectable  public override  var attributedText: NSAttributedString! {
        didSet {
            textDidChange()
        }
    }
    
    @IBInspectable  public override  var textContainerInset: UIEdgeInsets {
        didSet {
            updateConstraintsForPlaceholderLabel()
        }
    }
    
    @IBInspectable public override var frame: CGRect {
        didSet {
            if frame.size != oldValue.size {
                updateConstraintsForPlaceholderLabel()
            }
        }
    }
    
    
    @IBInspectable  public override var bounds: CGRect{
        didSet {
            if bounds.size != oldValue.size {
                updateConstraintsForPlaceholderLabel()
            }
        }
    }
    
    
    public init() {
        super.init(frame: CGRect.zero, textContainer: nil)
        shareInit()
    }
    
    public override  init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        shareInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        shareInit()
    }
    
    public func shareInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(PKTextView.textDidChange), name: NSNotification.Name.UITextViewTextDidChange, object: nil)
        
        font = UIFont.systemFont(ofSize: 14)
        textColor = UIColor.darkGray
        placeholderLabel.font = font
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.textAlignment = textAlignment
        placeholderLabel.verticalAlignment = .top
        placeholderLabel.text = placeholder
        placeholderLabel.numberOfLines = 0
        placeholderLabel.backgroundColor = UIColor.clear
        addSubview(placeholderLabel)
        updateConstraintsForPlaceholderLabel()
    }
    
    fileprivate func updateConstraintsForPlaceholderLabel() {
        var rect = bounds
        rect.origin.x = textContainerInset.left + 4
        rect.origin.y = textContainerInset.top
        rect.size.width -=  textContainerInset.left +  textContainerInset.right + 8
        rect.size.height -=  textContainerInset.top +  textContainerInset.bottom
        placeholderLabel.frame = rect
    }
    
    @objc fileprivate func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UITextViewTextDidChange, object: nil)
    }
}
