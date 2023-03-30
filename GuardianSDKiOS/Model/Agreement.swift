//
//  AgreementModel.swift
//  GuardianCCS-iOS-Native
//
//  Created by elite on 2021/11/15.
//

import Foundation

struct Agreement {
    let seq: Int
    let title: String
    let type: AgreementType
    let userStatus: String
    let lang: String
    let clientKey: String
}

struct AgreementHTML {
    let userStatus : String
    let title : String
    let seq : Int
    let regUserKey : String
    let lang : String
    let content : String
    let clientKey: String
    let regDt : String
    let subCltBhv : String
    let clientName : String
    let type : AgreementType
}

enum AgreementType : String {
    case CMMAGR001 = "CMMAGR001"
    case CMMAGR002 = "CMMAGR002"
    case CMMAGR003 = "CMMAGR003"
    case none = ""
}
