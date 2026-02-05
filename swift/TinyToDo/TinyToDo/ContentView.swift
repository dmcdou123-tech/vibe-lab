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
            VStack(spacing: 16) {
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
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity, alignment: .center)
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
                            .font(.callout.weight(isSelected ? .semibold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                            .background(isSelected ? Color.accentColor.opacity(0.16) : Color(.secondarySystemBackground))
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.accentColor.opacity(0.8) : Color(.tertiarySystemFill), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                            .frame(minHeight: 34)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    isAddCategoryPresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(.secondary)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                        .frame(minHeight: 34)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 4)
        }
        .animation(.easeInOut(duration: 0.15), value: selectedCategoryId)
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
                .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .foregroundStyle(.primary)
                        .strikethrough(item.isCompleted, color: .secondary)
                        .font(.body)

                    Text(item.color.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Color dot
                Circle()
                    .fill(itemColor)
                    .frame(width: 9, height: 9)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
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
