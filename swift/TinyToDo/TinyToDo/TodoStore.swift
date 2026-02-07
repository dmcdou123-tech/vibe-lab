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

    func add(title: String, color: TodoColor, categoryId: UUID, dueDate: Date?) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newItem = TodoItem(title: trimmed, isCompleted: false, color: color, categoryId: categoryId, dueDate: dueDate)
        items.insert(newItem, at: 0)
        debugLog("Add item '\(trimmed)' (category: \(categoryId)) due: \(dueDate?.description ?? "nil")")
        saveItems()
    }

    func updateItem(id: UUID, title: String, dueDate: Date?) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].title = trimmed
        items[idx].dueDate = dueDate
        debugLog("Update item '\(id)' title='\(trimmed)' due='\(dueDate?.description ?? "nil")'")
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

    func deleteDisplayed(at offsets: IndexSet, categoryId: UUID) {
        let displayed = displayItems(for: categoryId)
        let idsToDelete: [UUID] = offsets.compactMap { idx -> UUID? in
            guard idx < displayed.count else { return nil }
            return displayed[idx].id
        }
        let indices = items.enumerated().compactMap { idx, element in
            idsToDelete.contains(element.id) ? idx : nil
        }
        items.remove(atOffsets: IndexSet(indices))
        saveItems()
    }

    func moveDisplayed(from source: IndexSet, to destination: Int, categoryId: UUID) {
        var displayed = displayItems(for: categoryId)
        displayed.move(fromOffsets: source, toOffset: destination)

        var queue = displayed
        var newItems: [TodoItem] = []
        for item in items {
            if item.categoryId == categoryId {
                guard let next = queue.first else { continue }
                newItems.append(next)
                queue.removeFirst()
            } else {
                newItems.append(item)
            }
        }
        items = newItems
        saveItems()
    }

    func items(for categoryId: UUID) -> [TodoItem] {
        items.filter { $0.categoryId == categoryId }
    }

    func displayItems(for categoryId: UUID) -> [TodoItem] {
        let filtered = items(for: categoryId)
        let now = Date()
        let soonCutoff = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now

        let dueSoon = filtered
            .filter { item in
                guard let due = item.dueDate else { return false }
                return due <= soonCutoff
            }
            .sorted {
                guard let a = $0.dueDate, let b = $1.dueDate else { return false }
                return a < b
            }

        let dueSoonIds = Set(dueSoon.map { $0.id })
        let remainder = filtered.filter { !dueSoonIds.contains($0.id) }
        return dueSoon + remainder
    }

    @discardableResult
    func addCategory(name: String) -> UUID? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let finalName = uniqueCategoryName(for: trimmed)
        let nextOrder = (categories.map { $0.sortOrder }.max() ?? 0) + 1
        let newId = UUID()
        let newCategory = Category(id: newId, name: finalName, sortOrder: nextOrder)
        categories.append(newCategory)
        normalizeCategories()
        saveCategories()
        debugLog("Add category '\(finalName)' id=\(newId)")
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
        if let decoded = try? JSONDecoder().decode([Category].self, from: data) {
            debugLog("Loaded categories file with \(decoded.count) entries")
            return decoded
        }
        debugLog("Failed to decode categories.json")
        return []
    }

    private func loadItems() -> [TodoItem]? {
        let url = itemsFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        if let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            debugLog("Loaded todos file with \(decoded.count) entries")
            return decoded
        }
        debugLog("Failed to decode todos.json")
        return []
    }

    private func saveCategories() {
        let url = categoriesFileURL()
        guard let data = try? JSONEncoder().encode(categories) else { return }
        try? data.write(to: url, options: [.atomic])
        debugLog("Saved categories count=\(categories.count)")
    }

    private func saveItems() {
        let url = itemsFileURL()
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: url, options: [.atomic])
        debugLog("Saved items count=\(items.count)")
    }

    private func saveAll() {
        saveCategories()
        saveItems()
    }

    private func uniqueCategoryName(for name: String) -> String {
        let lower = name.lowercased()
        let existing = categories.map { $0.name.lowercased() }
        if !existing.contains(lower) { return name }
        var suffix = 2
        while existing.contains("\(lower) \(suffix)") {
            suffix += 1
        }
        return "\(name) \(suffix)"
    }

#if DEBUG
    private func debugLog(_ message: String) {
        print("[TodoStore] \(message)")
    }
#else
    private func debugLog(_ message: String) { }
#endif
}
