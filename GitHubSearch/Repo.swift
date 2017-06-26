//
//  Repo.swift
//  GitHubSearch
//
//  Created by Marin Todorov on 5/11/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Foundation

import RealmSwift

class Repo: Object {
    @objc dynamic var id = 0
    @objc dynamic var full_name = ""
    @objc dynamic var language: String? = ""
    
    override class func primaryKey() -> String? {
        return "id"
    }
}
