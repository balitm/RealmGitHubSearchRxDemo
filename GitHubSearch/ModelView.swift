//
//  ModelView.swift
//  GitHubSearch
//
//  Created by Balázs Kilvády on 5/19/17.
//  Copyright © 2017 kil-dev. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxRealm
import RxDataSources

struct RepoData {
    var identity: Int
    var name: String
}

extension RepoData: IdentifiableType, Equatable {
    typealias Identity = Int
}

func ==(lhs: RepoData, rhs: RepoData) -> Bool {
    return lhs.identity == rhs.identity
}

struct SectionRepoData {
    var identity: RepoData.Identity
    var items: [Item]
}

extension SectionRepoData: AnimatableSectionModelType {
    typealias Item = RepoData
    typealias Identity = RepoData.Identity

    init(original: SectionRepoData, items: [Item]) {
        self = original
        self.items = items
    }
}

final class ModelView {

    typealias Parameter = (String, String)

    let repos = BehaviorSubject<([SectionRepoData])>(value: [])
    private let bag = DisposeBag()
    private var resultBag = DisposeBag()

    init(term: Observable<String>, language: Observable<String>) {
        let input = Observable.combineLatest(term, language) { title, lang in
            return Parameter(title, lang)
        }
        .shareReplay(1)

        let longInput = input
            .filter { $0.0.characters.count > 2 }

        let events = longInput.throttle(0.5, scheduler: MainScheduler.instance)
            .debug()
            .flatMapLatest { params -> Observable<Event<API.Github>> in
                DLog("params mapped to search: \(params.0), \(params.1)")
                return API.Github.search(params.0, language: params.1)
            }
            .shareReplay(1)

        events.elements()
            .subscribe(onNext: { (hit: API.Github) in
                let repos = hit.items.map { Repo(value: $0) }

                let realm = try! Realm()
                try! realm.write {
                    realm.add(repos, update: true)
                }
            }, onError: { error in
                DLog("Error: \(error)")
            }, onCompleted: {
                DLog("Completed")
            }, onDisposed: {
                DLog("Disposed")
            })
            .disposed(by: bag)

        events.errors().subscribe(onNext: { (error: Error) in
                DLog("Error: \(error)")
            }, onError: { error in
                DLog("Error: \(error)")
            }, onCompleted: {
                DLog("Completed")
            }, onDisposed: {
                DLog("Disposed")
            })
            .disposed(by: bag)

        // Bind repo changes.
        longInput.subscribe(onNext: { params in
            self.resultBag = DisposeBag()

            DLog("DB filter Thread on main: \(Thread.isMainThread)")
            let realm = try! Realm()
            let result = realm.objects(Repo.self)
                .filter("full_name CONTAINS[c] %@ AND language = %@", params.0, params.1)

            DLog("Starting changset observable for \"full_name CONTAINS[c] \(params.0) AND language = \(params.1)\".")
            Observable.changeset(from: result)
                .map { (objs: AnyRealmCollection<Repo>, _: RealmChangeset?) -> [SectionRepoData] in
                    DLog("repo objs: \(objs.count)")
                    let section = SectionRepoData(identity: 0,
                                                  items: objs.map { RepoData(identity: $0.id, name: $0.full_name) })
                    return [section]
                }
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
                self.repos.on(.next([]))
            })
            .disposed(by: bag)
    }
}
