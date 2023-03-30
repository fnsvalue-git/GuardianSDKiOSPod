//
//  PushNotificationModel.swift
//  GuardianCCS-iOS-Native
//
//  Created by elite on 2021/10/19.
//

import Foundation

struct PushNotificationModel {
    var title : String
    var body : String
    var userInfo : UserInfo
}

enum PushType : String {
    case Request = "1000"
    case Canceled = "1001"
    case Success = "1002"
    case Failed = "1003"
    case Change = "1010"
}

struct UserInfo {
    var blockKey : String
    var clientKey : String
    var target : PushType
    var clientName : String
    var fId : String
    var siteUrl : String
    var channelKey : String
    var messageId : String
//    var googleCAE : Int
//    var aps : Dictionary<String, String>
    var senderId : String
    var otpAuth : Bool
}
