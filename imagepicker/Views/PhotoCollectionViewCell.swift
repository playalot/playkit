//
//  PhotoCollectionViewCell.swift
//  imagepicker
//
//  Created by Tbxark on 26/12/2016.
//  Copyright © 2016 Tbxark. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    static let iden = "PhotoCollectionViewCell"
    static let size: CGSize = {
        let c =  CGFloat(imagepickerConfig.numOfRow)
        let s = CGFloat(2)
        let w = (UIScreen.main.bounds.width - (c - 1) * s)/c
        return CGSize(width: w, height: w)
    }()
    
    private let selectIndex = UILabel()
    private let selectMask  = UIView()
    private let imageView   = UIImageView()
    
    private(set) var assetIdentifier = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        shareInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func shareInit() {
        
        selectIndex.layer.borderColor = UIColor.white.cgColor
        selectIndex.layer.borderWidth = 2
        selectIndex.backgroundColor = imagepickerConfig.defaultColor
        selectIndex.layer.cornerRadius = 10
        selectIndex.clipsToBounds = true
        selectIndex.textAlignment = .center
        selectIndex.textColor = UIColor.darkGray
        selectIndex.font = UIFont.boldSystemFont(ofSize: 12)
        
        selectMask.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        selectMask.isHidden = true

        contentView.addSubview(imageView)
        contentView.addSubview(selectMask)
        contentView.addSubview(selectIndex)
        imageView.backgroundColor = UIColor.white

        
        let cons = contentView.makeConstraints(vlfs: ["H:|-0-[img]-0-|",
                                                      "V:|-0-[img]-0-|",
                                                      "H:|-0-[msk]-0-|",
                                                      "V:|-0-[msk]-0-|",
                                                      "H:[idx(==20)]-5-|",
                                                      "V:|-5-[idx(==20)]"], views: ["img": imageView,
                                                                                    "msk": selectMask,
                                                                                    "idx": selectIndex])
        contentView.addConstraints(cons)
    }
    
    func changeState(select: Bool, index: Int?) {
        if select {
            selectMask.isHidden = false
            if let i = index {
                selectIndex.isHidden = false
                selectIndex.text = "\(i + 1)"
            }
        } else {
            selectMask.isHidden = true
            selectIndex.isHidden = true
        }
    }
    
    func clear() {
        imageView.image = nil
        assetIdentifier = ""
    }
    
    func setImage(_ img: UIImage?) {
        imageView.image = img
    }
    
    func configureWithCameraMode() {
        imageView.image = UIImage.ip_imageWithName("ip_camera_icon")
//        imageView.contentMode = .center
        changeState(select: false, index: nil)
    }
    
    func configureWithDataModel(_ dataModel: PhotoModel) {
        assetIdentifier = dataModel.asset.localIdentifier
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }
}
