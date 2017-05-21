//
//  Request.swift
//  GitHubSearch
//
//  Created by Balázs Kilvády on 5/20/17.
//  Copyright © 2017 Realm Inc. All rights reserved.
//

import Foundation
import RxSwift

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
