//
//  Client.swift
//  GuardianCCS-iOS-Native
//
//  Created by elite on 2021/10/27.
//

import Foundation


public struct Client {
    let userStatus : IntegratingUserStatus
    let interlock : Bool
    let clientName : String
    let seq : Int
    let clientKey : String
    let clientDescription : String
    let siteUrl : String
    let verifyType : String?
}

public enum IntegratingUserStatus : String {
    case normal = "CMMMST001"
    case wait = "CMMMST002"
    case block = "CMMMST003"
    case deleted = "CMMMST004"
    case withdraw = "CMMMST005"
    case reject = "CMMMST006"
    case none = ""
}
