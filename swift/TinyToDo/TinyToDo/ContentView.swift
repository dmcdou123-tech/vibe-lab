//
//  ContentView.swift
//  TinyToDo
//
//  Created by David McDougal on 2/3/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: TodoStore

    @State private var newTaskTitle: String = ""
    @State private var selectedColor: TodoColor = .blue
    @State private var selectedCategoryId: UUID = Category.uncategorizedId
    @State private var isAddCategoryPresented: Bool = false
    @State private var isManageCategoriesPresented: Bool = false
    @State private var newCategoryName: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                categoryPillBar

                // Add row
                HStack(spacing: 10) {
                    TextField("New task...", text: $newTaskTitle)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        store.add(title: newTaskTitle, color: selectedColor, categoryId: selectedCategoryId)
                        newTaskTitle = ""
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // Color picker
                Picker("Color", selection: $selectedColor) {
                    ForEach(TodoColor.allCases) { c in
                        Text(c.displayName).tag(c)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // List
                List {
                    ForEach(store.items(for: selectedCategoryId)) { item in
                        TodoRow(item: item) {
                            store.toggle(item)
                        }
                    }
                    .onDelete { offsets in
                        store.deleteFiltered(at: offsets, categoryId: selectedCategoryId)
                    }
                    .onMove { source, destination in
                        store.moveFiltered(from: source, to: destination, categoryId: selectedCategoryId)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("TinyToDo")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manage") {
                        isManageCategoriesPresented = true
                    }
                }
            }
            .sheet(isPresented: $isAddCategoryPresented) {
                AddCategorySheet(
                    name: $newCategoryName,
                    onAdd: {
                        if let newId = store.addCategory(name: newCategoryName) {
                            selectedCategoryId = newId
                        }
                        newCategoryName = ""
                        isAddCategoryPresented = false
                    },
                    onCancel: {
                        newCategoryName = ""
                        isAddCategoryPresented = false
                    }
                )
            }
            .sheet(isPresented: $isManageCategoriesPresented) {
                ManageCategoriesView()
                    .environmentObject(store)
            }
            .onReceive(store.$categories) { categories in
                if categories.contains(where: { $0.id == selectedCategoryId }) == false {
                    selectedCategoryId = store.uncategorizedId
                }
            }
        }
    }

    private var categoryPillBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.sortedCategories) { category in
                    let isSelected = selectedCategoryId == category.id
                    Button {
                        selectedCategoryId = category.id
                    } label: {
                        Text(category.name)
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .foregroundStyle(isSelected ? .primary : .secondary)
                            .background(isSelected ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    isAddCategoryPresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .foregroundStyle(.secondary)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }
}

private struct AddCategorySheet: View {
    @Binding var name: String
    let onAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Category name", text: $name)
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { onAdd() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox-ish circle
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2)
                        .foregroundStyle(itemColor)

                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(itemColor)
                    }
                }
                .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .foregroundStyle(.primary)
                        .strikethrough(item.isCompleted, color: .secondary)

                    Text(item.color.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Color dot
                Circle()
                    .fill(itemColor)
                    .frame(width: 10, height: 10)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(tintBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
        .listRowSeparator(.hidden)
    }

    private var itemColor: Color {
        switch item.color {
        case .gray: return .gray
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        }
    }

    private var tintBackground: some ShapeStyle {
        itemColor.opacity(0.10)
    }
}
