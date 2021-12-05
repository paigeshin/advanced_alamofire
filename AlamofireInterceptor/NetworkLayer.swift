//
//  NetworkLayer.swift
//  AlamofireInterceptor
//
//  Created by paige on 2021/12/06.
//

import Foundation
import Alamofire

// MARK: - TARGET TYPE

enum HTTPHeaderField: String {
    case authentication = "Authorization"
    case contentType = "Content-Type"
    case acceptType = "Accept"
}

enum ContentType: String {
    case json = "Application/json"
}

enum RequestParams {
    case query(_ parameter: Encodable?)
    case body(_ parameter: Encodable?)
}

extension Encodable {
    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let jsonData = try? JSONSerialization.jsonObject(with: data),
              let dictionaryData = jsonData as? [String: Any] else { return [:] }
        return dictionaryData
    }
}

protocol TargetType: URLRequestConvertible {
    var baseURL: String { get }
    var method: HTTPMethod { get }
    var path: String { get }
    var parameters: RequestParams { get }
}

extension TargetType {
    
    // URL REQUEST CONVERTIABLE
    func asURLRequest() throws -> URLRequest {
        let url = try baseURL.asURL()
        var urlRequest = try URLRequest(url: url.appendingPathComponent(path), method: method)
        // set header
        urlRequest.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
        
        switch parameters {
            // map query
        case .query(let request):
            let params = request?.toDictionary() ?? [:]
            let queryParams = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            var components = URLComponents(string: url.appendingPathComponent(path).absoluteString)
            components?.queryItems = queryParams
            urlRequest.url = components?.url
        case .body(let request):
            let params = request?.toDictionary() ?? [:]
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        }
        return urlRequest
    }
    
}

// MARK: - MODELS
struct Login {
    let name: String
}


struct LoginRequest: Encodable {
    let userName: String
    let password: String
}

struct LoginResponse: Decodable {
    let name: String
    let accessToken: String
    let refreshToken: String
}

extension LoginResponse {
    var toDomain: Login {
        return Login(name: name)
    }
}

struct UserDetailsRequest: Encodable {}
struct UserDetailsResponse: Decodable {
    var toDomain: UserDetail {
        return UserDetail()
    }
}
struct UserDetail {}

// MARK: - USE
enum LoginTarget {
    case login(LoginRequest)
    case getUserDetails(UserDetailsRequest)
}

extension LoginTarget: TargetType {
    
    var baseURL: String {
        return "https://www.apiserver.com"
    }
    
    var method: HTTPMethod {
        switch self {
        case .login:
            return .post
        case .getUserDetails:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .login:
            return "/login"
        case .getUserDetails:
            return "/details"
        }
    }
    
    var parameters: RequestParams {
        switch self {
        case .login(let request):
            return .body(request)
        case .getUserDetails(let request):
            return .body(request)
        }
    }
    
}

// MARK: - API
struct LoginAPI {

    /// 이름과 패스워드로 로그인
    static func login(request: LoginRequest, completion: @escaping (_ succeed: Login?, _ failed: Error?) -> Void) {
        AF.request(LoginTarget.login(request))
            .responseDecodable { (response: AFDataResponse<LoginResponse>) in
                switch response.result {
                case .success(let response):
                    completion(response.toDomain, nil)
                case .failure(let error):
                    completion(nil, error)
                }
            }
    }

    /// 유저 정보 조회
    static func getUserDetails(request: UserDetailsRequest, completion: @escaping (_ succeed: UserDetail?, _ failed: Error?) -> Void) {
        AF.request(LoginTarget.getUserDetails(request))
            .responseDecodable { (response: AFDataResponse<UserDetailsResponse>) in
                switch response.result {
                case .success(let response):
                    completion(response.toDomain, nil)
                case .failure(let error):
                    completion(nil, error)
                }
            }
    }
}
