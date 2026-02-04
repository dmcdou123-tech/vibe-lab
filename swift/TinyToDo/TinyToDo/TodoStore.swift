//
//  TodoStore.swift
//  TinyToDo
//
//  Created by David McDougal on 2/3/26.
//

import Foundation

final class TodoStore: ObservableObject {
    @Published var items: [TodoItem] = [
        TodoItem(title: "GRM tests", isCompleted: false, color: .blue),
        TodoItem(title: "Pick up groceries", isCompleted: false, color: .green)
    ]

    func add(title: String, color: TodoColor) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.insert(TodoItem(title: trimmed, color: color), at: 0)
    }

    func toggle(_ item: TodoItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isCompleted.toggle()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}
