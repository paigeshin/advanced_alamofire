//
//  AlamofireAuthenticator.swift
//  AlamofireInterceptor
//
//  Created by paige on 2021/12/06.
//

import Alamofire
import Foundation

struct MyAuthenticationCredential: AuthenticationCredential {
    let accessToken: String
    let refreshToken: String
    let expiredAt: Date

    // 유효시간이 앞으로 5분 이하 남았다면 refresh가 필요하다고 true를 리턴 (false를 리턴하면 refresh 필요x)
    var requiresRefresh: Bool { Date(timeIntervalSinceNow: 60 * 5) > expiredAt }
}

class MyAuthenticator: Authenticator {
    typealias Credential = MyAuthenticationCredential

    func apply(_ credential: Credential, to urlRequest: inout URLRequest) {
        urlRequest.headers.add(.authorization(bearerToken: credential.accessToken))
        urlRequest.addValue(credential.refreshToken, forHTTPHeaderField: "refresh-token")
    }

    func didRequest(_ urlRequest: URLRequest, with response: HTTPURLResponse, failDueToAuthenticationError error: Error) -> Bool {
        return response.statusCode == 401
    }

    func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: Credential) -> Bool {
        // bearerToken의 urlRequest대해서만 refresh를 시도 (true)
        let bearerToken = HTTPHeader.authorization(bearerToken: credential.accessToken).value
        return urlRequest.headers["Authorization"] == bearerToken
    }

    func refresh(_ credential: Credential, for session: Session, completion: @escaping (Result<Credential, Error>) -> Void) {
        // TODO: refresh API 콜
        /*
         switch result {
         case .success(let response):
            completion(.success(credential))
         case .failure(let error):
            completion(.failure(error))
         }
         */
    }
}

static func predictWithAuth(request: PredictAgeRequest, completion: @escaping (_ succeed: Person?, _ failed: Error?) -> Void) {

    // AuthenticationInterceptor 적용
    let authenticator = MyAuthenticator()
    let credential = MyAuthenticationCredential(accessToken: KeychainServiceImpl.shared.accessToken ?? "",
                                                refreshToken: KeychainServiceImpl.shared.refreshToken ?? "",
                                                expiredAt: Date(timeIntervalSinceNow: 60 * 120))
    let myAuthencitationInterceptor = AuthenticationInterceptor(authenticator: authenticator,
                                                                credential: credential)

    AF.request(PredictAgeTarget.predict(request), interceptor: myAuthencitationInterceptor)
        .responseDecodable { (response: AFDataResponse<PredictAgeResponse>) in
            switch response.result {
            case .success(let response):
                completion(response.toDomain, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
}
