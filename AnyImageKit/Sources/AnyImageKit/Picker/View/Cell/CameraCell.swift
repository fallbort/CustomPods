//
//  CameraCell.swift
//  AnyImageKit
//
//  Created by 蒋惠 on 2019/10/21.
//  Copyright © 2019-2021 AnyImageProject.org. All rights reserved.
//

import UIKit
import MeMeKit

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
                label.text = NELocalize.localizedString("photo")
            case .video:
                imageView.image = UIImage(named: "albumIcVideo")
                label.text = NELocalize.localizedString("video")
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
        imageView.snp.makeConstraints { maker in
            maker.bottom.equalTo(self.snp.centerY)
            maker.centerX.equalTo(self.snp.centerX)
            maker.width.equalTo(28)
            maker.height.equalTo(28)
        }
        label.snp.makeConstraints { maker in
            maker.top.equalTo(self.snp.centerY).offset(2)
            maker.left.equalTo(self.snp.left)
            maker.right.equalTo(self.snp.right)
            maker.height.equalTo(17)
        }
    }
}
