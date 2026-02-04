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

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {

                // Add row
                HStack(spacing: 10) {
                    TextField("New task...", text: $newTaskTitle)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        store.add(title: newTaskTitle, color: selectedColor)
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
                    ForEach(store.items) { item in
                        TodoRow(item: item) {
                            store.toggle(item)
                        }
                    }
                    .onDelete(perform: store.delete)
                    .onMove(perform: store.move)
                }
                .listStyle(.plain)
            }
            .navigationTitle("TinyToDo")
            .toolbar {
                EditButton()
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
