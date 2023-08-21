//
//  WKWebCardVC.swift
//  MeMe
//
//  Created by fabo on 2022/12/2.
//  Copyright © 2022 sip. All rights reserved.
//

import Foundation

import Foundation
import Cartography
import MeMeKit

public class WKWebCardVC : UIViewController, BottomCardProtocol {
    
    //MARK: <>外部变量
    public var hasTitle = false {
        didSet {
            topViewHeightLayout?.constant = hasTitle ? 50 : 0
        }
    }
    
    //MARK: <>外部block
    
    //MARK: <>生命周期开始
    required init() {
        super.init(nibName: nil, bundle: nil)
        self.contentSizeInPopup = CGSize.init(width: UIScreen.main.bounds.width, height: 426)
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        contentVC.titleChangeObser.subscribe(onNext: { [weak self] title in
            guard let `self` = self else { return }
            self.topLabel.text = title
        }).disposed(by: self.mmDisposeBag)
    }
    
    func setupViews() {
        self.view.backgroundColor = .white
        let line = UIView()
        line.backgroundColor = UIColor.hexString(toColor: "f6f7f9")
        line.isUserInteractionEnabled = false
        
        contentVC.addTo(self, rect: self.view.bounds)
        self.view.addSubview(topView)
        topView.addSubview(line)
        
        constrain(topView) {
            $0.left == $0.superview!.left
            $0.right == $0.superview!.right
            $0.top == $0.superview!.top
            topViewHeightLayout = ($0.height == 0)
        }
        constrain(line) {
            $0.left == $0.superview!.left
            $0.right == $0.superview!.right
            $0.bottom == $0.superview!.bottom
            $0.height == 1
        }
        constrain(contentVC.view,topView) {
            $0.left == $0.superview!.left
            $0.right == $0.superview!.right
            $0.top == $1.bottom
            $0.bottom == $0.superview!.bottom
        }
        
        topViewHeightLayout?.constant = hasTitle ? 50 : 0
    }
    
    //MARK: <>功能性方法
    //MARK: <>内部View
    public var contentVC:WKWebController = WKWebController()
    
    lazy var topView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.clipsToBounds = true
        view.addSubview(topLabel)
        constrain(topLabel) {
            $0.left >= $0.superview!.left + 25
            $0.right <= $0.superview!.right - 25
            $0.center == $0.superview!.center
        }
        return view
    }()
    
    var topLabel: UILabel = {
        let view = UILabel()
        view.font = ThemeLite.Font.medium(size: 16)
        view.textColor =  UIColor.hexString(toColor: "#3c3c3c")!
        return view
    }()
    //MARK: <>内部UI变量
    fileprivate var topViewHeightLayout:NSLayoutConstraint?
    //MARK: <>内部数据变量
    //MARK: <>内部block
    
}

