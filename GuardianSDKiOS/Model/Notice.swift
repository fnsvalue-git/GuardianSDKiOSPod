//
//  Notice.swift
//  GuardianCCS-iOS-Native
//
//  Created by fnsvalue on 2022/12/08.
//

import Foundation

public enum NoticePatchType : String {
    case web  = "CMMPTN001"
    case Android = "CMMPTN002"
    case IOS = "CMMPTN003"
    case Windows = "CMMPTN004"
    case API = "CMMPTN005"
}

public struct Notice {
    let title : String
    let patchType : String
    let regDt : String
    //let version : String
    //let regUserName : String
    //let deployDt : String
    //let page : Int
    //let size : Int
}
