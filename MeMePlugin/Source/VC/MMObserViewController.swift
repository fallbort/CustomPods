//
//  MMObserViewController.swift
//  MeMeCustomPods
//
//  Created by xfb on 2023/8/2.
//

import Foundation

import Foundation
import Cartography
import MeMeKit
import RxSwift

public class MMObserViewController : UIViewController {
    
    //MARK: <>外部变量
    
    //MARK: <>外部block
    public var viewDidLoadedObser = BehaviorSubject<Bool>(value: false)
    public var viewDidLayoutedObser = BehaviorSubject<Bool>(value: false)
    public var viewIsWillAppearedObser = BehaviorSubject<Bool>(value: false)
    public var viewIsDidAppearedObser = BehaviorSubject<Bool>(value: false)
    
    
    //MARK: <>生命周期开始
    public required init() {
        super.init(nibName: nil, bundle: nil)
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadedObser.onNext(true)
        viewDidLayoutedObser.onNext(true)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewIsWillAppearedObser.onNext(true)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewIsDidAppearedObser.onNext(true)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewIsWillAppearedObser.onNext(false)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewIsDidAppearedObser.onNext(false)
    }
    
    //MARK: <>功能性方法
    //MARK: <>内部View
    //MARK: <>内部UI变量
    //MARK: <>内部数据变量
    //MARK: <>内部block
    
}

