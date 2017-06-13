//
//  Request.swift
//  GitHubSearch
//
//  Created by Balázs Kilvády on 5/20/17.
//  Copyright © 2017 kil-dev. All rights reserved.
//

import Foundation
import RxSwift

/// Provide factory method for urls to GitHub's search API
extension URL {
    static func gitHubSearch(_ query: String, language: String) -> URL {
        let query = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        return URL(string: "https://api.github.com/search/repositories?q=\(query)+language:\(language)+in:name")!
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
