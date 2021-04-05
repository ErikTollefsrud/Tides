//
//  TideReading.swift
//  Tides
//
//  Created by Erik Tollefsrud on 3/20/21.
//

import ComposableArchitecture
import SwiftUI
import TidesAndCurrentsClient

struct TideReadingState: Equatable {
    var stationID: String
    var predictionReading: TidePredictions?
}

enum TideReadingAction {
    case onAppear(String)
    case predictionResponse(Result<TidePredictions?, Never>)
}

struct TideReadingEnvironment {
    var tidesAndCurrentProvider: TidesAndCurrentsProvider
}

let tideReadingReducer = Reducer<TideReadingState, TideReadingAction, TideReadingEnvironment>{ state, action, environment in
    switch action {
    case let .onAppear(stationString):
        return environment.tidesAndCurrentProvider.nextTwoDaysOfPredictions(stationString)
            .receive(on: DispatchQueue.main)
            .print()
            .catchToEffect()
            .map(TideReadingAction.predictionResponse)
    case let .predictionResponse(.success(response)):
        state.predictionReading = response
        return .none
    }
}

struct TideReading: View {
    @State var station: Station
    let store: Store<TideReadingState, TideReadingAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
//                Text("Tide Level")
//                    .font(.title)
//                Text("Water Level")
//                    .font(.headline)
//                HStack {
//                    Text("Now: ")
//                    Text("3 ft")
//                }
//                .padding()
//                Text("Tides")
//                    .font(.headline)
//                HStack {
//                    Text("")
//                }
                List {
                    ForEach(viewStore.predictionReading?.predictions ?? [Tide]()) { prediction in
                        Text("\(prediction.time) - \(prediction.value) - \(prediction.type.rawValue)")
                    }
                }
            }
            .onAppear { viewStore.send(.onAppear("\(station.id)")) }
            .navigationTitle(Text("\(station.name)"))
        }
    }
}

struct TideReading_Previews: PreviewProvider {
    static var previews: some View {
        TideReading(station: Station.init(
                        id: "8454000",
                        name: "Providence",
                        state: "RI",
                        latitude: 41.000,
                        longitude: 21.000),
                    store: Store(
                        initialState: TideReadingState(stationID: "8454000"),
                        reducer: tideReadingReducer,
                        environment: TideReadingEnvironment(tidesAndCurrentProvider: .live))
        )
    }
}
