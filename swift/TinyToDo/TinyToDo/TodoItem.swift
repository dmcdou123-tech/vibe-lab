//
//  TodoItem.swift
//  TinyToDo
//
//  Created by David McDougal on 2/3/26.
//
import Foundation

enum TodoColor: String, CaseIterable, Identifiable, Codable {
    case gray, red, orange, yellow, green, blue

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gray: return "Gray"
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .blue: return "Blue"
        }
    }
}

struct TodoItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var color: TodoColor
    var categoryId: UUID
    var dueDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        color: TodoColor = .blue,
        categoryId: UUID,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.color = color
        self.categoryId = categoryId
        self.dueDate = dueDate
    }
}
