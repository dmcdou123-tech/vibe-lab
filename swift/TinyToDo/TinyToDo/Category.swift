//
//  Category.swift
//  TinyToDo
//
//  Created by David McDougal on 2/5/26.
//

import Foundation

struct Category: Identifiable, Codable {
    let id: UUID
    var name: String
    var sortOrder: Int

    var isUncategorized: Bool {
        id == Category.uncategorizedId
    }

    static let uncategorizedId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
}
