//
//  imagepickerTitleView.swift
//  imagepicker
//
//  Created by Tbxark on 26/12/2016.
//  Copyright © 2016 Tbxark. All rights reserved.
//

import UIKit


typealias TKTitleViewStateChange = (Bool) -> Void

class imagepickerTitleView: UIButton {
    var title: String = " " {
        didSet {
            setTitle(title + "  ", for: .normal)
            alignImageRight()
        }
    }
    var isOpen = false {
        didSet {
            setImage(isOpen ? stateImage.on : stateImage.off, for: .normal)
        }
    }
    let stateImage = (on: UIImage.ip_imageWithName("ip_select_album"), off: UIImage.ip_imageWithName("ip_select_album_off"))

    init() {
        super.init(frame: CGRect.zero)
        shareInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        shareInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        shareInit()
    }
    
    func shareInit() {
        
        
        setImage(stateImage.off, for: .normal)
        setTitle(" ", for: .normal)
        imageView?.contentMode = .scaleAspectFit
        setTitleColor(UIColor.darkGray, for: .normal)
        
        titleLabel?.textAlignment = .center
        titleLabel?.font = UIFont.systemFont(ofSize: 16)
        title = ""
    }
    
    func alignImageRight() {
        if let titleLabel = titleLabel, let imageView = imageView {
            titleLabel.sizeToFit()
            imageView.sizeToFit()
            imageView.contentMode = .scaleAspectFit
            
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -1 * imageView.frame.size.width,
                                                bottom: 0, right: imageView.frame.size.width)
            self.imageEdgeInsets = UIEdgeInsets(top: 4, left: titleLabel.frame.size.width,
                                                bottom: 4, right: -1 * titleLabel.frame.size.width)
        }
    }
}
