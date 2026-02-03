//
//  TodoItem.swift
//  TinyToDo
//
//  Created by David McDougal on 2/3/26.
//
import Foundation

struct TodoItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var isDone: Bool = false
    var createdAt: Date = Date()
}
