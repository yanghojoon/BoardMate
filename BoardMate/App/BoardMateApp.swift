//
//  BoardMateApp.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import SwiftUI

@main
struct BoardMateApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session = BoardMateSession()

    var body: some Scene {
        WindowGroup {
            ContentView(session: session)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    session.setActive(phase == .active)
                }
                .task(id: scenePhase) {
                    guard scenePhase == .active else { return }
                    while !Task.isCancelled {
                        session.refreshTime()
                        do {
                            try await Task.sleep(for: .milliseconds(250))
                        } catch {
                            return
                        }
                    }
                }
        }
    }
}
