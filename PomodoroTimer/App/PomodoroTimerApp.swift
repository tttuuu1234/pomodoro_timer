//
//  PomodoroTimerApp.swift
//  PomodoroTimer
//
//  Created by Tsubasa on 2026/09/03.
//

import SwiftUI
import SwiftData

@main
struct PomodoroTimerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PomodoroSession.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TimerView()
        }
        .modelContainer(sharedModelContainer)
    }
}
