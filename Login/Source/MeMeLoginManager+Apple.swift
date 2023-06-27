//
//  MeMeLoginModel+Apple.swift
//  MeMeCustomPods
//
//  Created by xfb on 2023/6/27.
//

import Foundation
import AuthenticationServices
import MeMeKit
import MeMeComponents

public struct AppleLoginResponseData {
    var token:String
    var uid:String
    var authorizationCode:String
}

extension MeMeLoginManager {
    public func loginWithApple(complete:((_ res:AppleLoginResponseData?,_ error:CustomNSError?)->())?) {
        if #available(iOS 13.0, *) {
            let changingSuccess = self.loginkeeper.setStartChanging(id: LoginType.apple) { statusValue in
                if let result = statusValue as? (res:AppleLoginResponseData?,error:CustomNSError?) {
                    complete?(result.res,result.error)
                }
            }
            if changingSuccess == true {
                let appleIDProvider = ASAuthorizationAppleIDProvider()
                let request = appleIDProvider.createRequest()
                request.requestedScopes = [.fullName]
                
                let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                authorizationController.delegate = self
                authorizationController.presentationContextProvider = self
                authorizationController.performRequests()
            }
        }
    }
}

@available(iOS 13.0, *)
extension MeMeLoginManager: ASAuthorizationControllerDelegate {
    /// - Tag: did_complete_authorization
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            if let codeData = appleIDCredential.authorizationCode {
                if let authorizationCode = String(data: codeData, encoding: .utf8) {
                    if let tokenData = appleIDCredential.identityToken {
                        if let identityToken = String(data: tokenData, encoding: .utf8) {
                            let response = AppleLoginResponseData.init(token: identityToken, uid: appleIDCredential.user, authorizationCode: authorizationCode)
                            self.makeEndResponse(data: response, error: nil)
                        } else {
                            let error = NSError.init(domain: MemeErrorDomain, code: 5)
                            let memeError = MemeCommonError.normal(error)
                            self.makeEndResponse(data: nil, error: memeError)
                        }
                    } else {
                        let error = NSError.init(domain: MemeErrorDomain, code: 4)
                        let memeError = MemeCommonError.normal(error)
                        self.makeEndResponse(data: nil, error: memeError)
                    }
                } else {
                    let error = NSError.init(domain: MemeErrorDomain, code: 3)
                    let memeError = MemeCommonError.normal(error)
                    self.makeEndResponse(data: nil, error: memeError)
                }
            } else {
                let error = NSError.init(domain: MemeErrorDomain, code: 2)
                let memeError = MemeCommonError.normal(error)
                self.makeEndResponse(data: nil, error: memeError)
            }
        default:
            let error = NSError.init(domain: MemeErrorDomain, code: 1)
            let memeError = MemeCommonError.normal(error)
            self.makeEndResponse(data: nil, error: memeError)
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        switch (error as NSError).code {
        case ASAuthorizationError.canceled.rawValue:
            self.makeEndResponse(data: nil, error: MemeCommonError.cancel)
        default:
            let memeError = MemeCommonError.normal(error as NSError)
            self.makeEndResponse(data: nil, error: memeError)
        }
    }
    
    fileprivate func makeEndResponse(data:AppleLoginResponseData?,error:MemeCommonError?) {
        let value:(res:AppleLoginResponseData?,error:CustomNSError?) = (data,error)
        self.loginkeeper.setStatus(id: LoginType.apple, value: value)
        self.loginkeeper.setEndChanging(id: LoginType.apple)
    }
}

@available(iOS 13.0, *)
extension MeMeLoginManager: ASAuthorizationControllerPresentationContextProviding {
    /// - Tag: provide_presentation_anchor
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return ScreenUIManager.topWindow() ?? (UIApplication.shared.keyWindow) ?? UIWindow()
    }
}
