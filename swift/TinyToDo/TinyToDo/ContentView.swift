//
//  ContentView.swift
//  TinyToDo
//
//  Created by David McDougal on 2/3/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: TodoStore
    @Environment(\.editMode) private var editMode

    @State private var newTaskTitle: String = ""
    @State private var selectedColor: TodoColor = .blue
    @State private var selectedCategoryId: UUID = Category.uncategorizedId
    @State private var isAddCategoryPresented: Bool = false
    @State private var isManageCategoriesPresented: Bool = false
    @State private var newCategoryName: String = ""
    @State private var didSetInitialCategory: Bool = false
    @State private var newTaskDueDate: Date? = nil
    @State private var showDueDatePicker: Bool = false
    @State private var isVersionSheetPresented: Bool = false
    @State private var editingItem: TodoItem?
    @State private var editTitle: String = ""
    @State private var editDueDate: Date? = nil
    @State private var isEditPresented: Bool = false
    @State private var editColor: TodoColor = .blue

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                categoryPillBar

                // Add row
                HStack(spacing: 10) {
                    TextField("New task...", text: $newTaskTitle)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit {
                            addTaskIfPossible()
                        }

                    Button("Add") {
                        addTaskIfPossible()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                HStack(spacing: 10) {
                    Button {
                        showDueDatePicker.toggle()
                        if newTaskDueDate == nil {
                            newTaskDueDate = Date()
                        }
                    } label: {
                        if let due = newTaskDueDate {
                            Text("Due \(formattedDueDate(due))")
                        } else {
                            Text("+ Due Date")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.secondary)

                    if newTaskDueDate != nil {
                        Button("Clear") {
                            newTaskDueDate = nil
                            showDueDatePicker = false
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)

                if showDueDatePicker {
                    DatePicker(
                        "Due date",
                        selection: newDueDateBinding,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
                }

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
                    ForEach(store.displayItems(for: selectedCategoryId)) { item in
                        TodoRow(item: item) {
                            store.toggle(item)
                        } onEdit: {
                            startEditing(item)
                        }
                    }
                    .onDelete { offsets in
                        dismissKeyboard()
                        store.deleteDisplayed(at: offsets, categoryId: selectedCategoryId)
                    }
                    .onMove { source, destination in
                        dismissKeyboard()
                        store.moveDisplayed(from: source, to: destination, categoryId: selectedCategoryId)
                    }
                }
                .listStyle(.plain)
                .scrollDismissesKeyboard(.interactively)
            }
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity, alignment: .center)
            .navigationTitle("TinyToDo")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        isVersionSheetPresented = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    Button("Manage") {
                        isManageCategoriesPresented = true
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        dismissKeyboard()
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
            .sheet(isPresented: $isEditPresented) {
                NavigationView {
                    Form {
                        Section("Title") {
                            TextField("Task title", text: $editTitle)
                        }

                        Section("Due Date") {
                            DatePicker(
                                "Due",
                                selection: editDueDateBinding,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            Button("Clear Due Date") {
                                editDueDate = nil
                            }
                        }

                        Section("Color") {
                            Picker("Color", selection: $editColor) {
                                ForEach(TodoColor.allCases) { color in
                                    Text(color.displayName).tag(color)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .navigationTitle("Edit Task")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") { cancelEdit() }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") { saveEdit() }
                                .disabled(editTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $isVersionSheetPresented) {
                NavigationView {
                    Form {
                        Section("App Version") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Version \(appVersion.short)")
                                Text("Build \(appVersion.build)")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .navigationTitle("About TinyToDo")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { isVersionSheetPresented = false }
                        }
                    }
                }
            }
            .onReceive(store.$categories) { categories in
                if !didSetInitialCategory {
                    if let first = categories.first(where: { !$0.isUncategorized }) {
                        selectedCategoryId = first.id
                    } else {
                        selectedCategoryId = store.uncategorizedId
                    }
                    didSetInitialCategory = true
                } else if categories.contains(where: { $0.id == selectedCategoryId }) == false {
                    if let first = categories.first(where: { !$0.isUncategorized }) {
                        selectedCategoryId = first.id
                    } else {
                        selectedCategoryId = store.uncategorizedId
                    }
                }
            }
            .onChange(of: editMode?.wrappedValue) { mode in
                if mode?.isEditing == true {
                    dismissKeyboard()
                }
            }
            .simultaneousGesture(TapGesture().onEnded {
                dismissKeyboard()
            })
        }
    }

    private var categoryPillBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
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

                ForEach(displayCategories) { category in
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
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 4)
        }
        .animation(.easeInOut(duration: 0.15), value: selectedCategoryId)
    }

    private var displayCategories: [Category] {
        let nonUncategorized = store.sortedCategories.filter { !$0.isUncategorized }
        if let uncategorized = store.sortedCategories.first(where: { $0.isUncategorized }) {
            return nonUncategorized + [uncategorized]
        }
        return nonUncategorized
    }

    private var newDueDateBinding: Binding<Date> {
        Binding<Date>(
            get: { newTaskDueDate ?? Date() },
            set: { newTaskDueDate = $0 }
        )
    }

    private var editDueDateBinding: Binding<Date> {
        Binding<Date>(
            get: { editDueDate ?? Date() },
            set: { editDueDate = $0 }
        )
    }

    private var appVersion: (short: String, build: String) {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = info?["CFBundleVersion"] as? String ?? "Unknown"
        return (short, build)
    }

    private func startEditing(_ item: TodoItem) {
        editingItem = item
        editTitle = item.title
        editDueDate = item.dueDate
        editColor = item.color
        isEditPresented = true
    }

    private func cancelEdit() {
        isEditPresented = false
        editingItem = nil
    }

    private func saveEdit() {
        guard let target = editingItem else { return }
        store.updateItem(id: target.id, title: editTitle, dueDate: editDueDate, color: editColor)
        isEditPresented = false
        editingItem = nil
    }

    private func formattedDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func addTaskIfPossible() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.add(title: trimmed, color: selectedColor, categoryId: selectedCategoryId, dueDate: newTaskDueDate)
        newTaskTitle = ""
        newTaskDueDate = nil
        showDueDatePicker = false
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
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

                HStack(spacing: 6) {
                    Text(item.color.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let due = item.dueDate {
                        Text(dueIndicator(for: due))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(dueIndicatorColor(for: due))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(dueIndicatorColor(for: due).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Button(action: onEdit) {
                Circle()
                    .fill(itemColor)
                    .frame(width: 16, height: 16)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(tintBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
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

    private func dueIndicator(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        if date < Date() {
            return "Overdue"
        }
        return "Due \(formatter.string(from: date))"
    }

    private func dueIndicatorColor(for date: Date) -> Color {
        return date < Date() ? .red : .orange
    }
}
