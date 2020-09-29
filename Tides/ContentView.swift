//
//  ContentView.swift
//  Tides
//
//  Created by Erik Tollefsrud on 8/6/20.
//

import ComposableArchitecture
import Combine
import SwiftUI
import TidesAndCurrentsClient

struct AppState: Equatable {
    var errorMessage: String = ""
    var stations: [Station] = []
}

enum AppAction: Equatable {    
    case onAppear
    case stationsResponse(Result<[Station], TidesClient.Failure>)
}

struct AppEnvironment {
    var tidesClient: TidesClient
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    switch action {
    case .onAppear:
        return environment.tidesClient
            .stations()
            .receive(on: DispatchQueue.main)
            .catchToEffect()
            .map(AppAction.stationsResponse)
    case let .stationsResponse(.failure(response)):
        state.errorMessage = response.localizedDescription
        state.stations = []
        return .none
    case let .stationsResponse(.success(response)):
        state.stations = response
        return .none
    }
}

struct ContentView: View {
    let store: Store<AppState, AppAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView {
                List{
                    ForEach(viewStore.stations) { station in
                        NavigationLink("\(station.name), \(station.state)", destination: EmptyView())
                    }
                }
                .navigationBarTitle("Stations")
            }
            .onAppear{ viewStore.send(.onAppear) }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store(
                initialState: AppState(
                    errorMessage: "", stations: [
                        Station(id: 12345678, name: "Test 1", state: "MN", latitude: 100.00, longitude: -100.00),
                        Station(id: 87654321, name: "Test 2", state: "WI", latitude: 200.00, longitude: -200.00)
                    ]
                ),
                reducer: appReducer,
                environment: AppEnvironment(tidesClient: .mock)
            )
        )
    }
}
