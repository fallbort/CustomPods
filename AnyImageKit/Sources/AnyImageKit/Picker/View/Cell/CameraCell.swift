//
//  CameraCell.swift
//  AnyImageKit
//
//  Created by 蒋惠 on 2019/10/21.
//  Copyright © 2019-2021 AnyImageProject.org. All rights reserved.
//

import UIKit
import Cartography

public enum CameraCellType {
    case camera
    case video
}
public final class CameraCell: UICollectionViewCell {
    public var type: CameraCellType = .camera {
        didSet {
            switch type {
            case .camera:
                imageView.image = UIImage(named: "albumIcCamera")
                label.text = NELocalize.localizedString("moments_photo")
            case .video:
                imageView.image = UIImage(named: "albumIcVideo")
                label.text = NELocalize.localizedString("moments_video")
            }
        }
    }
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.image = UIImage(named: "albumIcCamera")
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    fileprivate lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
        label.textColor = UIColor.init(hex: 0xff1e76, alpha: 1)
        label.text = NELocalize.localizedString("Take photos")
        label.textAlignment = .center
        return label
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.color(hex: 0xf8f8f8)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(imageView)
        addSubview(label)
        constrain(imageView, label) {
            $0.height == 28
            $0.width == 28
            $0.centerX == $0.superview!.centerX
            $0.bottom == $0.superview!.centerY
            $1.top == $0.superview!.centerY + 2
            $1.height == 17
            $1.left == $0.superview!.left
            $1.right == $0.superview!.right
        }
    }
}
