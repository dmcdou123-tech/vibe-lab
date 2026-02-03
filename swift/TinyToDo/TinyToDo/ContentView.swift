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

    var body: some View {
        NavigationView {
            VStack(spacing: 10) {

                // Add row
                HStack(spacing: 10) {
                    TextField("New task…", text: $newTaskTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Add") {
                        store.add(title: newTaskTitle)
                        newTaskTitle = ""
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // List
                List {
                    ForEach(store.items) { item in
                        row(item)
                    }
                    .onDelete(perform: store.delete)
                    .onMove(perform: store.move)
                }
            }
            .navigationBarTitle("TinyToDo", displayMode: .inline)
            .navigationBarItems(trailing: EditButton())
        }
    }

    private func row(_ item: TodoItem) -> some View {
        HStack(spacing: 12) {

            Button(action: { store.toggle(item) }) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
            }
            .buttonStyle(PlainButtonStyle())

            Text(item.title)
                .font(.body)
                .strikethrough(item.isDone, color: .secondary)
                .foregroundColor(item.isDone ? .secondary : .primary)

            Spacer()
        }
        .padding(.vertical, 6)
    }
}
