//
//  TinyToDoApp.swift
//  TinyToDo
//
//  Created by David McDougal on 2/3/26.
//

import SwiftUI

@main
struct TinyToDoApp: App {
    @StateObject private var store = TodoStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
