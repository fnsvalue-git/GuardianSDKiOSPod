//
//  GuardianService.swift
//  GuardianFramework
//
//  Created by Jayhy on 07/07/2020.
//  Copyright © 2020 fns_mac_pro. All rights reserved.
//

import Foundation
import Alamofire
import CryptoSwift
import CoreMotion
import AVFoundation
import SwiftyJSON
import DeviceKit

//MARK: - RtCode
public enum RtCode : Int {
    case AUTH_SUCCESS = 0
    case AUTH_PROCESSING = 2010
    
    case PUSH_LOGIN = 1000; // 로그인 푸시
    case PUSH_LOGIN_CANCEL = 1001; // 로그인 취소 푸시
    case PUSH_LOGIN_SUCCESS = 1002; // 로그인 성공 푸시
    case PUSH_LOGIN_FAIL = 1003; // 로그인 실패 푸시
    case PUSH_VERIFICATION_1 = 1004; // 첫번째 검증요청 푸시
    case PUSH_VERIFICATION_2 = 1005; // 두번째 검증요청 푸시
    
    case COMM_FIND_CLIENT_FAIL = 2000
    case COMM_SERVER_ERROR = 2001
    case COMM_REQUEST_PARAM_ERROR = 2002
    case COMM_SESSION_ERROR = 2003
    case AUTH_CHANNDEL_NOT_EXIST = 2004
    case MEMBER_MAX_USER_LICENSE_EXPIRY = 2005
    case MEMBER_MAX_AUTH_LICENSE_EXPIRY = 2006
    case MEMBER_NOT_REGISTER = 2007
    case MEMBER_DEVICE_NOT_REGISTER = 2008
    case MEMBER_MULTIPLE_JOIN = 2009
    
    case COMM_FAIL_LICENSE_CONSISTENCY = 2011
    case COMM_MAINTENANCE_SERVER = 2012
    case MEMBER_LICENSE_TERM_EXPIRY = 2013
    case COMM_FIND_LICENSE_FAIL = 2014
    case COMM_DUPLICATE_CLIENT = 2015
    case COMM_DUPLICATE_LICENSE = 2016
    case COMM_DUPLICATE_REQUEST_LICENSE = 2017
    
    case MEMBER_FIND_AUTH_TYPE_FAIL = 3000
    case MEMBER_FIND_ICON_SELECT_FAIL = 3001
    case MEMBER_FIND_PERSONAL_INFO_AGREE_FAIL = 3002
    case MEMBER_FIND_UUID_INFO_AGREE_FAIL = 3003
    case MEMBER_AUTH_NOMAL = 3004
    case MEMBER_FAIL_VAILD_AUTH_NUM = 3005
    case MEMBER_FAIL_VAILD = 3006
    case MEMBER_FAIL_VAILD_DEVICE_ID = 3007
    case MEMBER_NO_ACCESS_ADMIN_PAGE = 3008
    case MEMBER_FIND_FCM_TOKEN_FAIL = 3009
    case MEMBER_FIND_STATUS_FAIL = 3010
    
    case AUTH_CERT_TIME_OUT = 5000
    case AUTH_STATUS_TIMEOUT = 5001
    case AUTH_VAILD_SESSION_ID_FAIL = 5002
    case AUTH_VAILD_IP_FAIL = 5003
    case AUTH_FAIL_VAILD_BLOCK_KEY = 5004
    case AUTH_MEMBER_STATUS_UNAPPROVAL = 5005
    case AUTH_MEMBER_STATUS_TEMP = 5006
    case AUTH_MEMBER_STATUS_PERM = 5007
    case AUTH_MEMBER_STATUS_WITHDRAW = 5008
    case AUTH_FAIL = 5010
    case AUTH_CANCEL = 5011
    case AUTH_ICON_SELECT_FAIL = 5013
    case AUTH_ADD_CHANNEL_FAIL = 5015
    case AUTH_CREATE_NODE_FAIL = 5016
    case AUTH_SEND_PUSH_FAIL = 5017
    case AUTH_REQUEST_FAIL = 5018
    case AUTH_GET_CHANNEL_FAIL = 5019
    case AUTH_DATA_DECRYPT_FAIL = 5020
    case AUTH_VERIFICATION_REQUEST_FAIL = 5021
    case AUTH_VERIFICATION_FAIL = 5022
    
    case BIOMETRIC_NORMAL = 9000
    case BIOMETRIC_NOT_AVILABLE = 9001
    case BIOMETRIC_LOCK_OUT = 9002
    case BIOMETRIC_NOT_SUPPORT_HARDWARE = 9003
    case BIOMETRIC_NOT_ENROLLED_DEVICE = 9004
    case BIOMETRIC_NOT_ENROLLED_APP = 9005
    case BIOMETRIC_CHANGE_ENROLLED = 9006
    case BIOMETRIC_ENROLLED_DUPLICATION = 9007
    case BIOMETRIC_ERROR = 9008
    case BIOMETRIC_AUTH_FAILED = 9009
    case BIOMETRIC_PASSCODE = 9010
    
    case API_ERROR = 10001
}

//MARK: - PushTarget
public enum PushTarget : String {
    case PUSH_TARGET_AUTH = "1000"
    case PUSH_TARGET_KEY_IN = "1006"
    case PUSH_TARGET_CANCEL = "1001"
    case PUSH_TARGET_SUCCESS = "1002"
    case PUSH_TARGET_FAIL = "1003"
}

//MARK: - NotipicationId
public enum NotipicationId : String {
    case NOTI_ID_AUTH = "GUARDIAN_AHTH"
    case NOTI_ID_SUCCESS = "GUARDIAN_SUCCESS"
    case NOTI_ID_FAIL = "GUARDIAN_FAIL"
    case NOTI_ID_CANCEL = "GUARDIAN_CANCEL"
}


//MARK: - AuthStatus
public enum AuthStatus : String {
    /**
     * 인증시작 요청 by Web
     */
    case REQUEST_AUTH = "RequestAuth"
    /**
     * 채널 생성
     */
    case CREATE_CHANNEL = "CreateChannel"
    /**
     * 검증노드 선정
     */
    case SELECT_NODES = "SelectNodes"
    /**
     * 인증시작 by App
     */
    case START_AUTH = "StartAuth"
    /**
     * 노드검증 시작
     */
    case START_VERIFICATION_OF_NODES = "StartVerificationOfNodes"
    /**
     * 노드검증 완료
     */
    case COMPLETE_VERIFICATION_OF_NODES = "CompleteVerificationOfNodes"
    /**
     * 취소 요청 by App/Web
     */
    case REQUEST_CANCEL = "RequestCancel"
    /**
     * 인증취소(완료) by App/Web
     */
    case AUTH_CANCELED = "AuthCanceled"
    /**
     * 인층실패(완료)
     */
    case AUTH_FAILED = "AuthFailed"
    /**
     * 인증성공(완료)
     */
    case AUTH_COMPLETED = "AuthCompleted"
    /**
     *  인증 시간 초과
     */
    case AUTH_TIMEOUT = "AuthTimeout"
    
}

public let USER_KEY = "GUARDIAN_USER_KEY"
public let FCM_TOKEN = "GUARDIAN_FCM_TOKEN"

public let AUTH_FAIL_CODE_ERROR = -2
public let AUTH_FAIL_CODE_USER_ERROR = -4
public let AUTH_FAIL_CODE_NOT_START_PROCESS = -3
public let AUTH_FAIL_CODE_USER_CANCEL = -1

public enum PushState {
    case deviceCheck,keyIn
}

//MARK: - 인증 결과 전달을 위한 delegate
public protocol AuthCallBack: class {
    func onFailed(errorCode: Int,errorMsg: String)
    func onSuccess(channelKey: String)
    func onCancel()
}

//MARK: - unwind 를 위한 delegate
public protocol UnwindCallBack: class {
    func onBack()
}

func setUserKey(userKey : String) {
    let ud = UserDefaults.standard
    ud.set(userKey,forKey: USER_KEY)
}

func getLang() -> String {
    let prefferedLanguage = Locale.preferredLanguages[0] as String
    let arr = prefferedLanguage.components(separatedBy: "-")
    return arr.first!
}

func getUUid() -> String {
    let packageName = getPackageName()
    let deviceId =  "\(packageName)\(UIDevice.current.identifierForVendor!.uuidString)"
    let encryptDeivceId = encryptAES256(value: deviceId, seckey: packageName)
    let trimStr = encryptDeivceId.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimStr
}

func getPackageName() -> String {
    let packageName = Bundle.main.bundleIdentifier as? String ?? "com.fnsvalue.GuardianCCS"
    
    return packageName
}

func getUserToken() -> String {
    let ud = UserDefaults.standard
    return ud.string(forKey: FCM_TOKEN) ?? ""
}

func getOSVersion() -> String {
    return UIDevice.current.systemVersion
}

func getAppVersion() -> String {
    let appVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as? String
    return appVersion!
}

public protocol AuthObserver: class {
    func onAuthentication(status : String)
}

//MARK: - GuardianService Class
public class GuardianService{
    
    public static let sharedInstance = GuardianService()
    
    public var _authRequestSuccess : (RtCode, String, Int, String, String, String) -> Void
    public var _authRequestProcess : (String) -> Void
    public var _authRequestFailed : (RtCode, String) -> Void
    public var _onSubscribeAuthStatus : (String) -> Void
    
    private init() {
        func initOnSuccess(rtcode: RtCode, rtMsg: String, authType: Int, connectIp: String, userKey: String, clientKey: String) -> Void{}
        func initOnProcess(status : String) -> Void{}
        func initOnFailed(rtcode: RtCode, rtMsg: String) -> Void{}
        func initOnSubscribeAuthStatus(status : String) -> Void{}
        
        self._authRequestSuccess = initOnSuccess
        self._authRequestProcess = initOnProcess
        self._authRequestFailed = initOnFailed
        self._onSubscribeAuthStatus = initOnSubscribeAuthStatus
    }
    
    var authTimeoutTimer = Timer()
    
    var observers = [AuthObserver]()
    
    public struct Domain {
        public static var baseUrl = ""
        public static var apiDomain = ""
    }
    
    public func getBaseUrl() -> String {
        return Domain.baseUrl
    }
    
    private static var _userKey : String = ""
    public var userKey : String {
        get  {
            return GuardianService._userKey
        }
        set(value) {
            GuardianService._userKey = value
        }
    }
    
    private static var _clientKey : String = ""
    public var clientKey : String {
        get  {
            return GuardianService._clientKey
        }
        set(value) {
            GuardianService._clientKey = value
        }
    }
    
    private static var _qrId : String?
    public var qrId : String? {
        get  {
            return GuardianService._qrId
        }
        set(value) {
            GuardianService._qrId = value
        }
    }
    
    private static var _authType : Int = 0
    public var authType : Int {
        get {
            return GuardianService._authType
        }
        set(value) {
            GuardianService._authType = value
        }
    }
    
    private static var _connectIp : String = ""
    public var connectIp : String {
        get {
            return GuardianService._connectIp
        }
        set(value) {
            GuardianService._connectIp = value
        }
    }
    
    private static var _channelKey : String = ""
    public var channelKey : String {
        get {
            return GuardianService._channelKey
        }
        set(value) {
            GuardianService._channelKey = value
        }
    }
    
    private static var _blockKey : String = ""
    public var blockKey : String {
        get {
            return GuardianService._blockKey
        }
        set(value) {
            GuardianService._blockKey = value
        }
    }
    
    //    private static var _translationMap : [String: Any]? = ["1": 1]
    //
    //    private var translationMap : [String: Any]? {
    //        get {
    //            return GuardianService._translationMap
    //        }
    //        set (value) {
    //            GuardianService._translationMap = value
    //        }
    //    }
    
    public func initDomain(baseUrl :String, apiUrl : String ) {
        print("initDomain")
        Domain.baseUrl = baseUrl
        Domain.apiDomain = apiUrl
    }
    
    public func initClientKey(clientKey: String) {
        self.clientKey = clientKey
    }
    
    public func initQrId(qrId: String?) {
        self.qrId = qrId
    }
    
    public func addObserver(_ observer: AuthObserver) {
        observers.append(observer)
    }
    
    public func removeObserver(_ observer: AuthObserver) {
        observers = observers.filter({ $0 !== observer })
    }
    
    public func notifyAuthStatus(status : String) {
        self._onSubscribeAuthStatus(status)
    }
    
    public func addSubscribeCallback(subscribe: @escaping(String) -> Void) {
        self._onSubscribeAuthStatus = subscribe
    }
    
    public func onFcmMessageHandle(messageDic : Dictionary<String,String>, callback: @escaping(RtCode, String) -> Void) {
        if let strTarget = messageDic["target"] {
            let target = Int(strTarget)
            switch target {
            case RtCode.PUSH_LOGIN.rawValue:
                self.channelKey = messageDic["channel_key"] ?? ""
                self.blockKey = messageDic["block_key"] ?? ""
                callback(RtCode.AUTH_SUCCESS, "")
            case RtCode.PUSH_LOGIN_SUCCESS.rawValue:
                self._authRequestSuccess(RtCode.AUTH_SUCCESS, "", self.authType, self.connectIp, self.userKey, self.clientKey)
            case RtCode.PUSH_LOGIN_FAIL.rawValue:
                self._authRequestFailed(RtCode.AUTH_FAIL, "")
            //          case RtCode.PUSH_LOGIN_CANCEL.rawValue:
            //              callback(RtCode.AUTH_CANCEL, LocalizationMessage.sharedInstance.getLocalization(code: RtCode.AUTH_CANCEL.rawValue) ?? "")
            default:
                print("")
            }
        }
        
    }
    
    //MARK: - requestMember
    public func requestMember(onSuccess: @escaping(RtCode, String, [String:String])-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        let apiUrl = "device/check"
        var params = getCommonParam()
        params["deviceId"] = getUUid()
        
        // method is .get by default
        self.callHttpMethod(params: params, api: apiUrl) { (data: JSON) in
            let rtCode = data["rtCode"].intValue
            let rtMsg = data["rtMsg"].string ?? ""
            guard let authData = data["data"] as? JSON else {
                onFailed(RtCode.API_ERROR, rtMsg)
                return
            }
            
            var dic = [String:String]()
            
            if (rtCode == RtCode.AUTH_SUCCESS.rawValue) {
                print("AuthData from \(apiUrl) : \(authData)")
                dic["userKey"] = authData["userKey"].string ?? ""
                dic["name"] = authData["name"].string ?? ""
                dic["email"] = authData["email"].string ?? ""
                dic["authType"] = authData["authType"].string ?? ""
                dic["phoneNum"] = authData["phoneNum"].string ?? ""
                
                onSuccess(RtCode.AUTH_SUCCESS, rtMsg, dic)
            } else if (rtCode == RtCode.AUTH_MEMBER_STATUS_WITHDRAW.rawValue) {
                // print("in AUTH_MEMBER_STATUS_WITHDRAW")
                dic["userKey"] = authData["userKey"].string ?? ""
                dic["uptDt"] = authData["uptDt"].string ?? ""
                onSuccess(RtCode.AUTH_MEMBER_STATUS_WITHDRAW, rtMsg, dic)
            } else{
                onSuccess(RtCode(rawValue: rtCode)!, rtMsg, dic)
            }
        } errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR, errorMsg)
        }
    }
    
    public func requestClients(onSuccess: @escaping(RtCode, String, Array<[String:String]>)-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        let apiUrl = "clients"
        var params = getCommonParam()
        params["deviceId"] = getUUid()
        
        self.callHttpMethod(params: params, api: apiUrl) { (data: JSON) -> Void in
            let rtCode = data["rtCode"].intValue
            let rtMsg = data["rtMsg"].string ?? ""
            
            if (rtCode == RtCode.AUTH_SUCCESS.rawValue) {
                var returnValue = Array<[String:String]>()
                let size = data["data"].count
                for i in 0..<size {
                    let client = data["data"].arrayValue[i]
                    var dic = [String:String]()
                    dic["clientName"] = client["clientName"].string ?? ""
                    dic["clientKey"] = client["clientKey"].string ?? ""
                    returnValue.append(dic)
                }
                onSuccess(RtCode.AUTH_SUCCESS, rtMsg, returnValue)
            } else {
                onFailed(RtCode.API_ERROR, "\(rtCode)")
            }
        } errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR, errorMsg)
        }
    }
    
    public func requestTokenUpdate(token : String, onSuccess: @escaping(RtCode, String)-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        let apiUrl = "me/token"
        
        var params = getCommonParam()
        params["deviceId"] = getUUid()
        params["token"] = token
        params["osVersion"] = getOSVersion()
        params["appVersion"] = getAppVersion()
        
        self.callHttpMethod(params: params, api: apiUrl, method: .put) { (data: JSON) in
            let rtCode = data["rtCode"].intValue
            let rtMsg = data["rtMsg"].string ?? ""
            if(rtCode == RtCode.AUTH_SUCCESS.rawValue) {
                onSuccess(RtCode(rawValue: rtCode)!, rtMsg)
            } else {
                self.onCallbackFailed(rtCode: RtCode(rawValue: rtCode)!, onFailed: onFailed)
            }
        } errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR, errorMsg)
        }
    }
    
    //MARK: - requestAuthRequest
    /// Also known as StartAuth
    /// - Parameters:
    ///   - onSuccess: When the authentication is completed successfully
    ///   - onProcess: Report every single process such as `Start Authentication`, `Create Channel`, `Node Verification`...
    ///   - onFailed: When the authentication is failed
    public func requestAuthRequest(onSuccess: @escaping(RtCode, String, Int, String, String, String)-> Void, onProcess: @escaping(String) -> Void,  onFailed: @escaping(RtCode, String)-> Void) {
        let apiUrl = "auth/nodes"
        
        let enCodeCK = encryptAES256(value: self.channelKey, seckey: self.channelKey)
        let enCodeBK = encryptAES256(value: self.blockKey, seckey: self.channelKey)
        let enCodeDK = encryptAES256(value: getUUid(), seckey: self.channelKey)
        
        var params = getCommonParam()
        params["deviceId"] = getUUid()
        params["enCodeCK"] = enCodeCK
        params["enCodeBK"] = enCodeBK
        params["enCodeDK"] = enCodeDK
        params["userKey"] = self.userKey
        
        // WebSocket 연결.
        var socketDataMap = getCommonParam()
        socketDataMap["channelKey"] = self.channelKey
        socketDataMap["deviceId"] = getUUid()
        socketDataMap["userKey"] = self.userKey
        
        if let mQrId = self.qrId {
            if mQrId.count > 0 {
                params["qrId"] = mQrId
                socketDataMap["qrId"] = mQrId
            }
        }
        
        StompSocketService.sharedInstance.connect(dataMap: socketDataMap, connectCallback: {(isConnect: Bool) -> Void in
            if isConnect {
                print("stompwebsocket connect")
                StompSocketService.sharedInstance.subscribe(authProcessCallback: {(status : String?) -> Void in
                    print("stompwebsocket subscribe => \(status!)")
                    
                    //                    self.notifyAuthStatus(status: status!)
                    switch status! {
                    case AuthStatus.COMPLETE_VERIFICATION_OF_NODES.rawValue:
                        self._authRequestSuccess(RtCode.AUTH_SUCCESS, status!, self.authType, self.connectIp, self.userKey, self.clientKey)
                        break
                    case AuthStatus.AUTH_CANCELED.rawValue:
                        self._authRequestFailed(RtCode.AUTH_CANCEL,status!)
                        break
                    case AuthStatus.REQUEST_CANCEL.rawValue:
                        self._authRequestFailed(RtCode.AUTH_REQUEST_FAIL, status!)
                        break
                    case AuthStatus.AUTH_FAILED.rawValue:
                        self._authRequestFailed(RtCode.AUTH_FAIL, status!)
                        break
                    case AuthStatus.AUTH_TIMEOUT.rawValue:
                        self._authRequestFailed(RtCode.AUTH_CERT_TIME_OUT, status!)
                        break
                    default:
                        print("Status doesn't fit in")
                        break
                    }
                    
                    if status! != AuthStatus.AUTH_COMPLETED.rawValue ||
                        status! != AuthStatus.AUTH_FAILED.rawValue ||
                        status! != AuthStatus.AUTH_CANCELED.rawValue {
                        self._authRequestProcess(status!) //authRequest callback.
                    }
                    
                    if status! == AuthStatus.AUTH_COMPLETED.rawValue || status! == AuthStatus.AUTH_FAILED.rawValue {
                        StompSocketService.sharedInstance.disconnect()
                        self.invalidateAuthTimeoutTimer()
                    }
                })
            } else {
                print("stompwebsocket disconnect")
            }
        })
        
        self._authRequestSuccess = onSuccess
        self._authRequestProcess = onProcess
        self._authRequestFailed = onFailed
        
        self._authRequestProcess(AuthStatus.CREATE_CHANNEL.rawValue)
        
        self.callHttpMethod(params: params, api: apiUrl, method: .post) { (data: JSON) in
            let rtCode = data["rtCode"].intValue
            let rtMsg = data["rtMsg"].string ?? ""
            
            if (rtCode == RtCode.AUTH_SUCCESS.rawValue){
                guard let authData = data["data"] as? JSON else {
                    onFailed(RtCode.API_ERROR, rtMsg)
                    return
                }
                
                self._authRequestProcess(AuthStatus.SELECT_NODES.rawValue)
                
                self.authType = authData["authType"].intValue
                self.connectIp = authData["connectIp"].string ?? ""
                self.userKey = authData["userKey"].string ?? ""
                let authTimeRemaining = authData["authTimeRemaining"].doubleValue
                
                // Auth Timer start
                self.executeAuthTimeoutTimer(authTimeRemaining : authTimeRemaining)
                
            } else {
                self.onCallbackFailed(rtCode: RtCode(rawValue: rtCode)!, onFailed: onFailed)
            }
        } errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR, errorMsg)
        }
    }
    
    private func executeAuthTimeoutTimer(authTimeRemaining : Double) {
        let authTimeout = authTimeRemaining / 1000
        self.authTimeoutTimer = Timer.scheduledTimer(withTimeInterval: authTimeout, repeats: false, block: { timer in
            self.notifyAuthStatus(status : AuthStatus.AUTH_TIMEOUT.rawValue)
        })
    }
    
    private func invalidateAuthTimeoutTimer() {
        self.authTimeoutTimer.invalidate()
    }
    
    //MARK: - requestAuthResult
    public func requestAuthResult(isSecondaryCertification : Bool, onSuccess: @escaping(RtCode, String)-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        let apiUrl = "auth/complete"
        
        
        var params = Dictionary<String, Any>()
        
        let commonParam = self.getCommonParam()
        for key in commonParam.keys {
            params[key] = commonParam[key]
        }
        
        params["deviceId"] = getUUid()
        params["isSecondaryCertification"] = isSecondaryCertification
        
        if let mQrId = self.qrId {
            if mQrId.count > 0 {
                params["qrId"] = mQrId
            }
        }
        
        self.callHttpMethod(params: params, api: apiUrl, method: .post) { (data: JSON) in
            
            let rtCode = data["rtCode"].intValue
            let rtMsg = data["rtMsg"].string ?? ""
            
            if (rtCode == RtCode.AUTH_SUCCESS.rawValue){
                onSuccess(RtCode.AUTH_SUCCESS, rtMsg)
            } else {
                self.onCallbackFailed(rtCode: RtCode(rawValue: rtCode)!, onFailed: onFailed)
            }
            
        } errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR, errorMsg)
        }
    }
    
    /// To get the Auth Result Token
    /// - Parameters:
    ///   - onSuccess: Recieve rtCode and Token
    ///   - onFailed: Error rtCode and Error Message
    public func getAuthResultToken(onSuccess: @escaping(RtCode, [String:Any])-> Void, onFailed: @escaping(RtCode, String)-> Void){
        let apiUrl = "auth"
        
        var params = Dictionary<String,String>()
        params["deviceId"] = getUUid()
        params["clientKey"] = self.clientKey
        params["channelKey"] = self.channelKey
        
        self.callHttpMethod(params: params, api: apiUrl) { (data: JSON) in
            var resultData = [String:Any]()
            resultData["data"] = data["data"].string ?? ""
            onSuccess(RtCode.AUTH_SUCCESS, resultData)
        } errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR, errorMsg)
        }
    }
    
    public func requestAuthCancel(onSuccess: @escaping(RtCode, String)-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        let apiUrl = "auth"
        
        var params = getCommonParam()
        params["deviceId"] = getUUid()
        
        if let mQrId = self.qrId {
            if mQrId.count > 0 {
                params["qrId"] = mQrId
            }
        }
        
        self.callHttpMethod(params: params, api: apiUrl, method: .delete) { (data: JSON) in
            let rtCode = data["rtCode"].intValue
            let rtMsg = data["rtMsg"].string ?? ""
            
            if (rtCode == RtCode.AUTH_SUCCESS.rawValue) {
                onSuccess(RtCode.AUTH_SUCCESS, rtMsg)
            } else {
                self.onCallbackFailed(rtCode: RtCode(rawValue: rtCode)!, onFailed: onFailed)
            }
            
        } errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR, errorMsg)
        }
    }
    
    //MARK: - To register Membership - 회원가입
    public func requestMemberRegister(memberObject : Dictionary<String, Any>, onSuccess: @escaping(RtCode, String, Dictionary<String, String>)-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        
        let packageName = getPackageName()
        let deviceId =  "\(packageName)\(UIDevice.current.identifierForVendor!.uuidString)"
        KeychainService.updatePassword(service: packageName, account:"deviceId",data:deviceId)
        
        DispatchQueue.main.async {
            DeviceInfoService().getDeviceInfo{ (data:Dictionary<String, Any>) in
                let apiUrl = "users"
                
                var params = data
                
                let commonParam = self.getCommonParam()
                for key in commonParam.keys {
                    params[key] = commonParam[key]
                }
                
                for key in memberObject.keys {
                    params[key] = memberObject[key]
                }
                
                params["deviceId"] = getUUid()
                params["appPackage"] = getPackageName()
                params["os"] = "CMMDOS002"
                params["osVersion"] = getOSVersion()
                params["appVersion"] = getAppVersion()
                params["deiceManufacturer"] = "apple"
                params["deviceName"] = Device.current.description
                
                self.callHttpMethod(params: params, api: apiUrl, method: .post) { (response: JSON) in
                    let rtCode = response["rtCode"].intValue
                    let rtMsg = response["rtMsg"].string ?? ""
                    var data = ["secretKey":""]
                    
                    if let dataObject = response["data"].dictionary {
                        if let secret = dataObject["secretKey"]?.rawString() {
                            data["secretKey"] = secret
                        }
                    }
                    
                    if (rtCode == RtCode.AUTH_SUCCESS.rawValue){
                        onSuccess(RtCode.AUTH_SUCCESS, rtMsg, data)
                    } else {
                        self.onCallbackFailed(rtCode: RtCode(rawValue: rtCode)!, onFailed: onFailed)
                    }
                } errorCallBack: { (errorCode, errorMsg) in
                    onFailed(RtCode.API_ERROR, errorMsg)
                }
            }
        }
    }
    
    //MARK: - To register Device - 기기재등록
    public func requestReMemberRegister(memberObject : Dictionary<String, Any>, onSuccess: @escaping(RtCode, String, Dictionary<String, String>)-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        
        let packageName = getPackageName()
        let deviceId =  "\(packageName)\(UIDevice.current.identifierForVendor!.uuidString)"
        KeychainService.updatePassword(service: packageName, account:"deviceId",data:deviceId)
        
        DispatchQueue.main.async {
            DeviceInfoService().getDeviceInfo{ (data:Dictionary<String, Any>) in
                let userKey = memberObject["userKey"] as? String ?? ""
                let apiUrl = "users/\(userKey)/device"
                
                var params = data
                
                
                
                let commonParam = self.getCommonParam()
                for key in commonParam.keys {
                    params[key] = commonParam[key]
                }
                
                for key in memberObject.keys {
                    params[key] = memberObject[key]
                }
                
                params["deviceId"] = getUUid()
                params["appPackage"] = getPackageName()
                params["os"] = "CMMDOS002"
                params["osVersion"] = getOSVersion()
                params["appVersion"] = getAppVersion()
                params["deiceManufacturer"] = "apple"
                params["deviceName"] = Device.current.description
                
                self.callHttpMethod(params: params, api: apiUrl, method: .put) { (response: JSON) in
                    let rtCode = response["rtCode"].intValue
                    let rtMsg = response["rtMsg"].string ?? ""
                    var data = ["secretKey":""]
                    
                    if let dataObject = response["data"].dictionary {
                        if let secret = dataObject["secretKey"]?.rawString() {
                            data["secretKey"] = secret
                        }
                    }
                    
                    if (rtCode == RtCode.AUTH_SUCCESS.rawValue){
                        onSuccess(RtCode.AUTH_SUCCESS, rtMsg, data)
                    } else {
                        self.onCallbackFailed(rtCode: RtCode(rawValue: rtCode)!, onFailed: onFailed)
                    }
                } errorCallBack: { (errorCode, errorMsg) in
                    onFailed(RtCode.API_ERROR, errorMsg)
                }
            }
        }
    }
    
    //MARK: - To recover withdrawn member - 탈퇴 멤버 복구
    public func recoveryMember(memberObject : Dictionary<String, Any>, onSuccess: @escaping(RtCode, String)-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        
        let packageName = getPackageName()
        let deviceId =  "\(packageName)\(UIDevice.current.identifierForVendor!.uuidString)"
        KeychainService.updatePassword(service: packageName, account:"deviceId",data:deviceId)
        
        DispatchQueue.main.async {
            DeviceInfoService().getDeviceInfo{ (data:Dictionary<String, Any>) in
                let userKey = memberObject["userKey"] as? String ?? ""
                let apiUrl = "users/\(userKey)/cancel"
                
                var params = data
                
                let commonParam = self.getCommonParam()
                for key in commonParam.keys {
                    params[key] = commonParam[key]
                }
                
                for key in memberObject.keys {
                    params[key] = memberObject[key]
                }
                
                params["deviceId"] = getUUid()
                params["appPackage"] = getPackageName()
                params["os"] = "CMMDOS002"
                params["osVersion"] = getOSVersion()
                params["appVersion"] = getAppVersion()
                params["deiceManufacturer"] = "apple"
                params["deviceName"] = Device.current.description
                
                self.callHttpMethod(params: params, api: apiUrl, method: .post) { (data: JSON) in
                    let rtCode = data["rtCode"].intValue
                    let rtMsg = data["rtMsg"].string ?? ""
                    
                    if (rtCode == RtCode.AUTH_SUCCESS.rawValue){
                        onSuccess(RtCode.AUTH_SUCCESS, rtMsg)
                    } else {
                        self.onCallbackFailed(rtCode: RtCode(rawValue: rtCode)!, onFailed: onFailed)
                    }
                } errorCallBack: { (errorCode, errorMsg) in
                    onFailed(RtCode.API_ERROR, errorMsg)
                }
            }
        }
    }
    
    public func requestAuthSms(phoneNum : String, onSuccess: @escaping(RtCode, String, Int)-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        let apiUrl = "sms"
        var params = getCommonParam()
        params["phoneNum"] = phoneNum
        
        self.callHttpMethod(params: params, api: apiUrl, method: .post) { (data: JSON) in
            let rtCode = data["rtCode"].intValue
            let rtMsg = data["rtMsg"].string ?? ""
            
            guard let authData = data["data"] as? JSON else {
                onFailed(RtCode.API_ERROR, rtMsg)
                return
            }
            
            let seq = authData["seq"].intValue
            
            if (rtCode == RtCode.AUTH_SUCCESS.rawValue){
                onSuccess(RtCode.AUTH_SUCCESS, rtMsg, seq)
            } else {
                self.onCallbackFailed(rtCode: RtCode(rawValue: rtCode)!, onFailed: onFailed)
            }
        } errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR, errorMsg)
        }
    }
    
    public func verifySms(phoneNum : String, authNum: String, seq: String,
                          onSuccess: @escaping(RtCode, String, Bool)-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        let apiUrl = "sms/verify"
        var params = getCommonParam()
        params["phoneNum"] = phoneNum
        params["authNum"] = authNum
        params["seq"] = seq
        
        self.callHttpMethod(params: params, api: apiUrl, method: .post) { (data: JSON) in
            let rtCode = data["rtCode"].intValue
            let rtMsg = data["rtMsg"].string ?? ""
            
            guard let verifyData = data["data"] as? JSON else {
                onFailed(RtCode.API_ERROR, rtMsg)
                return
            }
            
            let result = verifyData["result"].boolValue
            
            if (rtCode == RtCode.AUTH_SUCCESS.rawValue){
                onSuccess(RtCode.AUTH_SUCCESS, rtMsg, result)
            } else {
                self.onCallbackFailed(rtCode: RtCode(rawValue: rtCode)!, onFailed: onFailed)
            }
        } errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR, errorMsg)
        }
    }
    
    public func requestUserCheck(userKey: String, onSuccess: @escaping(RtCode, String)-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        let apiUrl = "me/\(self.clientKey)/member/\(userKey)/check"
        let params = getCommonParam()
        
        self.callHttpMethod(params: params, api: apiUrl) { (data: JSON) in
            let rtCode = data["rtCode"].intValue
            let rtMsg = data["rtMsg"].string ?? ""
            
            if (rtCode == RtCode.AUTH_SUCCESS.rawValue) {
                onSuccess(RtCode.AUTH_SUCCESS, rtMsg)
            } else {
                onFailed(RtCode.API_ERROR, "\(rtCode)")
            }
        } errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR, errorMsg)
        }
    }
    
    public func requestVerifyIcon(icons: String, onSuccess: @escaping(RtCode, String)-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        let apiUrl = "auth/verify/icon"
        
        var params = getCommonParam()
        params["deviceId"] = getUUid()
        params["iconSelect"] = icons
        
        self.callHttpMethod(params: params, api: apiUrl, method: .post) { (data: JSON) in
            let rtCode = data["rtCode"].intValue
            let rtMsg = data["rtMsg"].string ?? ""
            
            if (rtCode == RtCode.AUTH_SUCCESS.rawValue){
                onSuccess(RtCode.AUTH_SUCCESS, rtMsg)
            } else {
                self.onCallbackFailed(rtCode: RtCode(rawValue: rtCode)!, onFailed: onFailed)
            }
        } errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR, errorMsg)
        }
    }
    
    public func requestFingerFail(onSuccess: @escaping(RtCode, String)-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        let apiUrl = "auth/verify/finger/fail"
        
        var params = getCommonParam()
        params["deviceId"] = getUUid()
        
        self.callHttpMethod(params: params, api: apiUrl, method: .post) { (data: JSON) in
            let rtCode = data["rtCode"].intValue
            let rtMsg = data["rtMsg"].string ?? ""
            
            if (rtCode == RtCode.AUTH_SUCCESS.rawValue){
                onSuccess(RtCode.AUTH_SUCCESS, rtMsg)
            } else {
                self.onCallbackFailed(rtCode: RtCode(rawValue: rtCode)!, onFailed: onFailed)
            }
        } errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR, errorMsg)
        }
    }
    
    public func isAuthExist(userKey: String, onSuccess: @escaping(RtCode, String, [String:Any])-> Void, onFailed: @escaping(RtCode, String)-> Void) {
        let apiUrl = "auth/exist"
        
        var params = getCommonParam()
        params["deviceId"] = getUUid()
        params["userKey"] = userKey
        
        self.callHttpMethod(params: params, api: apiUrl) { (data: JSON) in
            let rtCode = data["rtCode"].intValue
            let rtMsg = data["rtMsg"].string ?? ""
            
            if (rtCode == RtCode.AUTH_SUCCESS.rawValue){
                guard let authData = data["data"] as? JSON else {
                    onFailed(RtCode.API_ERROR, rtMsg)
                    return
                }
                
                var resultData = [String:Any]()
                resultData["isExist"] = authData["isExist"].boolValue ?? false
                resultData["clientKey"] = authData["clientKey"].string ?? ""
                resultData["siteURL"] = authData["siteURL"].string ?? ""
                resultData["timeout"] = authData["timeout"].string ?? ""
                
                onSuccess(RtCode.AUTH_SUCCESS, rtMsg, resultData)
                
            } else {
                self.onCallbackFailed(rtCode: RtCode(rawValue: rtCode)!, onFailed: onFailed)
            }
        } errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR, errorMsg)
        }
    }
    
    //MARK: - isDuplcatedEmailOrPhoneNumber
    /// To check if the user has input an existing email or phone number
    /// - Parameters:
    ///   - verifyType: is a `String`, which has 2 cases. `CMMDUP001` for email and `CMMDUP002` for sms/phone
    ///   - verifyData: is a `String`, which could be your `email` or your `phone number` depending on the `verifyType`
    ///   - onSuccess: will escape when unique
    ///   - onFailed: will escape when duplicated
    public func isDuplicatedEmailOrPhoneNumber(verifyType: String, verifyData: String, onSuccess: @escaping(JSON)->Void, onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/users/common/duplicate-check"
        var params = Dictionary<String, String>()
        params["verifyType"] = verifyType
        params["verifyData"] = verifyData
        
        self.callHttpMethod(params: params, api: apiUrl) { (data: JSON) in
            onSuccess(data)
        }
        errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR.rawValue, errorMsg)
            }
        }

    //MARK: - isDuplicateUserKey
    /// To check if the user has input an existing `userKey`
    /// - Parameters:
    ///   - userKey: FNSV
    ///   - onSuccess: will escape when unique
    ///   - onFailed: will escape when duplicated
    public func isDuplicatedUserKey(userKey: String, onSuccess: @escaping(JSON)->Void, onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/idcheck"
        var params = Dictionary<String, String>()
        params["userKey"] = userKey
        
        self.callHttpMethod(params: params, api: apiUrl) { (data: JSON) in
            onSuccess(data)
        }
        errorCallBack: { (errorCode, errorMsg) in
            onFailed(RtCode.API_ERROR.rawValue, errorMsg)
            }
        }
    
    
    //MARK: - callHttpMethod
    /// Creates a `DataRequest` using the default `SessionManager` to retrieve the contents of the specified `url`,
    /// `method`, `parameters`, `encoding` and `headers`.
    ///
    /// - parameter api:        The api, which will later be concatenated with `Domain.apiDomain` to create `url`.
    /// - parameter method:     The HTTP method. `.get` by default.
    /// - parameter params: The parameters cannot be `nil`.
    /// - Parameter successCallBack: A callback function to retrieve `JSONResponse` when successfully fetching data.
    /// - parameter errorCallBack: A callback function to retrieve `statusCode` in `Int` and `statusMessage` in `String` in case of failure
    ///
    public func callHttpMethod(params: Dictionary<String,Any>,
                               api: String,
                               method: HTTPMethod = .get,
                               successCallBack : @escaping(JSON) -> Void,
                               errorCallBack: @escaping(Int, String) -> Void){
        
        let url = Domain.apiDomain + api
        let encodingMethod: ParameterEncoding = (method == .get) ? URLEncoding.default : JSONEncoding.default
        
        print("callHttpGet url => \(url)")
        print("method => \(method)")
        print("encodingMethod => \(encodingMethod)")
        
        Alamofire.request(url, method: method, parameters: params, encoding: encodingMethod).responseJSON { response in
            guard response.result.isSuccess else {
                var statusCode : Int! = response.response?.statusCode ?? RtCode.API_ERROR.rawValue
                var statusMessage : String
                
                if let error = response.result.error as? AFError {
                    statusCode = error._code // statusCode Private
                    
                    switch error {
                    case .invalidURL(let url):
                        statusMessage = "Invalid URL, url: \(url)"
                    case .parameterEncodingFailed(let reason):
                        statusMessage = "Parameter encoding failed, reason: \(reason)"
                    case .multipartEncodingFailed(let reason):
                        statusMessage = "Multipart encoding failed, reason: \(reason)"
                    case .responseValidationFailed(let reason):
                        statusMessage = "Response validation failed, reason: \(reason)"
                        //                        statusMessage = "Failure Reason"
                        switch reason {
                        case .dataFileNil, .dataFileReadFailed:
                            statusMessage = "Downloaded file could not be read"
                        case .missingContentType(let acceptableContentTypes):
                            statusMessage = "Content Type Missing: \(acceptableContentTypes)"
                        case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                            statusMessage = "Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)"
                        case .unacceptableStatusCode(let code):
                            statusMessage = "Response status code was unacceptable: \(code)"
                            statusCode = code
                        }
                    case .responseSerializationFailed(let reason):
                        statusMessage = "Response serialization failed: \(error.localizedDescription), reason: \(reason)"
                        statusMessage = "Failure Reason"
                    // statusCode = 3840 ???? maybe..
                    }
                    statusMessage = "Underlying error"
                } else if let error = response.result.error as? URLError {
                    statusMessage = "URLError occurred, error: \(error)"
                    
                } else {
                    statusMessage = "Unknown error"
                }
                
                errorCallBack(statusCode, statusMessage)
                return
            }
            if let data = response.result.value {
                let json = JSON(data)
                if json["rtCode"] == 0 {
                    successCallBack(json)
                } else {
                    errorCallBack(json["rtCode"].rawValue as! Int, "")
                }
            }
        }
        
    }
    
    //MARK: - callHttpUrl
    /// Creates a `DataRequest` using the default `SessionManager` to retrieve the contents of the specified `url`,
    /// `method`, `parameters`, `encoding` and `headers`.
    ///
    /// - parameter url:        The URL.
    /// - parameter method:     The HTTP method. `.get` by default.
    /// - parameter params: The parameters. `nil` by default.
    /// - parameter headers: The headers. `nil` by default
    /// - Parameter successCallBack: A callback function to retrieve JSON response when successfully fetching data.
    /// - parameter errorCallBack: A callback function to retrieve `statusCode` in `Int` and `statusMessage` in `String` in case of failure
    ///
    public func callHttpUrl(params: Dictionary<String,Any>?,
                            method: HTTPMethod = .get,
                            url: String,
                            headers: HTTPHeaders? = nil,
                            successCallBack : @escaping(JSON) -> Void,
                            errorCallBack: @escaping(Int, String) -> Void){
        
        let encodingMethod: ParameterEncoding = (method == .get) ? URLEncoding.default : JSONEncoding.default
        
        print("callHttpGet url => \(url)")
        print("method => \(method)")
        print("encodingMethod => \(encodingMethod)")
        print("headers => \(String(describing: headers))")
        
        Alamofire.request(url, method: method, parameters: params, encoding: encodingMethod, headers: headers).responseJSON { response in
            guard response.result.isSuccess else {
                var statusCode : Int! = response.response?.statusCode ?? RtCode.API_ERROR.rawValue
                var statusMessage : String
                
                if let error = response.result.error as? AFError {
                    statusCode = error._code // statusCode Private
                    
                    switch error {
                    case .invalidURL(let url):
                        statusMessage = "Invalid URL, url: \(url)"
                    case .parameterEncodingFailed(let reason):
                        statusMessage = "Parameter encoding failed, reason: \(reason)"
                    case .multipartEncodingFailed(let reason):
                        statusMessage = "Multipart encoding failed, reason: \(reason)"
                    case .responseValidationFailed(let reason):
                        statusMessage = "Response validation failed, reason: \(reason)"
                        //                        statusMessage = "Failure Reason"
                        switch reason {
                        case .dataFileNil, .dataFileReadFailed:
                            statusMessage = "Downloaded file could not be read"
                        case .missingContentType(let acceptableContentTypes):
                            statusMessage = "Content Type Missing: \(acceptableContentTypes)"
                        case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                            statusMessage = "Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)"
                        case .unacceptableStatusCode(let code):
                            statusMessage = "Response status code was unacceptable: \(code)"
                            statusCode = code
                        }
                    case .responseSerializationFailed(let reason):
                        statusMessage = "Response serialization failed: \(error.localizedDescription), reason: \(reason)"
                        statusMessage = "Failure Reason"
                    // statusCode = 3840 ???? maybe..
                    }
                    statusMessage = "Underlying error"
                } else if let error = response.result.error as? URLError {
                    statusMessage = "URLError occurred, error: \(error)"
                    
                } else {
                    statusMessage = "Unknown error"
                }
                
                errorCallBack(statusCode, statusMessage)
                return
            }
            if let data = response.result.value {
                let json = JSON(data)
                successCallBack(json)
            }
        }
        
    }
    
    //MARK: - callHttpGet
    private func callHttpGet(params: Dictionary<String,Any>,
                             api: String,
                             successCallBack : @escaping(JSON) -> Void,
                             errorCallBack: @escaping(Int, String) -> Void) {
        
        let url = Domain.apiDomain + api
        print("callHttpGet url => \(url)")
        
        Alamofire.request(url,method: .get ,parameters: params)
            .responseJSON{ response in
                guard response.result.isSuccess else {
                    var statusCode : Int! = response.response?.statusCode ?? RtCode.API_ERROR.rawValue
                    var statusMessage : String
                    if let error = response.result.error as? AFError {
                        statusCode = error._code // statusCode private
                        switch error {
                        case .invalidURL(let url):
                            statusMessage = "Invalid URL"
                        case .parameterEncodingFailed(let reason):
                            statusMessage = "Parameter encoding failed"
                        case .multipartEncodingFailed(let reason):
                            statusMessage = "Multipart encoding failed"
                        case .responseValidationFailed(let reason):
                            statusMessage = "Response validation failed"
                            statusMessage = "Failure Reason"
                            switch reason {
                            case .dataFileNil, .dataFileReadFailed:
                                statusMessage = "Downloaded file could not be read"
                            case .missingContentType(let acceptableContentTypes):
                                statusMessage = "Content Type Missing: \(acceptableContentTypes)"
                            case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                                statusMessage = "Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)"
                            case .unacceptableStatusCode(let code):
                                statusMessage = "Response status code was unacceptable: \(code)"
                                statusCode = code
                            }
                        case .responseSerializationFailed(let reason):
                            statusMessage = "Response serialization failed: \(error.localizedDescription)"
                            statusMessage = "Failure Reason"
                        // statusCode = 3840 ???? maybe..
                        }
                        //                        statusMessage = "Underlying error: \(error.underlyingError)"
                        statusMessage = "Underlying error"
                    } else if let error = response.result.error as? URLError {
                        //                        statusMessage = "URLError occurred: \(error)"
                        statusMessage = url
                    } else {
                        //                        statusMessage = "Unknown error: \(response.result.error)"
                        statusMessage = "Unknown error"
                    }
                    
                    errorCallBack(statusCode, statusMessage)
                    return
                }
                
                if let data = response.result.value {
                    let json = JSON(data)
                    successCallBack(json)
                }
            }
    }
    
    //MARK: - callHttpPost
    private func callHttpPost(params: Dictionary<String,Any>,
                              api: String,
                              successCallBack : @escaping(JSON) -> Void,
                              errorCallBack: @escaping(Int, String) -> Void) {
        
        let url = Domain.apiDomain + api
        print("callHttpPost url => \(url)")
        
        Alamofire.request(url,method: .post ,parameters: params, encoding: JSONEncoding.default)
            .responseJSON{ response in
                guard response.result.isSuccess else {
                    var statusCode : Int! = response.response?.statusCode ?? RtCode.API_ERROR.rawValue
                    var statusMessage : String
                    if let error = response.result.error as? AFError {
                        statusCode = error._code // statusCode private
                        switch error {
                        case .invalidURL(let url):
                            statusMessage = "Invalid URL"
                        case .parameterEncodingFailed(let reason):
                            statusMessage = "Parameter encoding failed"
                        case .multipartEncodingFailed(let reason):
                            statusMessage = "Multipart encoding failed"
                        case .responseValidationFailed(let reason):
                            statusMessage = "Response validation failed"
                            statusMessage = "Failure Reason"
                            switch reason {
                            case .dataFileNil, .dataFileReadFailed:
                                statusMessage = "Downloaded file could not be read"
                            case .missingContentType(let acceptableContentTypes):
                                statusMessage = "Content Type Missing: \(acceptableContentTypes)"
                            case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                                statusMessage = "Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)"
                            case .unacceptableStatusCode(let code):
                                statusMessage = "Response status code was unacceptable: \(code)"
                                statusCode = code
                            }
                        case .responseSerializationFailed(let reason):
                            statusMessage = "Response serialization failed: \(error.localizedDescription)"
                            statusMessage = "Failure Reason"
                        // statusCode = 3840 ???? maybe..
                        }
                        //                        statusMessage = "Underlying error: \(error.underlyingError)"
                        statusMessage = "Underlying error"
                    } else if let error = response.result.error as? URLError {
                        //                        statusMessage = "URLError occurred: \(error)"
                        statusMessage = "URLError occurred"
                    } else {
                        //                        statusMessage = "Unknown error: \(response.result.error)"
                        statusMessage = "Unknown error"
                    }
                    
                    errorCallBack(statusCode, statusMessage)
                    return
                }
                
                if let data = response.result.value {
                    let json = JSON(data)
                    successCallBack(json)
                }
            }
        
    }
    
    //MARK: - callHttpPut
    private func callHttpPut(params: Dictionary<String,Any>,
                             api: String,
                             successCallBack : @escaping(JSON) -> Void,
                             errorCallBack: @escaping(Int, String) -> Void) {
        
        let url = Domain.apiDomain + api
        print("callHttpPut url => \(url)")
        
        Alamofire.request(url,method: .put ,parameters: params, encoding: JSONEncoding.default)
            .responseJSON{ response in
                guard response.result.isSuccess else {
                    var statusCode : Int! = response.response?.statusCode ?? RtCode.API_ERROR.rawValue
                    var statusMessage : String
                    if let error = response.result.error as? AFError {
                        statusCode = error._code // statusCode private
                        switch error {
                        case .invalidURL(let url):
                            statusMessage = "Invalid URL"
                        case .parameterEncodingFailed(let reason):
                            statusMessage = "Parameter encoding failed"
                        case .multipartEncodingFailed(let reason):
                            statusMessage = "Multipart encoding failed"
                        case .responseValidationFailed(let reason):
                            statusMessage = "Response validation failed"
                            statusMessage = "Failure Reason"
                            switch reason {
                            case .dataFileNil, .dataFileReadFailed:
                                statusMessage = "Downloaded file could not be read"
                            case .missingContentType(let acceptableContentTypes):
                                statusMessage = "Content Type Missing: \(acceptableContentTypes)"
                            case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                                statusMessage = "Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)"
                            case .unacceptableStatusCode(let code):
                                statusMessage = "Response status code was unacceptable: \(code)"
                                statusCode = code
                            }
                        case .responseSerializationFailed(let reason):
                            statusMessage = "Response serialization failed: \(error.localizedDescription)"
                            statusMessage = "Failure Reason"
                        // statusCode = 3840 ???? maybe..
                        }
                        //                        statusMessage = "Underlying error: \(error.underlyingError)"
                        statusMessage = "Underlying error"
                    } else if let error = response.result.error as? URLError {
                        //                        statusMessage = "URLError occurred: \(error)"
                        statusMessage = "URLError occurred"
                    } else {
                        //                        statusMessage = "Unknown error: \(response.result.error)"
                        statusMessage = "Unknown error"
                    }
                    
                    errorCallBack(statusCode, statusMessage)
                    return
                }
                
                if let data = response.result.value {
                    let json = JSON(data)
                    if json["rtCode"] == 0 {
                        successCallBack(json)
                    } else {
                        errorCallBack(json["rtCode"].rawValue as! Int, "")
                    }
                }
            }
    }
    
    //MARK: - callHttpDelete
    private func callHttpDelete(params: Dictionary<String,String>,
                                api: String,
                                successCallBack : @escaping(JSON) -> Void,
                                errorCallBack: @escaping(Int, String) -> Void) {
        
        let url = Domain.apiDomain + api
        print("callHttpDelete url => \(url)")
        
        Alamofire.request(url,method: .delete ,parameters: params, encoding: JSONEncoding.default)
            .responseJSON{ response in
                guard response.result.isSuccess else {
                    var statusCode : Int! = response.response?.statusCode ?? RtCode.API_ERROR.rawValue
                    var statusMessage : String
                    if let error = response.result.error as? AFError {
                        statusCode = error._code // statusCode private
                        switch error {
                        case .invalidURL(let url):
                            statusMessage = "Invalid URL"
                        case .parameterEncodingFailed(let reason):
                            statusMessage = "Parameter encoding failed"
                        case .multipartEncodingFailed(let reason):
                            statusMessage = "Multipart encoding failed"
                        case .responseValidationFailed(let reason):
                            statusMessage = "Response validation failed"
                            statusMessage = "Failure Reason"
                            switch reason {
                            case .dataFileNil, .dataFileReadFailed:
                                statusMessage = "Downloaded file could not be read"
                            case .missingContentType(let acceptableContentTypes):
                                statusMessage = "Content Type Missing: \(acceptableContentTypes)"
                            case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
                                statusMessage = "Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)"
                            case .unacceptableStatusCode(let code):
                                statusMessage = "Response status code was unacceptable: \(code)"
                                statusCode = code
                            }
                        case .responseSerializationFailed(let reason):
                            statusMessage = "Response serialization failed: \(error.localizedDescription)"
                            statusMessage = "Failure Reason"
                        // statusCode = 3840 ???? maybe..
                        }
                        //                        statusMessage = "Underlying error: \(error.underlyingError)"
                        statusMessage = "Underlying error"
                    } else if let error = response.result.error as? URLError {
                        //                        statusMessage = "URLError occurred: \(error)"
                        statusMessage = "URLError occurred"
                    } else {
                        //                        statusMessage = "Unknown error: \(response.result.error)"
                        statusMessage = "Unknown error"
                    }
                    
                    errorCallBack(statusCode, statusMessage)
                    return
                }
                
                if let data = response.result.value {
                    let json = JSON(data)
                    successCallBack(json)
                }
            }
    }
    
    private func onCallbackFailed(rtCode : RtCode, onFailed: @escaping(RtCode, String) -> Void) {
        let msg : String = LocalizationMessage.sharedInstance.getLocalization(code: rtCode.rawValue) ?? ""
        onFailed(rtCode, msg)
    }
    
    private func getCommonParam() -> Dictionary<String,String> {
        var params = Dictionary<String,String>()
        params["lang"] = getLang()
        if !self.clientKey.isEmpty {
            params["clientKey"] = self.clientKey
        } else {
            params["appPackage"] = getPackageName()
            params["os"] = "IOS"
        }
        return params
    }
    
    class DeviceInfoService {
        let authCode: String = "authCode"
        //var bthOnOff = "OFF"
        let audioMode: String = "audioMode"
        let phoneNum: String = "phoneNum"
        let altimeter = CMAltimeter()
        let motionManager = CMMotionManager()
        
        var magnetic = "magnetic"
        var orientation  = "orientation"
        var gyroscope  = "gyroscope"
        var acceleration  = "acceleration"
        var light  = "altimeter"
        var checkCount = 0;
        
        
        var mGetDeviceInfoCallback :(Dictionary<String,String>) -> Void = {_ in }
        
        public init(){
            
        }
        
        public func getDeviceInfo(getDeviceInfoCallback:@escaping(Dictionary<String,Any>) -> Void){
            if motionManager.isDeviceMotionAvailable {
                motionManager.deviceMotionUpdateInterval = 0.1
                motionManager.startDeviceMotionUpdates(to: OperationQueue.current!){ (motion,error) in
                    self.outputMotion(data: motion)
                }
            } else {
                checkCount += 1
            }
            
            //가속도 센서
            if motionManager.isAccelerometerAvailable {
                motionManager.accelerometerUpdateInterval = 0.1
                motionManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: {accelerometerData, error in self.outputAccelerationData(data: (accelerometerData?.acceleration)!)
                })
            }  else {
                checkCount += 1
            }
            //자이로 센서
            if motionManager.isGyroAvailable {
                motionManager.gyroUpdateInterval = 0.1
                motionManager.startGyroUpdates(to: OperationQueue.current!) { (data, error) in
                    self.outputGyroData(data: (data?.rotationRate)!)
                }
            }  else {
                checkCount += 1
            }
            
            //지자기 센서
            if motionManager.isMagnetometerAvailable {
                motionManager.magnetometerUpdateInterval = 0.1
                motionManager.startMagnetometerUpdates(to : OperationQueue.current!) { (data, error) in
                    self.outputMagneticData(data: (data?.magneticField)!)
                }
            }  else {
                checkCount += 1
            }
            
            //기압
            if CMAltimeter.isRelativeAltitudeAvailable() {
                altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { (data, error) in
                    let a = data?.relativeAltitude.stringValue
                    let b = data?.pressure.stringValue
                    self.light = "\(a!)|\(b!)"
                    self.stopAltimeter();
                }
            }  else {
                checkCount += 1
            }
            mGetDeviceInfoCallback = getDeviceInfoCallback
        }
        
        func callCheck(){
            if (checkCount == 5) {
                NSLog("data set!")
                NSLog("data \(magnetic)")
                NSLog("data \(gyroscope)")
                NSLog("data \(acceleration)")
                NSLog("data \(orientation)")
                NSLog("data \(light)")
                
                self.setCallback()
                
            } else {
                NSLog("data not set!")
            }
        }
        
        func stopAltimeter(){
            checkCount += 1
            callCheck()
            altimeter.stopRelativeAltitudeUpdates()
        }
        
        func outputMotion(data: CMDeviceMotion?){
            let radians = atan2((data?.gravity.x)!, (data?.gravity.y)!) - .pi
            let degrees = radians * 180.0  / .pi
            
            orientation = String(format: "%.2f", degrees)
            checkCount += 1
            callCheck()
            motionManager.stopDeviceMotionUpdates()
        }
        
        func outputMagneticData(data : CMMagneticField){
            
            magnetic = "\(String(format: "%.2f", data.x))|\(String(format: "%.2f", data.y))|\(String(format: "%.2f", data.z))"
            checkCount += 1
            callCheck()
            motionManager.stopMagnetometerUpdates()
        }
        
        func outputGyroData(data: CMRotationRate){
            
            gyroscope = "\(String(format: "%.2f", data.x))|\(String(format: "%.2f", data.y))|\(String(format: "%.2f", data.z))"
            checkCount += 1
            callCheck()
            motionManager.stopGyroUpdates()
        }
        
        func outputAccelerationData(data: CMAcceleration){
            
            acceleration = "\(String(format: "%.2f", data.x))|\(String(format: "%.2f", data.y))|\(String(format: "%.2f", data.z))"
            checkCount += 1
            callCheck()
            motionManager.stopAccelerometerUpdates();
        }
        
        /// To check if the following string is `nil`
        /// - Parameter optional: an optional `String?`
        /// - Returns: Returns non-optional `String` if not nil. Otherwise, returns a `String` =`"nil"`
        private func nilCheck(optional: String?) -> String {
            if let value = optional {
                return value
            } else {
                return "nil"
            }
        }
        
        func setCallback(){
            let securityKey = "FNSVALUEfnsvalueFNSVALUEfnsvalue"
            
            var _proximity : String = "proximity \(Date().currentTimeMillis())"
            
            var _light : String = "\(nilCheck(optional: light)) \(Date().currentTimeMillis())"
            var _magnetic : String = "\(nilCheck(optional: magnetic)) \(Date().currentTimeMillis())"
            var _orientation : String = "\(nilCheck(optional: orientation)) \(Date().currentTimeMillis())"
            var _audioInfo : String = "audioInfo \(Date().currentTimeMillis())"
            var _audioMode : String = "\(nilCheck(optional: GuardianService().getAudioMode())) \(Date().currentTimeMillis())"
            
            var _macAddr : String = "macAddr \(Date().currentTimeMillis())"
            var _bthAddr : String = "bthAddr \(Date().currentTimeMillis())"
            var _wifiInfo : String = "wifiInfo \(Date().currentTimeMillis())"
            
            var _accelerometer : String = "\(nilCheck(optional: acceleration)) \(Date().currentTimeMillis())"
            var _gyroscope : String = "\(nilCheck(optional: gyroscope)) \(Date().currentTimeMillis())"
            
            var _gpsLat : String = "gpsLat \(Date().currentTimeMillis())"
            var _gpsLng : String = "gpsLng \(Date().currentTimeMillis())"
            
            
            _proximity = nilCheck(optional: encryptAES256(value:_proximity,seckey: securityKey))
            _light = nilCheck(optional: encryptAES256(value:_light,seckey: securityKey))
            _magnetic = nilCheck(optional: encryptAES256(value:_magnetic,seckey: securityKey))
            _orientation = nilCheck(optional: encryptAES256(value:_orientation,seckey: securityKey))
            _audioInfo = nilCheck(optional: encryptAES256(value:_audioInfo,seckey: securityKey))
            _audioMode = nilCheck(optional: encryptAES256(value:_audioMode,seckey: securityKey))
            _macAddr = nilCheck(optional: encryptAES256(value:_macAddr,seckey: securityKey))
            _bthAddr = nilCheck(optional: encryptAES256(value:_bthAddr,seckey: securityKey))
            _wifiInfo = nilCheck(optional: encryptAES256(value:_wifiInfo,seckey: securityKey))
            _accelerometer = nilCheck(optional: encryptAES256(value:_accelerometer,seckey: securityKey))
            _gyroscope = nilCheck(optional: encryptAES256(value:_gyroscope,seckey: securityKey))
            _gpsLat = nilCheck(optional: encryptAES256(value:_gpsLat,seckey: securityKey))
            _gpsLng = nilCheck(optional: encryptAES256(value:_gpsLng,seckey: securityKey))
            
            
            let params = [
                "phoneNum":nilCheck(optional: phoneNum),
                "authCode":nilCheck(optional: authCode),
                "lang":nilCheck(optional: getLang()),
                "proximity":_proximity,
                "light":_light,
                "magnetic":_magnetic,
                "orientation":_orientation,
                "audioInfo":_audioInfo,
                "audioMode":_audioMode,
                "macAddr":_macAddr,
                "bthAddr":_bthAddr,
                "wifiInfo":_wifiInfo,
                "accelerometer":_accelerometer,
                "gyroscope":_gyroscope,
                "gpsLat": _gpsLat,
                "gpsLng": _gpsLng]
            
            print("=== params === : \(params)")
            
            mGetDeviceInfoCallback(params)
        }
    }
    
    private func getAudioMode() -> String{
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(true)
            if (session.outputVolume <= 0 ){
                return "OFF"
            }
            else{
                return "ON"
            }
            
        } catch {
            return "Error audio"
        }
    }
    
}

public func encryptAES256(value: String ,seckey: String) -> String {
    do {
        var seckeyCustom : String
        if seckey.count >= 31 {
            seckeyCustom = seckey
        } else {
            seckeyCustom = seckey + "FNSVALUEfnsvalueFNSVALUEfnsvalue"
        }
        
        let idx1 = seckeyCustom.index(seckeyCustom.startIndex, offsetBy: 31)
        let idx2 = seckeyCustom.index(seckeyCustom.startIndex, offsetBy: 15)
        
        let skey = String(seckeyCustom[...idx1])
        let siv = String(seckeyCustom[...idx2])
        
        let key : [UInt8] = Array(skey.utf8)
        let iv : [UInt8] = Array(siv.utf8)
        let aes = try AES(key: key, blockMode: CBC(iv:iv), padding: .pkcs5)
        let enc = try aes.encrypt(Array(value.utf8))
        
        return enc.toBase64() ?? "base64 error"
    } catch {
        return "error"
    }
}

extension Date {
    func currentTimeMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}

