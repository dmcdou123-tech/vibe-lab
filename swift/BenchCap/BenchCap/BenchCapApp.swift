//
//  BenchCapApp.swift
//  BenchCap
//
//  Created by David McDougal on 2/6/26.
//

import SwiftUI
import SwiftData

@main
struct BenchCapApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Subject.self,
            Instrument.self,
            InstrumentInstance.self,
            TimeNode.self,
            FieldEntry.self,
            CorrectionNote.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            print("SwiftData store load failed: \(error). The local store may be incompatible after schema changes.")
#if DEBUG
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupport.appendingPathComponent(Bundle.main.bundleIdentifier ?? "BenchCap", isDirectory: true)
                do {
                    if FileManager.default.fileExists(atPath: storeURL.path) {
                        try FileManager.default.removeItem(at: storeURL)
                        print("DEBUG: Removed SwiftData store at \(storeURL.path), retrying container creation.")
                    }
                } catch {
                    print("DEBUG: Failed to remove SwiftData store at \(storeURL.path): \(error)")
                }
            }
            do {
                return try ModelContainer(for: schema, configurations: configuration)
            } catch {
                fatalError("SwiftData container failed after reset: \(error)")
            }
#else
            fatalError("SwiftData container failed to load: \(error)")
#endif
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
