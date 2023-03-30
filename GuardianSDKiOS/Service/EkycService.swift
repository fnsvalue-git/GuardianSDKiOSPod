//
//  EkycService.swift
//  GuardianSDKiOS
//
//  Created by fnsvalue on 2022/05/19.
//  Copyright © 2022 fns_mac_pro. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

public class EkycService {

    public enum EkycType : String{
        case idCard = "idCard"
        case passport = "passport"
    }
    public var decideEkycType = EkycType.idCard

    public static let sharedInstance = EkycService()

    public let baseUrl = "https://ekycportaldemo.innov8tif.com/api/ekyc/"
    public let EKYC_USER_NAME = "fns_trial"
    public let EKYC_PASSWORD = "F1j2k3!@#"

    private var journeyId : String?

    public func getJourneyID(onResult: @escaping(String, String) -> Void) {

        let apiUrl = baseUrl + "journeyid"
        var params = Dictionary<String, Any>()

        params["username"] = EKYC_USER_NAME
        params["password"] = EKYC_PASSWORD

        var message : String?
        var status : String?

        //AF.request(apiUrl, method: .post, parameters: params, encoding: JSONEncoding.default).responseJSON { (response) in
        AF.request(apiUrl, method: .post, parameters: params, encoding: JSONEncoding.default).responseDecodable{(response: DataResponse<JSON, AFError>) in
            switch response.result {
            case .failure(_):
                var statusCode : Int! = response.response?.statusCode ?? 2020
                var statusMessage : String = ""

                print("statusCode is \(String(describing: statusCode)) and statusMessage is \(statusMessage)")

                if let error = response.error{
                    statusCode = error._code // statusCode Private
                    statusMessage = "Underlying error"
                }else{
                    statusMessage = "Unknown error"
                }
            case .success(_):
                print("successful")
            }

            if let data = response.value{
                let json = JSON(data)
                print(json)
                if json["status"] == "success" {
                    status = json["status"].string
                    self.journeyId = json["journeyId"].string
                    onResult(status ?? "", self.journeyId ?? "")
                } else {
                    status = json["status"].string
                    self.journeyId = json["journeyId"].string
                    onResult(status ?? "", self.journeyId ?? "")
                    message = json["message"].string
                    onResult(status ?? "", message ?? "")
                }
            }
        }
    }

    //okayId
    public func verifyOkayId(frontImageBase64 : String,
                             backImageBase64 : String,
                             onResult: @escaping(Dictionary<String, String>) -> Void) {

        var resultData = Dictionary<String, String>()
        let apiUrl = baseUrl + "okayid"
        var params = Dictionary<String, Any>()

        params["journeyId"] = self.journeyId
        params["base64ImageString"] = frontImageBase64
        params["backImage"] = backImageBase64
        params["imageFormat"] = "jpg"
        params["imageEnabled"] = "false"
        params["faceImageEnabled"] = "false"
        params["docTypeEnabled"] = "true"
        params["cambodia"] = "false"
        params["docType"] = "indonesia_ektp"

        //AF.request(apiUrl, method: .post, parameters: params, encoding: JSONEncoding.default).responseJSON { response in
        AF.request(apiUrl, method: .post, parameters: params, encoding: JSONEncoding.default).responseDecodable{(response: DataResponse<JSON, AFError>) in
            switch response.result {
            case .failure(_):
                var statusCode : Int! = response.response?.statusCode ?? 2020
                var statusMessage : String = ""

                print("statusCode is \(String(describing: statusCode)) and statusMessage is \(statusMessage)")

                if let error = response.error{
                    statusCode = error._code // statusCode Private
                    statusMessage = "Underlying error"
                }else{
                    statusMessage = "Unknown error"
                }
            case .success(_):
                print("successful")
            }

            if let data = response.value {
                let json = JSON(data)
                //print(json)
                if json["status"] == "success" {
                    if let result = json["result"].array {
                        let results = result[0]
                        if let listVerifiedFields = results["ListVerifiedFields"].dictionary {
                            print("decideEkycType is \(self.decideEkycType)")
                            switch self.decideEkycType {
                            case .idCard :
                                if let pFieldMaps = listVerifiedFields["pFieldMaps"]?.array {
                                    //print("pFieldMaps is \(pFieldMaps)")
                                    resultData["status"] = json["status"].string
                                    resultData["message"] = json["message"].string
                                    resultData["idNumber"] = pFieldMaps[1]["Field_Visual"].string //신분증번호
                                    resultData["name"] = pFieldMaps[7]["Field_Visual"].string //이름
                                    resultData["gender"] = pFieldMaps[5]["Field_Visual"].string //성별
                                    resultData["dateOfBirth"] = pFieldMaps[2]["Field_Visual"].string //생년월일
                                    resultData["issuingState"] = pFieldMaps[8]["Field_Visual"].string //발행국가
                                    resultData["address"] = pFieldMaps[6]["Field_Visual"].string //주소

                                    onResult(resultData)
                                }
                            case .passport :
                                if let pFieldMaps = listVerifiedFields["pFieldMaps"]?.array {
                                    //print("pFieldMaps is \(pFieldMaps)")
                                    resultData["status"] = json["status"].string
                                    resultData["message"] = json["message"].string
                                    resultData["idNumber"] = pFieldMaps[2]["Field_Visual"].string //여권번호
                                    resultData["name"] = pFieldMaps[12]["Field_Visual"].string //이름
                                    resultData["gender"] = pFieldMaps[9]["Field_Visual"].string //성별
                                    resultData["dateOfBirth"] = pFieldMaps[5]["Field_Visual"].string //생년월일
                                    resultData["issuingState"] = pFieldMaps[11]["Field_Visual"].string //발행국가
                                    resultData["expireDate"] = pFieldMaps[3]["Field_Visual"].string //주소

                                    onResult(resultData)
                                }
                            }
                        }
                    }
                } else {
                    resultData["status"] = json["status"].string
                    resultData["message"] = json["message"].string
                    onResult(resultData)
                }
            }
        }
    }

    //okayFace
    public func verifyOkayFace(
        imageBestBase64 : String,
        imageIdCardBase64: String,
        onResult: @escaping(Dictionary<String, String>) -> Void) {

        var resultData = Dictionary<String, String>()
        let apiUrl = baseUrl + "okayface"

//        AF.upload(
//            multipartFormData: { (multipartFormData) in
//                multipartFormData.append(Data(self.journeyId!.utf8),
//                                         withName: "journeyId", mimeType: "text/plain")
//                multipartFormData.append(Data(imageBestBase64.utf8),
//                                         withName: "imageBestBase64", mimeType: "text/plain")
//                multipartFormData.append(Data(imageIdCardBase64.utf8),
//                                         withName: "imageIdCardBase64", mimeType: "text/plain")
//                multipartFormData.append(Data("true".utf8),
//                                         withName: "livenessDetection", mimeType: "text/plain")
//
//              },
//            to: apiUrl).responseJSON{response in
        AF.upload(
            multipartFormData: { (multipartFormData) in
                multipartFormData.append(Data(self.journeyId!.utf8),
                                         withName: "journeyId", mimeType: "text/plain")
                multipartFormData.append(Data(imageBestBase64.utf8),
                                         withName: "imageBestBase64", mimeType: "text/plain")
                multipartFormData.append(Data(imageIdCardBase64.utf8),
                                         withName: "imageIdCardBase64", mimeType: "text/plain")
                multipartFormData.append(Data("true".utf8),
                                         withName: "livenessDetection", mimeType: "text/plain")

              },
            to: apiUrl).responseDecodable{(response: DataResponse<JSON, AFError>) in
                switch response.result {
                        case .success(_):
                            guard let _ = response.response?.statusCode, let data = response.value else { return }
                                let dt = JSON(data)
                                if dt["status"] == "success" {
                                    if let imageBestLiveness = dt["imageBestLiveness"].dictionary {
                                        resultData["status"] = dt["status"].string
                                        resultData["probability"] = imageBestLiveness["probability"]!.string
                                        resultData["quality"] = imageBestLiveness["quality"]!.string
                                        resultData["score"] = imageBestLiveness["score"]!.string
                                    }
                                    if let result_idcard = dt["result_idcard"].dictionary {
                                        resultData["confidence"] = result_idcard["confidence"]!.string
                                    }
                                }
                                onResult(resultData)
                        case .failure(let error):
                            print(error.localizedDescription)
                    }
            }
    }

    //okayDoc
    public func verifyOkayDoc(
        idImageBase64Image : String,
        livenessFaceBase64Image : String,
        onResult: @escaping(Dictionary<String, String>) -> Void) {

        var resultData = Dictionary<String, String>()
        let apiUrl = baseUrl + "okaydoc"
        var params = Dictionary<String, Any>()

        params["journeyId"] = self.journeyId
        params["type"] = "nonpassport"
        params["idImageBase64Image"] = idImageBase64Image
        params["livenessFaceBase64Image"] = livenessFaceBase64Image
        params["version"] = "3"
        params["docType"] = "mykad"
        params["landmarkCheck"] = "true"
        params["fontCheck"] = "true"
        params["microprintCheck"] = "true"
        params["photoSubstitutionCheck"] = "true"
        params["icTypeCheck"] = "true"
        params["colorMode"] = "true"
        params["hologram"] = "true"
        params["screenDetection"] = "true"
        params["ghostPhotoColorDetection"] = "true"
        params["idBlurDetection"] = "true"
        params["faceBrightnessDetection"] = "true"
        params["contentSubstitution"] = "true"

        var docList = [Dictionary<String, Any>]()

        var doc = Dictionary<String, Any>()
        doc["base64Image"] = idImageBase64Image
        doc["type"] = "high_quality"
        docList.append(doc)
        params["otherDocList"] = docList

        //AF.request(apiUrl, method: .post, parameters: params, encoding: JSONEncoding.default).responseJSON { response in
        AF.request(apiUrl, method: .post, parameters: params, encoding: JSONEncoding.default).responseDecodable{(response: DataResponse<JSON, AFError>) in
            switch response.result {
            case .failure(_):
                var statusCode : Int! = response.response?.statusCode ?? 2020
                var statusMessage : String = ""

                print("statusCode is \(String(describing: statusCode)) and statusMessage is \(statusMessage)")

                if let error = response.error{
                    statusCode = error._code // statusCode Private
                    statusMessage = "Underlying error"
                }else{
                    statusMessage = "Unknown error"
                }
            case .success(_):
                print("successful")
            }

            if let data = response.value {
                let json = JSON(data)
                print("okaydoc is \(json["status"])")
                if json["status"] == "success" {
                    if json["methodList"].array != nil {
                            resultData["status"] = json["status"].string
                            resultData["message"] = json["message"].string
                            onResult(resultData)
                    }
                } else {
                    resultData["status"] = json["status"].string
                    resultData["message"] = json["message"].string
                    onResult(resultData)
                }
            }
        }
    }
}
