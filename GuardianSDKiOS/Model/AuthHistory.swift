//
//  AuthHistory.swift
//  GuardianCCS-iOS-Native
//
//  Created by elite on 2021/10/22.
//

import Foundation

enum AuthHistoryStatus : String {
    case success = "CMMASC001"
    case failed = "CMMASC002"
    case canceled = "CMMASC003"
    case timeout = "CMMASC004"
}

struct AuthHistory {
    let userKey : String
    let content : String
    let connectIp : String
    let clientName : String
    let clientKey: String
    let status : AuthHistoryStatus
    let seq : String
    let regDt : Date
    let regDtString : String
}
