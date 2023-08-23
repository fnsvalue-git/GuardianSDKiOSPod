//
//  GuardianAPI.swift
//  StoryboardTest
//
//  Created by elite on 2021/10/07.
//

import Foundation
import Alamofire
import SwiftyJSON

public struct ClientIdentity {
    let clientName : String
    let clientKey : String
}

public class GuardianAPI {
//    public let server = K.server
//    public let suffix = K.suffix
//    public let baseUrl = K.server + K.suffix
    
    static public let sharedInstance = GuardianAPI()
    
    private(set) var baseUrl: String = ""
    public func setBaseUrl(_ url: String) {
        baseUrl = url
    }
    
//    static var seq : Int?
        
    private static var userKey : String?
    
    public func setUserKey(_ userKey: String){
        GuardianAPI.userKey = userKey
    }
    
    public func clearUserKey(){
        GuardianAPI.userKey = nil
        GuardianAPI._token = nil
    }
    
    public var getUserKey: String? {
        return  GuardianAPI.userKey
    }
    
    private static var _token : String?
    public var token: String? {
        get {
            return GuardianAPI._token
        }
        set(value) {
            GuardianAPI._token = value
        }
    }
    
    public func hasToken() -> Bool {
        return GuardianAPI._token != nil
    }
    
    private static var _auth : Dictionary<String, Any>?
    public var auth: Dictionary<String, Any>? {
        get {
            return GuardianAPI._auth
        }
        set(value) {
            GuardianAPI._auth = value
        }
    }
    
    private static var _authProcess : Bool = false
    public var authProcess: Bool {
        get {
            return GuardianAPI._authProcess
        }
        set(value) {
            GuardianAPI._authProcess = value
        }
    }
    
    private static var _clientData : Dictionary<String, String>  = Dictionary<String, String>()
    public var clientData: Dictionary<String, String> {
        get {
            return GuardianAPI._clientData
        }
        set(value) {
            GuardianAPI._clientData = value
        }
    }
    
    /// To get the client data
    /// - Parameters:
    ///   - onSuccess: Will escape an `rtCode` `rawValue` and an `Array` of `ClientIdentity(clientName: String, clientKey: String)`
    ///   - onFailed: Will escape an `errCode` and an `errMsg`
    public func getClients(onSuccess: @escaping (Int, [ClientIdentity])->Void, onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/clients"
        let params = Dictionary<String,String>()
        
        apiCall(params: params, api: apiUrl) { response in
            let clientList = response["data"].arrayObject as! [Dictionary<String, String>]
            let clientData : [ClientIdentity] = clientList.map { dict in
                if let clientName = dict["clientName"], let clientKey = dict["clientKey"] {
                    return ClientIdentity(clientName: clientName, clientKey: clientKey)
                } else {
                    return ClientIdentity(clientName: "", clientKey: "")
                }
            }
            for item in clientData {
                GuardianAPI._clientData[item.clientKey] = item.clientName
            }
            onSuccess(response["rtCode"].intValue, clientData)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
        
    }
    
    /// To the unregister the device (기기해제)
    /// - Parameters:
    ///   - userKey: `String` of userKey
    ///   - onSuccess: Will escape a `JSON` form of data
    ///   - onFailed: Will escape `errorCode, errMsg` if failed
    public func unregisterDevice(userKey: String, onSuccess: @escaping (JSON)->Void, onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/users/\(userKey)/device"
        
        apiCall(params: Dictionary<String,Any>(), api: apiUrl, method: .delete) { data in
            self.clearUserKey()
            onSuccess(data)
            //UserDefaults.standard.set(0, forKey:"firstOtpCount")
            //UserDefaults.standard.set(0, forKey:"otpCount")
            //UserDefaults.standard.set(0, forKey:"firstVerifyOtpCount")
            //UserDefaults.standard.set(0, forKey:"otpVerifyCount")
            //print("success firstotpcount is \(UserDefaults.standard.integer(forKey: "firstOtpCount"))")
            //print("success otpcount is \(UserDefaults.standard.integer(forKey: "otpCount"))")
        } errorCallBack: { errorCode, errMsg in
            onFailed(errorCode, errMsg)
        }
        
        KeychainService.checkSavedToKeychain()
        //UserDefaults.standard.set(nil, forKey: "ourDeviceId")
    }
    
    /// To delete the account(회원탈퇴)
    /// - Parameters:
    ///   - onSuccess: Will escape a `JSON` form of data
    ///   - onFailed: Will escape `errorCode, errMsg` if failed
    public func deleteAccount(onSuccess: @escaping(Int)->Void,
                           onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/me"
        let params = Dictionary<String, Any>()
        
        apiCall(params: params, api: apiUrl, method: .delete) { response in
            print("response is \(response)")
            let rtCode = response["rtCode"].intValue
            onSuccess(rtCode)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    /// To send verify the member user info and delivery OTP number if the user info is correct
    /// - Parameters:
    ///   - userKey: E.g. FNSV
    ///   - name: E.g. FNSV
    ///   - verifyType: is a `String`, which has 2 cases. `CMMDUP001` for email and `CMMDUP002` for sms/phone
    ///   - verifyData: is a `String`, which could be your `email` or your `phone number` depending on the `verifyType`
    ///   - onSuccess: escape when successful
    ///   - onFailed: escape when failed
    public func sendOTPInRegisterDevice(userKey: String, name: String, verifyType: String, verifyData: String, masterClientKey: String, onSuccess: @escaping (Int, Dictionary<String, Any>)->Void, onFailed: @escaping (Int)->Void) {
        
        let apiUrl = "/users/send-otp"
        
        var params = Dictionary<String,String>()
        params["userKey"] = userKey
        params["name"] = name
        params["verifyType"] = verifyType
        params["verifyData"] = verifyData
        params["clientKey"] = masterClientKey
//        params["clientKey"] = K.MasterClientKey
        
        print("params => \(params)")
                
        apiCall(params: params, api: apiUrl, method: .post) { response in
            let rtCode = response["rtCode"].intValue
            var data = Dictionary<String, Any>()
            if let dataObject = response["data"].dictionary {
                if let result = dataObject["result"]?.boolValue {
                    data["result"] = result
                }
                if let authType = dataObject["authType"]?.intValue {
                    data["authType"] = authType
                }
            }
            
            onSuccess(rtCode, data)
            
        } errorCallBack: { errorCode, errorMsg in
            onFailed(errorCode)
        }
    }
    
    /// To send an OTP number via Email
    /// - Parameters:
    ///   - email: fnsvalue@fnsvalue.co.kr
    ///   - onSuccess: will escape when success
    ///   - onFailed: will escape when failed
    public func sendOTPByEmail(email: String,  masterClientKey: String, onSuccess: @escaping(JSON)->Void, onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/mail"
        
        var params = Dictionary<String, Any>()
        params["clientKey"] = masterClientKey
//        params["clientKey"] = K.MasterClientKey
        params["email"] = email
        params["emailType"] = "HTML"
        
        apiCall(params: params, api: apiUrl, method: .post) { response in
            onSuccess(response)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    /// To send an OTP number via phone number
    /// - Parameters:
    ///   - phoneNum: 821012341234
    ///   - onSuccess: will escape when success
    ///   - onFailed: will escape when failed
    public func sendOTPBySms(phoneNum: String, masterClientKey: String, onSuccess: @escaping(JSON)->Void, onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/sms"
        
        var params = Dictionary<String, Any>()
        params["clientKey"] = masterClientKey
//        params["clientKey"] = K.MasterClientKey
        params["phoneNum"] = phoneNum
        
        apiCall(params: params, api: apiUrl, method: .post) { response in
            onSuccess(response)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    /// To count how many otp code was sent to the user
    public func otpCountChecker() -> Bool{
        let userDefaultOtpcount = UserDefaults.standard.integer(forKey: "otpCount")
        let firstOtpcount = UserDefaults.standard.integer(forKey: "firstOtpCount")
        print("firstOtpcount is \(firstOtpcount)")
    
        if firstOtpcount+4 == userDefaultOtpcount{
            print("userDefaultOtpcount is \(userDefaultOtpcount)")
            print("now reached the limit")
            UserDefaults.standard.set(firstOtpcount+4, forKey:"firstOtpCount")
            UserDefaults.standard.set(0, forKey:"firstOtpCount")
            UserDefaults.standard.set(0, forKey:"otpCount")
            return false
        }else{
            UserDefaults.standard.set(userDefaultOtpcount+1, forKey: "otpCount")
            print("userDefaultOtpcount is \(userDefaultOtpcount)")
            return true
        }
    }
    
    /// To count how many otp verification was made
    public func otpVerifyCountChecker() -> Bool{
        let userDefaultVerifyOtpcount = UserDefaults.standard.integer(forKey: "otpVerifyCount")
        let firstVerifyOtpcount = UserDefaults.standard.integer(forKey: "firstVerifyOtpCount")
        print("firstVerifyOtpCount is \(firstVerifyOtpcount)")
    
        if firstVerifyOtpcount+4 == userDefaultVerifyOtpcount{
            print("userDefaultVerifyOtpcount is \(userDefaultVerifyOtpcount)")
            print("now reached the limit")
            UserDefaults.standard.set(firstVerifyOtpcount+4, forKey:"firstVerifyOtpCount")
            UserDefaults.standard.set(0, forKey:"firstVerifyOtpCount")
            UserDefaults.standard.set(0, forKey:"otpVerifyCount")
            UserDefaults.standard.set(0, forKey:"firstOtpCount")
            UserDefaults.standard.set(0, forKey:"otpCount")
            return false
        }else{
            UserDefaults.standard.set(userDefaultVerifyOtpcount+1, forKey: "otpVerifyCount")
            print("userDefaultVerifyOtpcount is \(userDefaultVerifyOtpcount)")
            return true
        }
    }
    
    
    /// To verify OTP number sent to Email
    /// - Parameters:
    ///   - email: fnsvalue@fnsvalue.co.kr
    ///   - authNum: 123456
    ///   - onSuccess: Will escape the result of the OTP verification as `Bool`. If false, user input the wrong OTP number. Otherwise, it means the user has input the correct OTP number.
    ///   - onFailed: will escape `error, errorMsg`
    public func verifyOTPByEmail(email: String, authNum: String, masterClientKey: String, onSuccess: @escaping(Int, Bool, Dictionary<String, Any>)->Void, onFailed: @escaping(Int, String)->Void){
        
        let apiUrl = "/mail/verify"
        
        var params = Dictionary<String, Any>()
        params["clientKey"] = masterClientKey
//        params["clientKey"] = K.MasterClientKey
        params["email"] = email
//        params["phoneNum"] = phoneNum
        params["authNum"] = authNum
        
        print("Param => \(params)")
        
        apiCall(params: params, api: apiUrl, method: .post) { response in
            print("Verify => \(response)")
            let rtCode = response["rtCode"].intValue
            var data = Dictionary<String, Any>()
            
            if let dataObject = response["data"].dictionary {
                if let result = dataObject["result"]?.boolValue,
                   let disposeToken = dataObject["disposeToken"]?.stringValue, result {
                    data["result"] = result
                    data["disposeToken"] = disposeToken
                    onSuccess(rtCode, result, data)
                    print("rtCode is \(rtCode) and result is \(result) and data is \(data)")
                } else {
                    onSuccess(rtCode, false, data)
                }
            } else {
                onSuccess(rtCode, false, data)
            }
        } errorCallBack: { error, errorMsg in
            onFailed(error, errorMsg)
        }
    }
    
    /// To verify OTP number sent to phone number
    /// - Parameters:
    ///   - phoneNum: 821012341234
    ///   - authNum: 123456
    ///   - onSuccess: Will escape the result of the OTP verification as `Bool`. If false, user input the wrong OTP number. Otherwise, it means the user has input the correct OTP number.
    ///   - onFailed: will escape `error, errorMsg`
    public func verifyOtpBySms(phoneNum: String, authNum: String, masterClientKey: String, onSuccess: @escaping(Int, Bool, Dictionary<String, Any>)->Void, onFailed: @escaping(Int, String)->Void){
        
        let apiUrl = "/sms/verify"
        
        var params = Dictionary<String, Any>()
        params["clientKey"] = masterClientKey
//        params["clientKey"] = K.MasterClientKey
        params["phoneNum"] = phoneNum
        params["authNum"] = authNum

        apiCall(params: params, api: apiUrl, method: .post) { response in
            let rtCode = response["rtCode"].intValue
            var data = Dictionary<String, Any>()
            print("Verify => \(response)")
            if let dataObject = response["data"].dictionary {
                if let result = dataObject["result"]?.boolValue,
                   let disposeToken = dataObject["disposeToken"]?.stringValue, result {
                    data["result"] = result
                    data["disposeToken"] = disposeToken
                    onSuccess(rtCode, result, data)
                } else {
                    onSuccess(rtCode, false, data)
                }
            } else {
                onSuccess(rtCode, false, data)
            }
        } errorCallBack: { error, errorMsg in
            onFailed(error, errorMsg)
        }
    }

    /// To request different type of authentication depending on its parameters
    /// - Parameters:
    ///   - qrId: is an `Optional String?` and is used when proceeding the QR authentication
    ///   - clientKey: is used to authenticate a specific `Client` and is a `MasterClientKey` by default
    ///   - authPlatform: is used for statistic purposes to see where the user has proceed the authentication and is `"CMMAPF002"` (Mobile App) by default
    ///   - onSuccess: will escape when success
    ///   - onFailed: will escape when failed
    public func requestAuth(qrId: String? = nil,
                            clientKey: String,
                            authPlatform: String,// = "CMMAPF002",
                            onSuccess: @escaping(RtCode, String)->Void,
                            onFailed: @escaping(Int, String)->Void){
        let apiUrl = "/auth"
        var params = Dictionary<String, Any>()
        params["clientKey"] = clientKey
        params["userKey"] = GuardianAPI.userKey
        params["deviceId"] = GuardianAPI.userKey
        params["authPlatform"] = authPlatform
        
        if let qrId = qrId {
            params["qrId"] = qrId
        }
        
        apiCall(params: params, api: apiUrl, method: .post) { response in
            let responseData = response["data"].dictionaryObject
            
            var data = Dictionary<String, String>()
            data["channelKey"] = responseData?["channelKey"] as? String ?? ""
            data["blockKey"] = responseData?["blockKey"] as? String ?? ""
            GuardianAPI._auth = data
            
            var messageDic = Dictionary<String, String>()
            messageDic["target"] = PushType.Request.rawValue
            messageDic["channel_key"] = data["channelKey"]
            messageDic["block_key"] = data["blockKey"]
            
            GuardianService.sharedInstance.onFcmMessageHandle(messageDic: messageDic) { rtCode, rtMsg in
                onSuccess(rtCode, rtMsg)
            }
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
            print("errCode is \(errCode) and errMsg is \(errMsg)")
        }
    }
    
    /// To request a QR authentication. This method is deprecated. Please use `requestAuth(qrId: String? = nil, clientKey: String = K.MasterClientKey, authPlatform: String = "CMMAPF002", onSuccess: @escaping(RtCode, String)->Void, onFailed: @escaping(Int, String)->Void)` instead.
    /// - Parameters:
    ///   - qrId: must be a non-optional Stirng
    ///   - clientKey: refers to the `clientKey` extracted from the `QRCode`
    ///   - onSuccess: will escape when success
    ///   - onFailed: will escape when failed
    public func requestQRAuth(qrId: String,
                              clientKey: String,
                              onSuccess: @escaping(Int, Dictionary<String, Any>)->Void,
                              onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/auth"
        var params = Dictionary<String, Any>()
        params["clientKey"] = clientKey
        params["userKey"] = GuardianAPI.userKey
        params["deviceId"] = GuardianAPI.userKey
        params["qrId"] = qrId
        
        apiCall(params: params, api: apiUrl, method: .post) { response in
            let data = response["data"].dictionaryObject!
            print("data \(data)")
            
            var messageDic = Dictionary<String, String>()
            messageDic["target"] = PushType.Request.rawValue
            messageDic["channel_key"] = data["channelKey"] as? String ?? ""
            messageDic["block_key"] = data["blockKey"] as? String ?? ""
            
            GuardianService.sharedInstance.onFcmMessageHandle(messageDic: messageDic) { rtCode, rtMsg in
                onSuccess(rtCode.rawValue, data)
            }
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    /// To get Authentication History
    /// - Parameters:
    ///   - page: page number
    ///   - size: length of authentication record
    ///   - onSuccess: will escape an `Array` of `AuthHistory`
    ///   - onFailed: will escape when failed
    public func getAuthHistory(page: Int,
                               size: Int,
                               onSuccess: @escaping(Int, [AuthHistory])->Void,
                               onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/me/history"
        var params = Dictionary<String, Any>()
        params["page"] = page
        params["size"] = size
        params["sort"] = "REG_DT,DESC"
        
        apiCall(params: params, api: apiUrl) { response in
            let rtCode = response["rtCode"].intValue
            let array = response["data"].arrayObject as? [Dictionary<String,Any>] ?? []
//            print("====================================")
//            print("Client : \(GuardianAPI._clientData)")
            let authData : [AuthHistory] = array.map { data in
                
                let lang = Locale.current.languageCode
                
                if let rawRegDt = data["regDt"] as? String {
                    if lang == "ko" {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SS Z"
                        let date = dateFormatter.date(from: rawRegDt)
                        dateFormatter.dateFormat = "yyyy-MM-dd, a h:mm"
                        
                        let stringDate = dateFormatter.string(from: date ?? Date())
                        
//                        onSuccess(rtCode, name, userKey, stringDate, authType)
                        return AuthHistory(userKey: data["userKey"] as! String ,
                                           content: data["content"] as! String ,
                                           connectIp: data["connectIp"] as! String,
                                           clientName: GuardianAPI._clientData[data["clientKey"] as! String] ?? "Unknown Client",
                                           clientKey: data["clientKey"] as! String,
                                           status: AuthHistoryStatus(rawValue: data["status"] as! String) ?? .failed,
                                           seq:"\(data["seq"]!)",
                                           regDt: date ?? Date(),
                                           regDtString: stringDate)
                    } else {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SS Z"
                        let date = dateFormatter.date(from: rawRegDt)
                        dateFormatter.dateFormat = "MMM d, yyyy h:mm a"
                        
                        let stringDate = dateFormatter.string(from: date ?? Date())
                        
                        
//                        onSuccess(rtCode, name, userKey, stringDate, authType)
                        return AuthHistory(userKey: data["userKey"] as! String ,
                                           content: data["content"] as! String ,
                                           connectIp: data["connectIp"] as! String,
                                           clientName: GuardianAPI._clientData[data["clientKey"] as! String] ?? "Unknown Client",
                                           clientKey: data["clientKey"] as! String,
                                           status: AuthHistoryStatus(rawValue: data["status"] as! String) ?? .failed,
                                           seq:"\(data["seq"]!)",
                                           regDt: date ?? Date(),
                                           regDtString: stringDate)
                    }
                    
                    
                }
                return AuthHistory(userKey: data["userKey"] as! String ,
                                   content: data["content"] as! String ,
                                   connectIp: data["connectIp"] as! String,
                                   clientName: GuardianAPI._clientData[data["clientKey"] as! String] ?? "Unknown Client",
                                   clientKey: data["clientKey"] as! String,
                                   status: AuthHistoryStatus(rawValue: data["status"] as! String) ?? .failed,
                                   seq:"\(data["seq"]!)",
                                   regDt: Date(),
                                   regDtString: "")

            }
            onSuccess(rtCode, authData)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    /// To get the user info
    /// - Parameters:
    ///   - onSuccess: will escape `rtCode`, `username`, `userKey`, `registrationDate` and `authType`
    ///   - onFailed: will escape when failed
    public func getMe(onSuccess: @escaping(Int, String, String, String, Int)->Void,
                      onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/me"
        let params = Dictionary<String, Any>()
        
        apiCall(params: params, api: apiUrl) { response in
            print("getMe => \(response)")
            let rtCode = response["rtCode"].intValue
            let data = response["data"].dictionaryObject!
            let userKey = data["userKey"] as? String ?? ""
            let name = data["name"] as? String ?? ""
            let authType = data["authType"] as? Int ?? 3

            let lang = Locale.current.languageCode
            
            if let rawRegDt = data["regDt"] as? String {
                if lang == "ko" {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SS Z"
                    let date = dateFormatter.date(from: rawRegDt)
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    
                    let stringDate = dateFormatter.string(from: date ?? Date())
                    
                    onSuccess(rtCode, name, userKey, stringDate, authType)
                } else {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SS Z"
                    let date = dateFormatter.date(from: rawRegDt)
                    dateFormatter.dateFormat = "MMM dd, yyyy"
                    
                    let stringDate = dateFormatter.string(from: date ?? Date())
                    
                    onSuccess(rtCode, name, userKey, stringDate, authType)
                }
            }
        } errorCallBack: { errCode, errMsg in
            print("Error getMe => \(errCode) \(errMsg)")
            onFailed(errCode, errMsg)
        }
    }
    
    /// To change the 2-factor authentication type
    /// - Parameters:
    ///   - authType: `3` for `biometric authentication` and `4` for `passcode authentication`
    ///   - onSuccess: will escape when successful
    ///   - onFailed: will escape when failed
    public func changeAuthLevel(authType : Int,
                                onSuccess: @escaping(Int)->Void,
                                onFailed: @escaping(Int, String)->Void){
        let apiUrl = "/me"
        var params = Dictionary<String, Any>()
        params["authType"] = authType
        
        apiCall(params: params, api: apiUrl, method: .put) { response in
            onSuccess(0)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    /// To get the integrated client website
    /// - Parameters:
    ///   - onSuccess: will escape a `Array` of `Client`
    ///   - onFailed: will escape when failed
    public func interLockClients(onSuccess: @escaping(Int, [Client])->Void,
                                 onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/app/interlock/clients"
        let params = Dictionary<String, Any>()
        
        apiCall(params: params, api: apiUrl) { response in
            print("============ Get Client API ===============")
            print(response)
            print("===========================================")
            let rtCode = response["rtCode"].intValue
            let clientList = response["data"].arrayObject! as! [Dictionary<String,Any>]
            let clients : [Client] = clientList.map { dict in
                
                let userStatus = dict["userStatus"] as? String ?? ""
                let interlock = dict["interlock"] as? Bool ?? true
                let clientName = dict["clientName"] as? String ?? ""
                let seq = dict["seq"] as? Int ?? 0
                let clientKey = dict["clientKey"] as? String ?? ""
                let clientDescription = dict["clientExplain"] as? String ?? ""
                let siteUrl = dict["siteUrl"] as? String ?? ""
                let verifyType : String? = dict["verifyType"] as? String
                
                return Client(userStatus: IntegratingUserStatus(rawValue: userStatus) ?? .none,
                              interlock: interlock,
                              clientName: clientName,
                              seq: seq,
                              clientKey: clientKey,
                              clientDescription: clientDescription,
                              siteUrl: siteUrl,
                              verifyType: verifyType)
            }
            onSuccess(rtCode, clients)
            
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
        
    }
    
    /// To unlinke a website
    /// - Parameters:
    ///   - clientKey: clientKey of the website you want to unlink
    ///   - onSuccess: will escape when successfull
    ///   - onFailed: will escape when failed
    public func unlinkSite(clientKey : String,
                           onSuccess: @escaping(Int)->Void,
                           onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/me/sites/\(clientKey)"
        let params = Dictionary<String, Any>()
        
        apiCall(params: params, api: apiUrl, method: .delete) { response in
            let rtCode = response["rtCode"].intValue
            onSuccess(rtCode)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    /// To get the clients the user search for
    /// - Parameters:
    ///   - clientName: clientName the user searches
    ///   - onSuccess: will escape an array of `Client` object
    ///   - onFailed: will escape when failed
    public func linkSearchClient(clientName: String,
                                 onSuccess: @escaping(Int, [Client])->Void,
                                 onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/app/link/search/clients"
        var params = Dictionary<String, Any>()
        params["clientName"] = clientName
        
        apiCall(params: params, api: apiUrl) { response in
            let rtCode = response["rtCode"].intValue
            let clientList = response["data"].arrayObject! as! [Dictionary<String,Any>]
            let searchedClient : [Client] = clientList.map({ dict in
                
                let userStatus = dict["userStatus"] as? String ?? ""
                let interlock = dict["interlock"] as? Bool ?? true
                let clientName = dict["clientName"] as? String ?? ""
                let seq = dict["seq"] as? Int ?? 0
                let clientKey = dict["clientKey"] as? String ?? ""
                let clientDescription = dict["clientExplain"] as? String ?? ""
                let siteUrl = dict["siteUrl"] as? String ?? ""
                let verifyType : String? = dict["verifyType"] as? String
                
                return Client(userStatus: IntegratingUserStatus(rawValue: userStatus) ?? .none,
                              interlock: interlock,
                              clientName: clientName,
                              seq: seq,
                              clientKey: clientKey,
                              clientDescription: clientDescription,
                              siteUrl: siteUrl,
                              verifyType: verifyType)
            })
            onSuccess(rtCode, searchedClient)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    /// To check link credential and then integrate the website
    /// - Parameters:
    ///   - clientKey: clientKey of the website you want to integrate
    ///   - siteToken: is `nil` if the website doesn't need any verification; otherwise, you have to get the website token from `linkVerifySite` method
    ///   - onSuccess: will escape when successful
    ///   - onFailed: will escape when failed
    public func checkLinkSiteCredential(clientKey: String,
                                        siteToken: String?,
                                        onSuccess: @escaping(JSON)->Void,
                                        onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/me/sites"
        var params = Dictionary<String, Any>()
        params["clientKey"] = clientKey
        params["siteToken"] = siteToken
        
        apiCall(params: params, api: apiUrl, method: .post) { response in
            onSuccess(response)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    /// To verify and then integrate the website
    /// - Parameters:
    ///   - clientKey: clientKey of the website you want to integrate
    ///   - id: your ID from the actual website
    ///   - password: your password from the actual website
    ///   - onSuccess: will escape a token when successful
    ///   - onFailed: will escape when failed
    public func linkVerifySite(clientKey: String,
                               id: String,
                               password: String,
                               onSuccess: @escaping(Int, String)->Void,
                               onFailed: @escaping(Int, String)->Void){
        let apiUrl = "/users/link/verify"
        var params = Dictionary<String, Any>()
        params["clientKey"] = clientKey
        params["id"] = id
        params["pw"] = password
        
        apiCall(params: params, api: apiUrl, method: .post) { response in
            let rtCode = response["rtCode"].intValue
            let token = response["token"].stringValue
            onSuccess(rtCode, token)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    /// To issue OTP number for OTP login authenticaiton
    /// - Parameters:
    ///   - onSuccess: will escape with an OTP number
    ///   - onFailed: will escape when failed
    public func issueOTP(onSuccess: @escaping(Int, String)->Void,
                         onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/otp/generate"
        let params = Dictionary<String, Any>()
        
        apiCall(params: params, api: apiUrl, method: .post) { response in
            let rtCode = response["rtCode"].intValue
            let otp = response["data"].stringValue
            onSuccess(rtCode, otp)
        } errorCallBack: { errCode, errMsg in
            print("Failed")
            onFailed(errCode, errMsg)
        }
    }
    
    /// To cancel the OTP number
    /// - Parameters:
    ///   - otpCode: 123456
    ///   - onSuccess: will escape when successful
    ///   - onFailed: will escape when failed
    public func cancelOTP(otpCode: String,
                          onSuccess: @escaping(JSON)->Void,
                          onFailed: @escaping(Int, String)->Void){
        let apiUrl = "/otp/\(otpCode)"
        let params = Dictionary<String, Any>()
        
        apiCall(params: params, api: apiUrl, method: .delete) { response in
            onSuccess(response)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }

    /// To get the secretKey for TOTP generation
    /// - Parameters:
    ///   - onSuccess: will escape with a secretKey
    ///   - onFailed: will escape when failed
    public func getTOTPData(onSuccess: @escaping(Int, Dictionary<String, String>)->Void,
                                 onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/totp/generate"
        let params = Dictionary<String, Any>()

        apiCall(params: params, api: apiUrl, method: .post) { response in
            print("getTOTP => \(response)")
            let rtCode = response["rtCode"].intValue
            //let totpdata = response["data"].description
            let totpdata = (response["data"].dictionaryObject! as? Dictionary<String, String>) ?? Dictionary<String, String>()
            onSuccess(rtCode, totpdata)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    /// To get a list of agreement
    /// - Parameters:
    ///   - clientKey: `String`
    ///   - onSuccess: will escape with an `Array` of `Agreement`
    ///   - onFailed: will escape when failed
    public func getAgreements(clientKey: String,
                              onSuccess: @escaping(Int, [Agreement])->Void,
                              onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/clients/\(clientKey)/agreements"
        var params = Dictionary<String, Any>()
        
        let lang = Locale.current.languageCode
        
        switch lang {
        case "ko":
            params["lang"] = "CMMLNG002"
            break
        case "en":
            params["lang"] = "CMMLNG001"
            break
        default:
            params["lang"] = "CMMLNG001"
            break
        }
        
        apiCall(params: params, api: apiUrl, method: .get) { response in
            let rtCode = response["rtCode"].intValue
            let data = response["data"].arrayObject as? [Dictionary<String, Any>] ?? [Dictionary<String, Any>]()
            
            let agreements : [Agreement] = data.map { value in
                return Agreement(seq: value["seq"] as? Int ?? Int(),
                                 title: value["title"] as? String ?? "",
                                 type: AgreementType(rawValue: value["type"] as? String ?? "") ?? .none,
                                 userStatus: value["useStatus"] as? String ?? "",
                                 lang: value["lang"] as? String ?? "",
                                 clientKey: value["clientKey"] as? String ?? "")
            }
            
            onSuccess(rtCode, agreements)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    /// To get the agreement HTML content
    /// - Parameters:
    ///   - clientKey: `String`
    ///   - seq: The sequence number representing a certain agreement
    ///   - onSuccess: will escape with `AgreementHTML` object
    ///   - onFailed: will escape when failed
    public func getAgreementHTML(clientKey: String,
                          seq: Int,
                          onSuccess: @escaping(Int, AgreementHTML)->Void,
                          onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/clients/\(clientKey)/agreements/\(seq)"
        let params = Dictionary<String, Any>()
        
        apiCall(params: params, api: apiUrl, method: .get) { response in
            let rtCode = response["rtCode"].intValue
            let data = response["data"].dictionaryObject  ?? Dictionary<String, Any>()
            
            let agreementHTML = AgreementHTML(userStatus: data["useStatus"] as? String ?? "",
                                              title: data["title"] as? String ?? "",
                                              seq: data["seq"] as? Int ?? Int(),
                                              regUserKey: data["regUserKey"] as? String ?? "",
                                              lang: data["lang"] as? String ?? "",
                                              content: data["content"] as? String ?? "",
                                              clientKey: data["clientKey"] as? String ?? "",
                                              regDt: data["regDt"] as? String ?? "",
                                              subCltBhv: data["subCltBhv"] as? String ?? "",
                                              clientName: data["clientName"] as? String ?? "",
                                              type: AgreementType(rawValue: data["type"] as? String ?? "") ?? .none)
            
            onSuccess(rtCode, agreementHTML)
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    /// To get Notice Update
    /// - Parameters:
    ///   - page: page number
    ///   - size: length of notice
    ///   - onSuccess: will escape an `Array` of `Notice`
    ///   - onFailed: will escape when failed
    public func getNoticeUpdate(page: Int,
                               size: Int,
                                patchType: String,
                               onSuccess: @escaping(Int, [Notice])->Void,
                               onFailed: @escaping(Int, String)->Void) {
        let apiUrl = "/patches"
        var params = Dictionary<String, Any>()
        params["page"] = page
        params["size"] = size
        params["patchType"] = patchType
                
        apiCall(params: params, api: apiUrl) { response in
            let rtCode = response["rtCode"].intValue
            let array = response["data"].arrayObject as? [Dictionary<String,Any>] ?? []
            let noticeData : [Notice] = array.map { data in
                
                let lang = Locale.current.languageCode
                
                if let rawRegDt = data["regDt"] as? String {
                    if lang == "ko" {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SS Z"
                        let date = dateFormatter.date(from: rawRegDt)
                        //dateFormatter.dateFormat = "yyyy-MM-dd, a h:mm"
                        dateFormatter.dateFormat = "yyyy.MM.dd"
                        
                        let stringDate = dateFormatter.string(from: date ?? Date())
                        
//                        onSuccess(rtCode, name, userKey, stringDate, authType)
                        return Notice(title: data["title"] as! String,
                                      patchType: data["patchType"] as! String,
                                      regDt: stringDate)
                    } else {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SS Z"
                        let date = dateFormatter.date(from: rawRegDt)
                        //dateFormatter.dateFormat = "MMM d, yyyy h:mm a"
                        dateFormatter.dateFormat = "MMM d, yyyy"
                        
                        let stringDate = dateFormatter.string(from: date ?? Date())
//                        onSuccess(rtCode, name, userKey, stringDate, authType)
                        return Notice(title: data["title"] as! String,
                                      patchType: data["patchType"] as! String,
                                      regDt: stringDate)
                    }
                }                
                return Notice(title: data["title"] as! String,
                              patchType: data["patchType"] as! String,
                              regDt: "")

            }
            onSuccess(rtCode, noticeData )
        } errorCallBack: { errCode, errMsg in
            onFailed(errCode, errMsg)
        }
    }
    
    
    //MARK: - apiCall
    /// Creates a `DataRequest` using the default `SessionManager` to retrieve the contents of the specified `url`,
    /// `method`, `parameters`, `encoding` and `headers`.
    ///
    /// - parameter api:        The api, which will later be concatenated with `Domain.apiDomain` to create `url`.
    /// - parameter method:     The HTTP method. `.get` by default.
    /// - parameter params: The parameters cannot be `nil`.
    /// - Parameter successCallBack: A callback function to retrieve `JSONResponse` when successfully fetching data.
    /// - parameter errorCallBack: A callback function to retrieve `statusCode` in `Int` and `statusMessage` in `String` in case of failure
    ///
    private func apiCall(params: Dictionary<String,Any>,
                         api: String,
                         method: HTTPMethod = .get,
                         headers: HTTPHeaders? = nil,
                         successCallBack : @escaping(JSON) -> Void,
                         errorCallBack: @escaping(Int, String) -> Void){
        
        let url = baseUrl + api
        let encodingMethod: ParameterEncoding = (method == .get) ? URLEncoding.default : JSONEncoding.default
        
        var apiHeaders : HTTPHeaders? = nil
        
        if headers == nil {
            if let token = GuardianAPI._token {
                apiHeaders = ["Authorization":token]
            }
        } else {
            apiHeaders = headers
        }
        
        print("================= API Call =====================")
        print("URL \t: \t\(url)")
        print("Method \t: \t\(method)")
        print("Header \t: \t\(String(describing: apiHeaders))")
        print("EncodingMethod \t: \t\(encodingMethod)")
        print("================================================")
        
        //AF.request(url, method: method, parameters: params, encoding: encodingMethod, headers: apiHeaders).responseJSON { (response) in
        // AF 5.0.0
        AF.request(url, method: method, parameters: params, encoding: encodingMethod, headers: apiHeaders).responseDecodable {(response: DataResponse<JSON, AFError>) in
            switch response.result {
            case .failure(_):
            var statusCode : Int! = response.response?.statusCode ?? RtCode.API_ERROR.rawValue
            var statusMessage : String

                if let error = response.error {
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
                        case .customValidationFailed(error: let error):
                            statusMessage = "Custom validation failed: \(error)"
                        }
                    case .responseSerializationFailed(let reason):
                        statusMessage = "Response serialization failed: \(error.localizedDescription), reason: \(reason)"
                        statusMessage = "Failure Reason"
                        // statusCode = 3840 ???? maybe..
                    case .createUploadableFailed(error: let error):
                        print(error)
                    case .createURLRequestFailed(error: let error):
                        print(error)

                    case .downloadedFileMoveFailed(error: let error, source: let source, destination: let destination):
                        print("error is \(error) and source is \(source) and destination is \(destination)")

                    case .explicitlyCancelled:
                        print(error)

                    case .parameterEncoderFailed(reason: let reason):
                        print(reason)

                    case .requestAdaptationFailed(error: let error):
                        print(error)

                    case .requestRetryFailed(retryError: let retryError, originalError: let originalError):
                        print("retryError is \(retryError) and originalError is \(originalError)")

                    case .serverTrustEvaluationFailed(reason: let reason):
                        print(reason)

                    case .sessionDeinitialized:
                        print(error)

                    case .sessionInvalidated(error: let error):
                        print(error as Any)

                    case .sessionTaskFailed(error: let error):
                        print(error)

                    case .urlRequestValidationFailed(reason: let reason):
                        print(reason)

                    }
                    statusMessage = "Underlying error"
                } else if let error = response.error{
                    statusMessage = "URLError occurred, error: \(error)"

                } else {
                    statusMessage = "Unknown error"
                }

                errorCallBack(statusCode, statusMessage)
                return
            case .success(_):
                print("successful")
            }
            if let data = response.value {
                let json = JSON(data)
                if json["rtCode"] == 0 {
                    successCallBack(json)
                } else {
                    print("Error RTCode : \(json["rtCode"])")
                    errorCallBack(json["rtCode"].rawValue as! Int, "")
                }
            }
        }
        
        // AF 4.0.0
//        Alamofire.request(url, method: method, parameters: params, encoding: encodingMethod, headers: apiHeaders).responseJSON { response in
//            guard response.result.isSuccess else {
//                var statusCode : Int! = response.response?.statusCode ?? 2020
//                var statusMessage : String
//
//                if let error = response.result.error as? AFError {
//                    statusCode = error._code // statusCode Private
//
//                    switch error {
//                    case .invalidURL(let url):
//                        statusMessage = "Invalid URL, url: \(url)"
//                    case .parameterEncodingFailed(let reason):
//                        statusMessage = "Parameter encoding failed, reason: \(reason)"
//                    case .multipartEncodingFailed(let reason):
//                        statusMessage = "Multipart encoding failed, reason: \(reason)"
//                    case .responseValidationFailed(let reason):
//                        statusMessage = "Response validation failed, reason: \(reason)"
//                        //                        statusMessage = "Failure Reason"
//                        switch reason {
//                        case .dataFileNil, .dataFileReadFailed:
//                            statusMessage = "Downloaded file could not be read"
//                        case .missingContentType(let acceptableContentTypes):
//                            statusMessage = "Content Type Missing: \(acceptableContentTypes)"
//                        case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
//                            statusMessage = "Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)"
//                        case .unacceptableStatusCode(let code):
//                            statusMessage = "Response status code was unacceptable: \(code)"
//                            statusCode = code
//                        }
//                    case .responseSerializationFailed(let reason):
//                        statusMessage = "Response serialization failed: \(error.localizedDescription), reason: \(reason)"
//                        statusMessage = "Failure Reason"
//                        // statusCode = 3840 ???? maybe..
//                    }
//                    statusMessage = "Underlying error"
//                } else if let error = response.result.error as? URLError {
//                    statusMessage = "URLError occurred, error: \(error)"
//
//                } else {
//                    statusMessage = "Unknown error"
//                }
//
//                errorCallBack(statusCode, statusMessage)
//                return
//            }
//            if let data = response.result.value {
//                let json = JSON(data)
//                if json["rtCode"] == 0 {
//                    successCallBack(json)
//                } else {
//                    print("Error RTCode : \(json["rtCode"])")
//                    errorCallBack(json["rtCode"].rawValue as! Int, "")
//                }
//            }
//        }
    }
}

      
