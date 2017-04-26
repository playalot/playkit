//
//  imagepickerViewController.swift
//  imagepicker
//
//  Created by Tbxark on 26/12/2016.
//  Copyright © 2016 Tbxark. All rights reserved.
//

import UIKit
import Photos


public protocol imagepickerViewControllerDelegate: class {
    func imagepickerViewController(_ controller: imagepickerViewController, cancelSelect: Void)
    // 选中图片
    func imagepickerViewController(_ controller: imagepickerViewController, didSelect photo: PhotoModel)
    // 取消选中图片
    func imagepickerViewController(_ controller: imagepickerViewController, didDeselect photo: PhotoModel)
    // 最终选择图片
    func imagepickerViewController(_ controller: imagepickerViewController, commitSelect  image: UIImage)
    // 最终选择图片
    func imagepickerViewController(_ controller: imagepickerViewController, commitSelect photos: [PhotoModel])
}

extension imagepickerViewControllerDelegate {
    public func imagepickerViewController(_ controller: imagepickerViewController, cancelSelect: Void) {}
    public func imagepickerViewController(_ controller: imagepickerViewController, didSelect photo: PhotoModel) {}
    public func imagepickerViewController(_ controller: imagepickerViewController, didDeselect photo: PhotoModel) {}
    public func imagepickerViewController(_ controller: imagepickerViewController, commitSelect capture: UIImage) {}
    public func imagepickerViewController(_ controller: imagepickerViewController, commitSelect photos: [PhotoModel]) {}

}


public class imagepickerViewController: UIViewController {

    public let config: imagepickerConfig
    public weak var delegate: imagepickerViewControllerDelegate?
    fileprivate var _prefersStatusBarHidden = false
    let navBar = NavigationBar()
    let albumController: AlbumViewController
    let photoController: PhotoViewController
    
    
    
    public init(config: imagepickerConfig) {
        self.config = config
        self.albumController = AlbumViewController(config: config)
        self.photoController = PhotoViewController(config: config)
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        shareInit()
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
        
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !_prefersStatusBarHidden {
            UIView.animate(withDuration: 5/60.0, animations: {
                self._prefersStatusBarHidden = true
                self.setNeedsStatusBarAppearanceUpdate()
            })
        }
    }
    
    override public var prefersStatusBarHidden : Bool {
        return _prefersStatusBarHidden
    }
    
    override public var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
}


extension imagepickerViewController {
    func shareInit() {
        
        navBar.titleView.addTarget(self, action: #selector(imagepickerViewController.albumButtonDidClick(_:)), for: .touchUpInside)
        navBar.continueButton.isEnabled = false
        var rect = view.bounds
        rect.size.height -= navBar.frame.height
        rect.origin.y = navBar.frame.height
        photoController.view.frame = rect
        rect.origin.y = -rect.size.height
        albumController.view.frame = rect
        view.addSubview(photoController.view)
        view.addSubview(albumController.view)
        view.addSubview(navBar)
        view.clipsToBounds = true
        albumController.delegate = self
        photoController.delegate = self
        
        navBar.cancelButton.addTarget(self, action: #selector(imagepickerViewController.cancelButtonClick(_:)), for: .touchUpInside)
        navBar.continueButton.addTarget(self, action: #selector(imagepickerViewController.continueButtonClick(_:)), for: .touchUpInside)

        
    }
}


extension imagepickerViewController {
    
    func cancelButtonClick(_ btn: UIButton) {
        delegate?.imagepickerViewController(self, cancelSelect: ())
    }
    
    func continueButtonClick(_ btn:UIButton) {
        delegate?.imagepickerViewController(self, commitSelect: photoController.viewModel.selectPhotos)
    }
    
    func albumButtonDidClick(_ btn: imagepickerTitleView) {
        changeAlbumControllerState(isOpen: !btn.isOpen)
    }
    
    func changeAlbumControllerState( isOpen : Bool) {
        if isOpen {
            var rect = view.bounds
            rect.size.height -= navBar.frame.height
            rect.origin.y = navBar.frame.height
            UIView.animate(withDuration: 0.2, animations: { 
                self.albumController.view.frame = rect
            })
        } else {
            var rect = view.bounds
            rect.size.height -= navBar.frame.height
            rect.origin.y = -rect.size.height
            UIView.animate(withDuration: 0.2, animations: {
                self.albumController.view.frame = rect
            })
        }
        navBar.titleView.isOpen = isOpen
    }


}


extension imagepickerViewController:  AlbumViewControllerDelegate, PhotoViewControllerDelegate, CameraViewControllerDelegate {
    internal func albumViewController(_ controller: AlbumViewController, didSelect album: AlbumModel) {
        photoController.albumDataModel = album.fetchResult
        navBar.setTitle(album.title, state: false)
        changeAlbumControllerState(isOpen: false)
    }
    
    internal func albumViewController(_ controller: AlbumViewController, didLoad albums: [AlbumModel]) {
        guard let data = albums.first else {return}
        photoController.albumDataModel = data.fetchResult
        navBar.setTitle(data.title, state: false)
    }
    
    internal func cameraViewController(_ controller: CameraViewController, capture image: UIImage?) {
        if let img = image {
            // 保存后调用回调函数
            imagepickerConfig.HUG.show()
            AlbumManager.saveImage(image: img, complete: {[weak self] (isSuccess, error) in
                guard let `self` = self else { return }
                if isSuccess {
                    imagepickerConfig.HUG.dismiss()
                } else {
                    imagepickerConfig.HUG.error(error)
                }
                self.albumController.viewModel.refreshAblumArray()
                self.delegate?.imagepickerViewController(self, commitSelect: img)
                controller.dismiss(animated: true , completion: nil)
            })
        } else {
            imagepickerConfig.HUG.error(nil)
            controller.dismiss(animated: false, completion: nil)
        }
        
    }
    
    internal func photoPickerSelectCamera(_ controller: PhotoViewController) {
        let camera = CameraViewController()
        camera.delegate = self
        present(camera, animated: true, completion: nil)
    }
    
    internal func photoPickerDidSelect(_ controller: PhotoViewController, model: PhotoModel) {
        navBar.setCount(photoController.viewModel.count)
        navBar.continueButton.isEnabled = photoController.viewModel.count > 0
        delegate?.imagepickerViewController(self, didSelect: model)
    }
    
    internal func photoPickerDidDeselect(_ controller: PhotoViewController, model: PhotoModel) {
        navBar.continueButton.isEnabled = photoController.viewModel.count > 0
        navBar.setCount(photoController.viewModel.count)
        delegate?.imagepickerViewController(self, didDeselect: model)
    }

}
