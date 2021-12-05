//
//  APIEventLogger.swift
//  AlamofireInterceptor
//
//  Created by paige on 2021/12/06.
//

import Foundation
import Alamofire

class APIEventLogger: EventMonitor {

    let queue = DispatchQueue(label: "myNetworkLogger")

    func requestDidFinish(_ request: Request) {
      print("🛰 NETWORK Reqeust LOG")
      print(request.description)

      print(
        "URL: " + (request.request?.url?.absoluteString ?? "")  + "\n"
          + "Method: " + (request.request?.httpMethod ?? "") + "\n"
          + "Headers: " + "\(request.request?.allHTTPHeaderFields ?? [:])" + "\n"
      )
      print("Authorization: " + (request.request?.headers["Authorization"] ?? ""))
      print("Body: " + (request.request?.httpBody?.toPrettyPrintedString ?? ""))
    }

    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        print("🛰 NETWORK Response LOG")
        print(
          "URL: " + (request.request?.url?.absoluteString ?? "") + "\n"
            + "Result: " + "\(response.result)" + "\n"
            + "StatusCode: " + "\(response.response?.statusCode ?? 0)" + "\n"
            + "Data: \(response.data?.toPrettyPrintedString ?? "")"
        )
    }
}

extension Data {
    var toPrettyPrintedString: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
        return prettyPrintedString as String
    }
}

class API {
    static let session: Session = {
        let configuration = URLSessionConfiguration.af.default
        let apiLogger = APIEventLogger()
        return Session(configuration: configuration, eventMonitors: [apiLogger])
    }()
}

class PredictAgeAPI {
    
    static func predictWithEventLogger(request: PredictAgeRequest, completion: @escaping (_ succeed: Person?, _ failed: Error?) -> Void) {
        API.session.request(PredictAgeTarget.predict(request), interceptor: MyRequestInterceptor())
            .responseDecodable { (response: AFDataResponse<PredictAgeResponse>) in
                switch response.result {
                case .success(let response):
                    completion(response.toDomain, nil)
                case .failure(let error):
                    completion(nil, error)
                }
            }
    }
    
}


/*
 
 @IBAction func didTapCallAPIButton(_ sender: Any) {
     let request = PredictAgeRequest(name: textField.text ?? "")
     PredictAgeAPI.predictWithEventLogger(request: request) { [weak self] succeed, failed in
         guard let succeed = succeed else { return }
         self?.label.text = "\(succeed.name)이름, 예측 = \(succeed.age)살"
     }
 }
 
 */
