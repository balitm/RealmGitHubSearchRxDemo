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
import RxDataSources

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

    var modelView: ModelView!
    let dataSource = RxTableViewSectionedReloadDataSource<SectionRepoData>()
    
    // MARK: - Bind UI
    override func viewDidLoad() {
        super.viewDidLoad()

        // Activate search.
        query.becomeFirstResponder()

        // Define input.
        let text = query.rx.text.map { $0 ?? "" }
        let lang = language.rx_selected.map { $0! }
        modelView = ModelView(term: text, language: lang)

        // Setup data source.
        dataSource.configureCell = { ds, tv, ip, item in
            let cell = tv.dequeueReusableCell(withIdentifier: "RepoCell", for: ip)
            cell.textLabel?.text = item.name
            return cell
        }

        // Bind results to table.
        modelView.repos.asObservable()
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
    }
}

// MARK: - UITableView delegate

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        assert(section == 0)
        return 0.5
    }
}
