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
    case test
    case onAppear
    case stationsResponse(Result<[Station], TidesClient.Failure>)
}

struct AppEnvironment {
    var tidesClient: TidesClient
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    switch action {
    case .test:
       return .none
    case .onAppear:
        return environment.tidesClient.stations().receive(on: DispatchQueue.main).catchToEffect().map(AppAction.stationsResponse)
    case let .stationsResponse(.failure(response)):
        state.errorMessage = response.localizedDescription
        state.stations = [Station(id: 55555, name: "Error Stations", state: "MN", latitude: 0.0, longitude: 0.0)]
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
            VStack {
                Text("Tides Stations")
                List{
                    ForEach(viewStore.stations) { station in
                        Text("\(station.name), \(station.state)")
                    }
                }
            }
            .onAppear{ viewStore.send(.onAppear) }
            
        }
        .padding()
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store(
                initialState: AppState(),
                reducer: appReducer,
                environment: AppEnvironment(tidesClient: .mock)
            )
        )
    }
}
