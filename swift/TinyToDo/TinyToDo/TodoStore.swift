//
//  TodoStore.swift
//  TinyToDo
//
//  Created by David McDougal on 2/3/26.
//

import Foundation

final class TodoStore: ObservableObject {
    @Published var items: [TodoItem] = [] {
        didSet { save() }
    }

    private let key = "TinyToDo.items.v1"

    init() {
        load()
        if items.isEmpty {
            // Seed a couple so you see something immediately
            items = [
                TodoItem(title: "Email Belinda"),
                TodoItem(title: "Pick up groceries")
            ]
        }
    }

    func add(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.insert(TodoItem(title: trimmed), at: 0)
    }

    func toggle(_ item: TodoItem) {
        guard let idx = items.firstIndex(of: item) else { return }
        items[idx].isDone.toggle()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            // If save fails, we silently ignore for now.
            // (Could add logging later.)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        do {
            items = try JSONDecoder().decode([TodoItem].self, from: data)
        } catch {
            items = []
        }
    }
}
