//
//  Request.swift
//  GitHubSearch
//
//  Created by Balázs Kilvády on 5/20/17.
//  Copyright © 2017 kil-dev. All rights reserved.
//

import Foundation
import RxSwift
import TRON
import SwiftyJSON

/// Provide factory method for urls to GitHub's search API
extension URL {
    static func gitHubSearch(_ query: String, language: String) -> URL {
        let query = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        return URL(string: "https://api.github.com/search/repositories?q=\(query)+language:\(language)+in:name")!
    }
}

struct API {}

extension API {
    struct GHError: JSONDecodable {

        init(json: JSON) throws {
        }
    }

    struct Github: JSONDecodable {
        static let tron = TRON(baseURL: "https://api.github.com/")

        let items: [Any]

        init(json: JSON) throws {
            guard let items = json["items"].arrayObject else {
                self.items = []
                return
            }
            self.items = items
        }

        static func search(_ query: String, language: String) -> Observable<Github> {
            let request: APIRequest<Github, GHError> = tron.request("search/repositories?q=\(query)+language:\(language)+in:name")
            request.method = .get
            DLog("search url: \(request.urlBuilder.url(forPath: "search/repositories?q=\(query)+language:\(language)+in:name"))")
            let null = try! Github(json: JSON.null)
            return request.rxResult()//.catchErrorJustReturn(null)
        }
     }
}

struct Request {
    let response: Observable<[Any]>

    init(urlObservable: Observable<URL>) {
        self.response = urlObservable
            .flatMapLatest { url -> Observable<Any> in
                return URLSession.shared.rx.json(url: url).catchErrorJustReturn([])
            }
            .map { json -> [Any] in
                guard let json = json as? [String: Any],
                    let items = json["items"] as? [Any] else { return [] }
                return items
        }
    }
}
