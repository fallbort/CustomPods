//
//  JiGuangManager.swift
//  MeMeCustomPods
//
//  Created by xfb on 2023/6/14.
//

import Foundation
import JverificationSDK
import MeMeKit

public enum JiGuangImageType : Equatable {
    case checkboxNormal //协议checkbox
    case checkBoxSelected //协议checkbox
    case loginBtnNormal //登录按钮
    case loginBtnHighly //登录按钮高亮
    case loginBtnDisable //登录按钮禁用
    case logo  //logo图标
    case navBack //导航返回按钮
}

@objc public class JiGuangManager : NSObject {
    @objc public static var shared = JiGuangManager()
    //MARK: <>外部变量
    
    //MARK: <>外部block
    public var getImageBlock:((JiGuangImageType)->(image:UIImage?,size:CGSize?))?
    
    //MARK: <>生命周期开始
    fileprivate override init() {
        super.init()
    }
    //MARK: <>功能性方法
    @objc public func startup(appKey:String,isProduction:Bool,first:String,privacyNames:[String],privacyUrls:[String],connect:String = "、",last:String = "") {
        let config = JVAuthConfig()
        config.appKey = appKey
        config.channel = "App Store"
        config.isProduction = isProduction;
        config.timeout = 5000;
        config.authBlock = { (result) -> Void in
            if let result = Optional(result) {
                if let code = result["code"] as? Int, code == 8000 {
                    JVERIFICATIONService.preLogin(5000) { (result) in
                        if let result = Optional(result), let code = result["code"] as? Int,code == 7000 {
                            
                        }else if let result = Optional(result), let code = result["code"] as? Int {
                            
                        }else{
                            
                        }
                    }
                }else if let content = result["content"] {
                    
                }
            }
        }
        JVERIFICATIONService.setup(with: config)
        JVERIFICATIONService.setDebug(!isProduction)
        
//        customWindowUI(privacyName:privacyName,privacyUrl:privacyUrl)
        var datas:[(name:String,url:String)] = []
        for (index,name) in privacyNames.enumerated() {
            if privacyUrls.count > index {
                let url = privacyUrls[index]
                datas.append((name,url))
            }
        }
        customFullScreenUI(first: first, privacys: datas,connect: connect,last: last)
    }
    
    public func startLogin(workingChangeBlock:((_ isWorking:Bool)->())? = nil,complete:@escaping ((_ loginToken:String?,_ errorCode:Int)->())) {
        
        guard JVERIFICATIONService.checkVerifyEnable() == true else {
            complete(nil,JiGuangErrorCode.NetInvalid.rawValue)
            return
        }
        DispatchQueue.main.async {
            workingChangeBlock?(true)
        }
        
        if let vc = ScreenUIManager.topViewController() {
            JVERIFICATIONService.getAuthorizationWith(vc, hide: true, animated: true, timeout: 15*1000, completion: { (result) in
                if let result = Optional(result),let token = result["loginToken"] as? String, token.count > 0 {
                    DispatchQueue.main.async {
                        workingChangeBlock?(false)
                        complete(token,0)
                    }
                }else if let result = Optional(result), let code = result["code"] as? Int {
                    DispatchQueue.main.async {
                        workingChangeBlock?(false)
                        complete(nil,code)
                    }
                }else{
                    DispatchQueue.main.async {
                        workingChangeBlock?(false)
                        complete(nil,-99996)
                    }
                }
            }) { (type, content) in

            }
        }else{
            DispatchQueue.main.async {
                workingChangeBlock?(false)
                complete(nil,-99997)
            }
        }
    }
    
    public func clearLoginCache() {
        JVERIFICATIONService.clearPreLoginCache()
    }
    
    //全屏模式
    func customFullScreenUI(first:String,privacys:[(name:String,url:String)],connect:String = "、",last:String = "") {
        let config = JVUIConfig()
        //导航栏
        config.navCustom = false
        config.navTransparent = true
        config.navReturnHidden = false
        
        config.shouldAutorotate = false
        config.autoLayout = true
        
        let navBack = self.getImageBlock?(.navBack)
        config.navReturnImg = navBack?.image ?? UIImage()
        config.navText = NSAttributedString()
        config.navReturnImageEdgeInsets = UIEdgeInsets.init(top: 0, left: -30, bottom: 0, right: 0)
        //弹窗弹出方式
        config.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        
        //号码栏
        let numberConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant:0)
        let numberConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.login, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant:-22)
        let numberConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant:230)
        let numberConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant:36)
        config.numberConstraints = [numberConstraintX!, numberConstraintY!, numberConstraintW!, numberConstraintH!]
        config.numberHorizontalConstraints = config.numberConstraints
        config.numberFont = ThemeLite.Font.pingfang(size: 28,weight: .medium)
        config.numberColor = UIColor.hexString(toColor: "222222")!
        
        //slogan
        let sloganConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant:0)
        let sloganConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.login, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant:-6)
        let sloganConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant:230)
        let sloganConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant:20)
        config.sloganConstraints = [sloganConstraintX!, sloganConstraintY!, sloganConstraintW!, sloganConstraintH!]
        config.sloganHorizontalConstraints = config.sloganConstraints
        
        //登录按钮
        let loginBottom:CGFloat = 268.0 + UIWindow.keyWindowSafeAreaInsets().bottom
        let login_nor_image = self.getImageBlock?(.loginBtnNormal)
        let login_dis_image = self.getImageBlock?(.loginBtnDisable)
        let login_hig_image = self.getImageBlock?(.loginBtnHighly)
        if let norImage = login_nor_image?.image, let disImage = login_dis_image?.image, let higImage = login_hig_image?.image {
            config.logBtnImgs = [norImage, disImage, higImage]
        }
        config.logBtnText = NELocalize.localizedString("本机号码一键登录",comment: "totest")
        config.logBtnFont = ThemeLite.Font.pingfang(size: 16)
        config.logBtnTextColor = UIColor.hexString(toColor: "ffffff")!
        let loginBtnWidth = login_nor_image?.size?.width ?? 100
        let loginBtnHeight = login_nor_image?.size?.height ?? 50
        let loginConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant:0)
        let loginConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant:-loginBottom)
        let loginConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant:loginBtnWidth)
        let loginConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant:loginBtnHeight)
        config.logBtnConstraints = [loginConstraintX!, loginConstraintY!, loginConstraintW!, loginConstraintH!]
        config.logBtnHorizontalConstraints = config.logBtnConstraints
        
        //logo
        
        let logoImg = self.getImageBlock?(.logo)
        config.logoImg = logoImg?.image ?? UIImage()
        let logoWidth = logoImg?.size?.width ?? 100
        let logoHeight = logoImg?.size?.height ?? 100
        let logoCenterY:CGFloat = (UIScreen.main.bounds.height - loginBottom - loginBtnHeight) / 2.0
        let logoConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let logoConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: logoCenterY)
        let logoConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: logoWidth)
        let logoConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: logoHeight)
        config.logoConstraints = [logoConstraintX!,logoConstraintY!,logoConstraintW!,logoConstraintH!]
        config.logoHorizontalConstraints = config.logoConstraints
        
        //勾选框
        let checkBoxLeft:CGFloat = 38
        let uncheckedImage = self.getImageBlock?(.checkboxNormal)
        let checkedImage = self.getImageBlock?(.checkBoxSelected)
        let checkViewWidth = uncheckedImage?.size?.width ?? 10
        let checkViewHeight = uncheckedImage?.size?.height ?? 10
        config.uncheckedImg = uncheckedImage?.image ?? UIImage()
        config.checkedImg = checkedImage?.image ?? UIImage()
        let checkViewConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant:checkBoxLeft)
        let checkViewConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.privacy, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant:0)
        let checkViewConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant:checkViewWidth)
        let checkViewConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant:checkViewHeight)
        config.checkViewConstraints = [checkViewConstraintX!, checkViewConstraintY!, checkViewConstraintW!, checkViewConstraintH!]
        config.checkViewHorizontalConstraints = config.checkViewConstraints
        
        //隐私
        let spacingLeft:CGFloat = 60
        let spacingRight:CGFloat = -35
        config.privacyState = true
        config.privacyTextFontSize = 14
        config.appPrivacyColor = [UIColor.hexString(toColor: "#999999")!,UIColor.hexString(toColor: "#222222")!]
        config.privacyTextAlignment = NSTextAlignment.left
        var appPrivacyDict:[Any] = []
        appPrivacyDict.append(first)
        for data in privacys {
            appPrivacyDict.append([connect,data.name,data.url,data.name])
        }
        appPrivacyDict.append(last)
        config.appPrivacys = appPrivacyDict
        config.privacyShowBookSymbol = true
        let privacyConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant:spacingLeft)
        let privacyConstraintX2 = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant:spacingRight)
        let privacyConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant:-10)
        let privacyConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant:50)
        config.privacyConstraints = [privacyConstraintX!,privacyConstraintX2!, privacyConstraintY!, privacyConstraintH!]
        config.privacyHorizontalConstraints = config.privacyConstraints
        
       //loading
        let loadingConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant:0)
        let loadingConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant:0)
        let loadingConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant:30)
        let loadingConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant:30)
        config.loadingConstraints = [loadingConstraintX!, loadingConstraintY!, loadingConstraintW!, loadingConstraintH!]
        config.loadingHorizontalConstraints = config.loadingConstraints
        
        //协议弹窗
        config.agreementNavReturnImage = navBack?.image ?? UIImage()
        config.agreementNavTextColor = UIColor.hexString(toColor: "222222")!
        
        
        JVERIFICATIONService.customUI(with: config) { (customView) in
            //自定义view, 加到customView上
        }
        
       }
    //弹窗模式
    fileprivate func customWindowUI(privacyName:String,privacyUrl:String) {
        let config = JVUIConfig()
        config.navCustom = true
        config.autoLayout = true
        config.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        
        //弹窗
        config.showWindow = true
        config.windowCornerRadius = 10
        config.windowBackgroundAlpha = 0.3
        
        let windowW: CGFloat = 300
        let windowH: CGFloat = 300
        let windowConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let windowConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
        let windowConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: windowW)
        let windowConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: windowH)
        config.windowConstraints = [windowConstraintX!, windowConstraintY!, windowConstraintW!, windowConstraintH!]
        config.windowHorizontalConstraints = config.windowConstraints
        
        
        //弹窗close按钮
        let window_close_nor_image = imageNamed(name: "windowClose")
        let window_close_hig_image = imageNamed(name: "windowClose")
        if let norImage = window_close_nor_image, let higImage = window_close_hig_image {
            config.windowCloseBtnImgs = [norImage, higImage]
        }
        let windowCloseBtnWidth = window_close_nor_image?.size.width ?? 15
        let windowCloseBtnHeight = window_close_nor_image?.size.height ?? 15
        
        let windowCloseBtnConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: -5)
        let windowCloseBtnConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 5)
        let windowCloseBtnConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: windowCloseBtnWidth)
        let windowCloseBtnConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: windowCloseBtnHeight)
        config.windowCloseBtnConstraints = [windowCloseBtnConstraintX!, windowCloseBtnConstraintY!, windowCloseBtnConstraintW!, windowCloseBtnConstraintH!]
        config.windowCloseBtnHorizontalConstraints = config.windowCloseBtnConstraints
        
        //logo
        config.logoImg = UIImage(named: "cmccLogo") ?? UIImage()
        let logoWidth = config.logoImg.size.width
        let logoHeight = logoWidth
        let logoConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let logoConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 10)
        let logoConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: logoWidth)
        let logoConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: logoHeight)
        config.logoConstraints = [logoConstraintX!,logoConstraintY!,logoConstraintW!,logoConstraintH!]
        config.logoHorizontalConstraints = config.logoConstraints
               
        //号码栏
        let numberConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant:0)
        let numberConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant:130)
        let numberConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant:130)
        let numberConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant:25)
        config.numberConstraints = [numberConstraintX!, numberConstraintY!, numberConstraintW!, numberConstraintH!]
        config.numberHorizontalConstraints = config.numberConstraints
               
        //slogan
        let sloganConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant:0)
        let sloganConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant:160)
        let sloganConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant:130)
        let sloganConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant:20)
        config.sloganConstraints = [sloganConstraintX!, sloganConstraintY!, sloganConstraintW!, sloganConstraintH!]
        config.sloganHorizontalConstraints = config.sloganConstraints
               
        //登录按钮
        let login_nor_image = imageNamed(name: "loginBtn_Nor")
        let login_dis_image = imageNamed(name: "loginBtn_Dis")
        let login_hig_image = imageNamed(name: "loginBtn_Hig")
        if let norImage = login_nor_image, let disImage = login_dis_image, let higImage = login_hig_image {
            config.logBtnImgs = [norImage, disImage, higImage]
        }
        let loginBtnWidth = login_nor_image?.size.width ?? 100
        let loginBtnHeight = login_nor_image?.size.height ?? 100
        let loginConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant:0)
        let loginConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant:180)
        let loginConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant:loginBtnWidth)
        let loginConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant:loginBtnHeight)
        config.logBtnConstraints = [loginConstraintX!, loginConstraintY!, loginConstraintW!, loginConstraintH!]
        config.logBtnHorizontalConstraints = config.logBtnConstraints
               
        //勾选框
        let uncheckedImage = imageNamed(name: "checkBox_unSelected")
        let checkedImage = imageNamed(name: "checkBox_selected")
        let checkViewWidth = uncheckedImage?.size.width ?? 10
        let checkViewHeight = uncheckedImage?.size.height ?? 10
        config.uncheckedImg = uncheckedImage ?? UIImage()
        config.checkedImg = checkedImage ?? UIImage()
        let checkViewConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant:20)
        let checkViewConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.privacy, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant:0)
        let checkViewConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant:checkViewWidth)
        let checkViewConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant:checkViewHeight)
        config.checkViewConstraints = [checkViewConstraintX!, checkViewConstraintY!, checkViewConstraintW!, checkViewConstraintH!]
        config.checkViewHorizontalConstraints = config.checkViewConstraints
               
        //隐私
        let spacing = checkViewWidth + 20 + 5
        config.privacyState = true
        config.privacyTextAlignment = NSTextAlignment.left
        config.appPrivacyOne = [privacyName,privacyUrl]
        let privacyConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant:spacing)
        let privacyConstraintX2 = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant:-spacing)
        let privacyConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant:-20)
        let privacyConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant:50)
        config.privacyConstraints = [privacyConstraintX!,privacyConstraintX2!, privacyConstraintY!, privacyConstraintH!]
        config.privacyHorizontalConstraints = config.privacyConstraints
               
        //loading
        let loadingConstraintX = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant:0)
        let loadingConstraintY = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.super, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant:0)
        let loadingConstraintW = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant:30)
        let loadingConstraintH = JVLayoutConstraint(attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, to: JVLayoutItem.none, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant:30)
        config.loadingConstraints = [loadingConstraintX!, loadingConstraintY!, loadingConstraintW!, loadingConstraintH!]
        config.loadingHorizontalConstraints = config.loadingConstraints
               
        JVERIFICATIONService.customUI(with: config) { (customView) in
            //自定义view, 加到customView上
            guard let customV = Optional(customView) else {
                return
            }
        }
   
    }
    
    fileprivate func imageNamed(name: String) -> UIImage? {
        if let bundlePath = Bundle.main.path(forResource: "JVerificationResource", ofType: "bundle") {
            let image = UIImage(contentsOfFile: bundlePath + "/\(name).png")
            return image
        }
        return nil
    }
    
    //MARK: <>内部View
    
    //MARK: <>内部UI变量
    //MARK: <>内部数据变量
    
    //MARK: <>内部block
    
}
