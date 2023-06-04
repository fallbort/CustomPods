//
//  AlbumCell.swift
//  AnyImageKit
//
//  Created by 刘栋 on 2019/9/17.
//  Copyright © 2019-2021 AnyImageProject.org. All rights reserved.
//

import UIKit

final class AlbumCell: UITableViewCell {
    
    private lazy var posterImageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFill
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        view.textColor = UIColor.init(hex: 0x3c3c3c)
        return view
    }()
    
    private lazy var subTitleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        view.textColor = UIColor.init(hex: 0xbcbcbc)
        return view
    }()
    
    private lazy var separatorLine: UIView = {
        let view = UIView(frame: .zero)
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // Subviews
        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleLabel)
//        addSubview(separatorLine)
        posterImageView.snp.makeConstraints { maker in
            maker.left.equalTo(contentView.snp.left).offset(16)
            maker.top.equalTo(contentView.snp.top).offset(12)
            maker.bottom.equalTo(contentView.snp.bottom).offset(-12)
            maker.width.equalTo(posterImageView.snp.height)
        }
        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(contentView.snp.centerY)
            maker.left.equalTo(posterImageView.snp.right).offset(16)
        }
        subTitleLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(contentView.snp.centerY)
            maker.left.equalTo(titleLabel.snp.right).offset(8)
        }
//        separatorLine.snp.makeConstraints { maker in
//            maker.left.right.bottom.equalToSuperview()
//            maker.height.equalTo(0.5)
//        }
    }
}

extension AlbumCell {
    
    private func updateTheme(_ theme: PickerTheme) {
        tintColor = theme.mainColor
        backgroundColor = theme.backgroundColor
        let view = UIView(frame: .zero)
        view.backgroundColor = theme.selectedCellColor
        selectedBackgroundView = view
        titleLabel.textColor = theme.textColor
        subTitleLabel.textColor = theme.subTextColor
        separatorLine.backgroundColor = theme.separatorLineColor
    }
}

extension AlbumCell {
    
    func setContent(_ album: Album, manager: PickerManager) {
        updateTheme(manager.options.theme)
        titleLabel.text = album.title
        subTitleLabel.text = "(\(album.count))"
        manager.requestPhoto(for: album) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.posterImageView.image = response.image
            case .failure(let error):
                _print(error)
            }
        }
    }
}
