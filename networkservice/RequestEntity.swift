//
//  RequestEntity.swift
//  PlayKit
//
//  Created by Tbxark on 26/04/2017.
//  Copyright © 2017 Tbxark. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

public typealias HTTPMethod = Alamofire.HTTPMethod

public enum RequestBody {
    case none
    case dict(body: [String: Any])
    case mapper(body: Mappable)
}


public struct PLRequestEntity {
    
    // 请求类型
    public let method: HTTPMethod
    // 请求路径
    public let url: String
    // 请求版本
    public var version: String = "v1/"
    // 请求体
    public var body: RequestBody?
    
    
    public init(GET aUrl: String) {
        method = HTTPMethod.get
        url = aUrl
    }
    
    public init(POST aUrl: String) {
        method = HTTPMethod.post
        url = aUrl
    }
    
    public init(DELETE aUrl: String) {
        method = HTTPMethod.delete
        url = aUrl
    }
    
    public init(_ aMethod: HTTPMethod, _ aUrl: String) {
        method = aMethod
        url = aUrl
    }
    
    
    public func changeVersion(_ ver: String) -> PLRequestEntity {
        var data = self
        data.version = ver
        return data
    }
    
    public func addMapBody(_ map: Mappable) -> PLRequestEntity {
        var data = self
        data.body = RequestBody.mapper(body: map)
        return data
    }
    
    public func addDictBody(_ dict: [String: Any]) -> PLRequestEntity {
        var data = self
        data.body = RequestBody.dict(body: dict)
        return data
    }
}


public protocol RequestParameters {
    func toRequestEntity() -> PLRequestEntity
}

extension RequestParameters {
    public var request: PLRequestEntity {
        return self.toRequestEntity()
    }
}

public protocol HTTPResponseModel: Mappable {
    var code: Int { get }
    var message: String? { get }
    var data: Any? { get }
    var isSuccess: Bool { get }
}
