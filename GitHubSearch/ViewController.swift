//
//  ViewController.swift
//  GitHubSearch
//
//  Created by Marin Todorov on 5/11/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxRealm

/// Provide factory method for urls to GitHub's search API
extension URL {
    static func gitHubSearch(_ query: String, language: String) -> URL {
        let query = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        return URL(string: "https://api.github.com/search/repositories?q=\(query)+language:\(language)+in:name")!
    }
}

/// Observable emitting the currently selected segment title
extension UISegmentedControl {
    public var rx_selected: Observable<String?> {
        return rx.value.map(titleForSegment)
    }
}

final class ViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var query: UITextField!
    @IBOutlet weak var language: UISegmentedControl!

    // MARK: - Properties
    fileprivate let bag = DisposeBag()

    fileprivate var repos = [Repo]() //Results<Repo>?
    var modelView: ModelView!

    // MARK: - Bind UI
    override func viewDidLoad() {
        super.viewDidLoad()

        // Activate search.
        query.becomeFirstResponder()

        // Define input.
        let text = query.rx.text.map { $0 ?? "" }
        let lang = language.rx_selected.map { $0! }
        modelView = ModelView(term: text, language: lang)

        // Bind results to table.
        modelView.repos
            .subscribe(onNext: { [weak self] repos, changes in
                DLog("DB changed Thread on main: \(Thread.isMainThread)")
                self?._bindTableView(repos, changes)
            })
            .disposed(by: bag)
    }

    /// Bind results to table view.
    private func _bindTableView(_ repos: [Repo], _ changes: RealmChangeset?) {
        DLog("Repos changed, set: \(changes).")
        guard repos.count != 0 || self.repos.count != 0 else { return }

        self.repos = repos

        if let changes = changes {
            tableView.beginUpdates()
            tableView.insertRows(at: changes.inserted.map { IndexPath(row: $0, section: 0) },
                                 with: .automatic)
            tableView.endUpdates()
        } else {
            tableView.reloadData()
        }
    }
}

// MARK: - UITableView data source

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let repo = repos[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "RepoCell")!
        cell.textLabel!.text = repo.full_name
        return cell
    }
}

// MARK: - UITableView delegate

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        assert(section == 0)
        return 0.5
    }
}
