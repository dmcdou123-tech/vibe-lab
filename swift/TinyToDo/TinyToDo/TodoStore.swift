//
//  TodoStore.swift
//  TinyToDo
//
//  Created by David McDougal on 2/3/26.
//

import Foundation

final class TodoStore: ObservableObject {
    @Published private(set) var categories: [Category] = []
    @Published private(set) var items: [TodoItem] = []

    init() {
        load()
    }

    var uncategorizedId: UUID {
        Category.uncategorizedId
    }

    var sortedCategories: [Category] {
        categories.sorted { $0.sortOrder < $1.sortOrder }
    }

    func add(title: String, color: TodoColor, categoryId: UUID) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newItem = TodoItem(title: trimmed, color: color, categoryId: categoryId)
        items.insert(newItem, at: 0)
        saveItems()
    }

    func toggle(_ item: TodoItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isCompleted.toggle()
        saveItems()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveItems()
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        saveItems()
    }

    func deleteFiltered(at offsets: IndexSet, categoryId: UUID) {
        let matchingIndices = items.enumerated()
            .filter { $0.element.categoryId == categoryId }
            .map { $0.offset }
        let indicesToDelete: [Int] = offsets.compactMap { idx -> Int? in
            guard idx < matchingIndices.count else { return nil }
            return matchingIndices[idx]
        }
        let indexSet = IndexSet(indicesToDelete)
        items.remove(atOffsets: indexSet)
        saveItems()
    }

    func moveFiltered(from source: IndexSet, to destination: Int, categoryId: UUID) {
        var filtered = items.filter { $0.categoryId == categoryId }
        filtered.move(fromOffsets: source, toOffset: destination)

        var filteredIndex = 0
        for idx in items.indices {
            if items[idx].categoryId == categoryId {
                items[idx] = filtered[filteredIndex]
                filteredIndex += 1
            }
        }
        saveItems()
    }

    func items(for categoryId: UUID) -> [TodoItem] {
        items.filter { $0.categoryId == categoryId }
    }

    @discardableResult
    func addCategory(name: String) -> UUID? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let nextOrder = (categories.map { $0.sortOrder }.max() ?? 0) + 1
        let newId = UUID()
        let newCategory = Category(id: newId, name: trimmed, sortOrder: nextOrder)
        categories.append(newCategory)
        normalizeCategories()
        saveCategories()
        return newId
    }

    func renameCategory(id: UUID, to newName: String) {
        guard id != uncategorizedId else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let idx = categories.firstIndex(where: { $0.id == id }) else { return }
        categories[idx].name = trimmed
        saveCategories()
    }

    func deleteCategories(at offsets: IndexSet) {
        let sorted = sortedCategories
        let idsToDelete = offsets.compactMap { index -> UUID? in
            guard index < sorted.count else { return nil }
            let id = sorted[index].id
            return id == uncategorizedId ? nil : id
        }
        guard !idsToDelete.isEmpty else { return }
        deleteCategories(ids: idsToDelete)
    }

    func deleteCategories(ids: [UUID]) {
        let filteredIds = ids.filter { $0 != uncategorizedId }
        guard !filteredIds.isEmpty else { return }

        for idx in items.indices {
            if filteredIds.contains(items[idx].categoryId) {
                items[idx].categoryId = uncategorizedId
            }
        }
        categories.removeAll { filteredIds.contains($0.id) }
        normalizeCategories()
        saveAll()
    }

    func moveCategory(from source: IndexSet, to destination: Int) {
        var movable = sortedCategories.filter { !$0.isUncategorized }
        let adjustedSource = IndexSet(source.map { $0 - 1 }.filter { $0 >= 0 })
        var adjustedDestination = destination - 1
        if adjustedDestination < 0 { adjustedDestination = 0 }
        movable.move(fromOffsets: adjustedSource, toOffset: adjustedDestination)
        let uncategorized = sortedCategories.first { $0.isUncategorized }
        categories = ([uncategorized].compactMap { $0 }) + movable
        normalizeCategories()
        saveCategories()
    }

    private func normalizeCategories() {
        var ordered = sortedCategories
        if let uncategorizedIndex = ordered.firstIndex(where: { $0.isUncategorized }),
           uncategorizedIndex != 0 {
            let uncategorized = ordered.remove(at: uncategorizedIndex)
            ordered.insert(uncategorized, at: 0)
        }
        for idx in ordered.indices {
            ordered[idx].sortOrder = idx
        }
        categories = ordered
    }

    private func load() {
        if let loadedCategories = loadCategories() {
            categories = loadedCategories
        } else {
            categories = []
        }

        if categories.contains(where: { $0.isUncategorized }) == false {
            categories.insert(defaultUncategorized(), at: 0)
        }
        normalizeCategories()

        if let loadedItems = loadItems() {
            items = loadedItems.map { item in
                var updated = item
                if categories.contains(where: { $0.id == item.categoryId }) == false {
                    updated.categoryId = uncategorizedId
                }
                return updated
            }
        } else {
            items = [
                TodoItem(title: "GRM tests", isCompleted: false, color: .blue, categoryId: uncategorizedId),
                TodoItem(title: "Pick up groceries", isCompleted: false, color: .green, categoryId: uncategorizedId)
            ]
        }
        saveAll()
    }

    private func defaultUncategorized() -> Category {
        Category(id: uncategorizedId, name: "Uncategorized", sortOrder: 0)
    }

    private func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func categoriesFileURL() -> URL {
        documentsURL().appendingPathComponent("categories.json")
    }

    private func itemsFileURL() -> URL {
        documentsURL().appendingPathComponent("todos.json")
    }

    private func loadCategories() -> [Category]? {
        let url = categoriesFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return (try? JSONDecoder().decode([Category].self, from: data)) ?? []
    }

    private func loadItems() -> [TodoItem]? {
        let url = itemsFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return (try? JSONDecoder().decode([TodoItem].self, from: data)) ?? []
    }

    private func saveCategories() {
        let url = categoriesFileURL()
        guard let data = try? JSONEncoder().encode(categories) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    private func saveItems() {
        let url = itemsFileURL()
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    private func saveAll() {
        saveCategories()
        saveItems()
    }
}
