//
//  NetworkClient.swift
//  PlayKit
//
//  Created by Tbxark on 26/04/2017.
//  Copyright © 2017 Tbxark. All rights reserved.
//

import Foundation
import ObjectMapper
import Alamofire
import RxSwift


public struct NetworkClientConfig {
    public let name: String
    public let schema: String
    public let host: String
    func buildURL(version: String, path: String) -> String {
        return "\(schema)\(host)\(version)\(path)"
    }
}



public protocol RequestManager {
    func configure(request: URLRequest) -> URLRequest
    func errorHandle(request: URLRequest, error: Error?)
}

func NSBuildError(code: Int, message: String) -> Error {
    return NSError(domain: "com.play.networkClient", code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

public struct ClientError {
    public static let statusCodeNotFound = 9000
    public static let dataNotFound = 9001
    public static let transformError = 9002
    public static let urlError = 9003
}

public class NetworkClient<Base: HTTPResponseModel> {
    
    public let sessionManager: Alamofire.SessionManager
    private let configure: NetworkClientConfig
    private var requestManager: RequestManager?
    private let networkQueue: OperationQueueScheduler
    
    public init(config: NetworkClientConfig) {
        configure = config
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        sessionConfig.timeoutIntervalForRequest = 15.0
        sessionConfig.timeoutIntervalForResource = 15.0
        
        let delegate = SessionDelegate()
        let policy = ServerTrustPolicyManager(policies: [config.host: .disableEvaluation])
        sessionManager = SessionManager(configuration: sessionConfig,
                                        delegate: delegate,
                                        serverTrustPolicyManager: policy)
        
        let queue = OperationQueue()
        queue.name = "com.network.\(config.name)"
        networkQueue =  OperationQueueScheduler(operationQueue: queue)
    
    }
    
    
    public func setRequestManager(_ rm: RequestManager) -> NetworkClient<Base>  {
        requestManager = rm
        return self
    }
    
    
    // MARK: - Create
    private func createURLRequest(_ method: HTTPMethod,
                          _ urlString: String,
                          parameters: [String: Any]? = nil,
                          encoding: ParameterEncoding = JSONEncoding.default,
                          headers: [String: String]? = nil)  -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        for (headerField, headerValue) in headers ?? [:] {
            request.setValue(headerValue, forHTTPHeaderField: headerField)
        }
        if let parameters = parameters,
            let encoded = try? encoding.encode(request, with: parameters) {
            request = encoded
        }
        request.timeoutInterval = 15
        return request
    }
    
    
    private func createURLRequest(type: RequestParameters) -> URLRequest? {
        let entity = type.toRequestEntity()
        let url = configure.buildURL(version: entity.version, path: entity.url)
        var parameters: [String: Any]? = nil
        if let b = entity.body {
            switch b {
            case .none: break
            case .dict(let body):
                parameters = body
            case .mapper(let body):
                parameters = body.toJSON()
            }
        }
        guard let req = createURLRequest(entity.method,
                                         url, parameters: parameters,
                                         encoding: JSONEncoding.default,
                                         headers: nil) else { return nil }
        if let m = requestManager {
            return m.configure(request: req)
        } else {
            return req
        }
    }
    
    public func modelNetRequest<T:Mappable>(_ type: RequestParameters, key: String? = nil) -> Observable<T> {
        let transform: ((Any) -> T?) = { response -> T? in
            if let k = key {
                guard let dict = response as? [String: Any],
                    let data = dict[k] else {
                        return nil
                }
                return Mapper<T>().map(JSONObject: data)
            } else {
                return Mapper<T>().map(JSONObject: response)
            }
        }
        return netRequest(type, transform: transform)
        
    }
    
    public func modelArrayNetRequest<T:Mappable>(_ type: RequestParameters, key: String? = nil) -> Observable<[T]> {
        let transform: ((Any) -> [T]?) = { response -> [T]? in
            if let k = key {
                guard let dict = response as? [String: Any],
                    let data = dict[k] else {
                        return nil
                }
                return Mapper<T>().mapArray(JSONObject: data)
            } else {
                return Mapper<T>().mapArray(JSONObject: response)
            }
        }
        return netRequest(type, transform: transform)
    }
    
    public func netRequest<T>(_ type: RequestParameters, transform: @escaping ((Any) -> (T?))) -> Observable<(T)> {
        guard let request = createURLRequest(type: type) else {
            return Observable.error(NSBuildError(code: ClientError.urlError,
                                                 message: "URL error"))
        }
        return sessionManager.rx
            .request(urlRequest: request)
            .flatMap {
                $0.rx.responseJSON()
            }
            .flatMap { (response: HTTPURLResponse, json: Any) -> Observable<T> in
                guard let model = Mapper<Base>().map(JSONObject: json) else {
                    return Observable.error(NSBuildError(code: ClientError.dataNotFound,
                                                         message: "Data Not Found"))
                }
                guard model.code == 1 else {
                    let errorReason = model.message ?? "Status Error"
                    return Observable.error(NSBuildError(code: model.code, message: errorReason))
                }
                // 没有找到有效数据
                guard let data = model.data else {
                    return Observable.error(NSBuildError(code: ClientError.dataNotFound,
                                                         message: "Missing Data"))
                }
                // 转换为 Model 失败
                guard let t = transform(data) else {
                    return Observable.error(NSBuildError(code: ClientError.transformError,
                                                         message: "Data Transform Error"))
                }
                return Observable.just(t)
            }
            .do(onError: { (error) in
                self.requestManager?.errorHandle(request: request, error: error)
            })
            .subscribeOn(networkQueue)
            .observeOn(MainScheduler.asyncInstance)
    }

    public func netDefaultRequest(_ type: RequestParameters) -> Observable<Any> {
        guard let request = createURLRequest(type: type) else {
            return Observable.error(NSBuildError(code: ClientError.urlError,
                                                 message: "URL error"))        }
        return sessionManager.rx
            .request(urlRequest: request)
            .flatMap {
                $0.rx.responseJSON()
            }
            .flatMap { (response: HTTPURLResponse, json: Any) -> Observable<Any> in
                guard let model = Mapper<Base>().map(JSONObject: json) else {
                    return Observable.error(NSBuildError(code: ClientError.dataNotFound,
                                                         message: "Data not found"))
                }
                if model.isSuccess {
                    return Observable.just(json)
                } else {
                    let errorReason = model.message ?? "Status Error"
                    let error = NSBuildError(code: response.statusCode, message: errorReason)
                    return Observable.error(error)
                }
            }
            .do(onError: { (error) in
                self.requestManager?.errorHandle(request: request, error: error)
            })
            .subscribeOn(networkQueue)
            .observeOn(MainScheduler.asyncInstance)
    }

}


public struct Reachability {
    public static var defaultReachability = NetworkReachabilityManager()
    public static var isUseCellular: Bool {
        if let r = defaultReachability {
            return r.isReachableOnWWAN
        } else if let reach = NetworkReachabilityManager() {
            defaultReachability = reach
            return reach.isReachableOnWWAN
        } else {
            return false
        }
    }
}