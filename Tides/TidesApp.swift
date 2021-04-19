//
//  TidesApp.swift
//  Tides
//
//  Created by Erik Tollefsrud on 8/6/20.
//

import ComposableArchitecture
import SwiftUI
import TidesAndCurrentsClientLive

@main
struct TidesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(
                            initialState: Root.State(),
                            reducer: Root.reducer,
                            environment: Root.Environment(tidesClient: .live,
                                                        tidesAndCurrentProvider: .live,
                                                        mainQueue: DispatchQueue.main.eraseToAnyScheduler()))
            )
        }
    }
}
