//
//  AlmofireAdaptRetry.swift
//  AlamofireInterceptor
//
//  Created by paige on 2021/12/06.
//

import Foundation
import Alamofire


// MARK: - INTERCEPTOR

// RequestInterceptor: RequestAdaptor & RequestRetrier
protocol RequestInterceptor: RequestAdapter, RequestRetrier {}

extension RequestInterceptor {

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        completion(.doNotRetry)
    }
    
}

class MyRequestInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard urlRequest.url?.absoluteString.hasPrefix("https://api.agify.io") == true,
              let accessToken = KeychainServiceImpl.shared.accessToken else {
                  completion(.success(urlRequest))
                  return
              }

        var urlRequest = urlRequest
        urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        completion(.success(urlRequest))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            completion(.doNotRetryWithError(error))
            return
        }

        /* TODO
        RefreshTokenAPI.refreshToken { result in
            switch result {
            case .success(let accessToken):
                KeychainServiceImpl.shared.accessToken = accessToken
                completion(.retry)
            case .failure(let error):
                completion(.doNotRetryWithError(error))
            }
        }
        */
    }
}

// MARK: - USAGE
struct PredictAgeAPI {
    
    static func predict(request: PredictAgeRequest, completion: @escaping(_ succeed: Person?, _ faield: Error?) -> Void) {
        AF.request(PredictAgeTarget.predict(request), interceptor: MyRequestInterceptor())
            .responseDecodable { response in
                switch response.result {
                case .success(let response):
                    completion(response.toDomain, nil)
                case .failure(let error):
                    completion(nil, error)
                }
            }
    }
    
}
