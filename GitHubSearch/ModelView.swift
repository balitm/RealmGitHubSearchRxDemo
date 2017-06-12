//
//  ModelView.swift
//  GitHubSearch
//
//  Created by Balázs Kilvády on 5/19/17.
//  Copyright © 2017 Realm Inc. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxRealm

final class ModelView {

    typealias Parameter = (String, String)

    let repos = BehaviorSubject<([String], [Int]?)>(value: ([], nil))
    private let bag = DisposeBag()
    private var resultBag = DisposeBag()

    init(term: Observable<String>, language: Observable<String>) {
        let input = Observable.combineLatest(term, language) { title, lang in
            return Parameter(title, lang)
        }
        .shareReplay(1)

        let longInput = input.filter { $0.0.characters.count > 2 }

        let url = longInput.throttle(0.5, scheduler: MainScheduler.instance)
            .map {
                return URL.gitHubSearch($0, language: $1)
        }

        let request = Request(urlObservable: url)

        request.response
            .subscribe(onNext: { items in
                let repos = items.map { Repo(value: $0) }

                let realm = try! Realm()
                try! realm.write {
                    realm.add(repos, update: true)
                }
            })
            .disposed(by: bag)

        // Bind repo changes.
        longInput.subscribe(onNext: { params in
            self.resultBag = DisposeBag()

            DLog("DB filter Thread on main: \(Thread.isMainThread)")
            let realm = try! Realm()
            let result = realm.objects(Repo.self)
                .filter("full_name CONTAINS[c] %@ AND language = %@", params.0, params.1)

            Observable.changeset(from: result)
                .map { ($0.0.map { $0.full_name }, $0.1?.inserted) }
                .bind(to: self.repos)
            .disposed(by: self.resultBag)
        })
            .disposed(by: bag)

        // Clear on short input.
        input
            .filter { params in
                params.0.characters.count <= 2
            }
            .subscribe(onNext: { _ in
                self.repos.on(.next(([], nil)))
            })
            .disposed(by: bag)
    }
}
