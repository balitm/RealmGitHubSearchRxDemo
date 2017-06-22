//
//  Request.swift
//  GitHubSearch
//
//  Created by Balázs Kilvády on 5/20/17.
//  Copyright © 2017 kil-dev. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import RxSwiftExt
import TRON
import SwiftyJSON

/// Provide factory method for urls to GitHub's search API
//extension URL {
//    static func gitHubSearch(_ query: String, language: String) -> URL {
//        let query = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
//        let url = URL(string: "https://api.github.com/search/repositories?q=\(query)+language:\(language)+in:name")!
//        DLog("url: \(url.absoluteString)")
//        return url
//    }
//}

private struct Encoding: ParameterEncoding {
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()

        guard let parameters = parameters else { return urlRequest }

        if let _ = HTTPMethod(rawValue: urlRequest.httpMethod ?? "GET") {
            guard let url = urlRequest.url else {
                throw AFError.parameterEncodingFailed(reason: .missingURL)
            }

            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
                let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                urlComponents.percentEncodedQuery = percentEncodedQuery
                urlRequest.url = urlComponents.url
            }
        } else {
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            }

            urlRequest.httpBody = query(parameters).data(using: .utf8, allowLossyConversion: false)
        }

        return urlRequest
    }

    private func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []

        for key in parameters.keys.sorted(by: <) {
            var value: String
            if let str = parameters[key]! as? String {
                value = str
            } else {
                value = String(describing: parameters[key]!)
            }
            components.append((key, value))
        }
        #if swift(>=4.0)
            return components.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
        #else
            return components.map { "\($0)=\($1)" }.joined(separator: "&")
        #endif
    }
}

struct API {}

extension API {
    struct GHError: JSONDecodable {

        init(json: JSON) throws {
        }
    }

    struct Github: JSONDecodable {
        static let tron: TRON = {
            let logger = NetworkLoggerPlugin()
            logger.logSuccess = false
            logger.logFailures = true
            return TRON(baseURL: "https://api.github.com/", plugins: [logger])
        }()

        let items: [Any]

        init(json: JSON) throws {
            guard let items = json["items"].arrayObject else {
                self.items = []
                return
            }
            self.items = items
        }

        static func search(_ query: String, language: String) -> Observable<Event<Github>> {
            let request: APIRequest<Github, GHError> = tron.request("search/repositories")
            request.method = .get
            request.parameters = ["q": "\(query)+language:\(language)+in:name"]
            request.parameterEncoding = Encoding()
            return request.rxResult().materialize()
        }
     }
}
