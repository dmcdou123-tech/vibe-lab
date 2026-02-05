//
//  ManageCategoriesView.swift
//  TinyToDo
//
//  Created by David McDougal on 2/5/26.
//

import SwiftUI

struct ManageCategoriesView: View {
    @EnvironmentObject private var store: TodoStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(store.sortedCategories) { category in
                    HStack(spacing: 12) {
                        if category.isUncategorized {
                            Text(category.name)
                                .foregroundStyle(.secondary)
                        } else {
                            TextField(
                                "Category name",
                                text: Binding(
                                    get: { category.name },
                                    set: { store.renameCategory(id: category.id, to: $0) }
                                )
                            )
                        }

                        Spacer()
                    }
                    .moveDisabled(category.isUncategorized)
                    .deleteDisabled(category.isUncategorized)
                }
                .onDelete(perform: store.deleteCategories)
                .onMove(perform: store.moveCategory)
            }
            .navigationTitle("Manage Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
