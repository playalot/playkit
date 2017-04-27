//
//  PKLabel.swift
//  playkit
//
//  Created by Tbxark on 27/04/2017.
//  Copyright © 2017 Tbxark. All rights reserved.
//

import UIKit

@IBDesignable
public class PKLabel: UILabel {
    public enum VerticalAlignment: Int {
        case top    = 0
        case middle = 1
        case bottom = 2
    }
    
    @IBInspectable public  var verticalAlignment: VerticalAlignment = .middle {
        didSet {
            if verticalAlignment != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public fileprivate(set) var textContainerInset: UIEdgeInsets = UIEdgeInsets()
    
    public override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var rect = super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        switch verticalAlignment {
        case .top:
            rect.origin.y = bounds.origin.y
        case .middle:
            let space = (bounds.height - rect.height)/2.0
            rect.origin.y = bounds.origin.y + space
            textContainerInset = UIEdgeInsets(top: space, left: 0, bottom: space, right: 0)
        case .bottom:
            let space = bounds.height - rect.height
            rect.origin.y = bounds.origin.y + space
            textContainerInset = UIEdgeInsets(top: space, left: 0, bottom: space, right: 0)
        }
        return rect
    }
    
    public override func drawText(in rect: CGRect) {
        let realRect = textRect(forBounds: rect, limitedToNumberOfLines: numberOfLines)
        super.drawText(in: realRect)
    }
    
}
