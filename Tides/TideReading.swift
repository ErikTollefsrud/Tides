//
//  TideReading.swift
//  Tides
//
//  Created by Erik Tollefsrud on 3/20/21.
//

import ComposableArchitecture
import SwiftUI
import TidesAndCurrentsClient

struct TideReading {
    struct State: Equatable {
        var stationID: String
        var predictionReading: TidePredictions
    }
    
    enum Action {
        case onAppear(String)
        case predictionResponse(Result<TidePredictions, TideError>)
    }
    
    struct Environment {
        var tidesAndCurrentProvider: TidesAndCurrentsProvider
    }
}

extension TideReading {
    static let reducer = Reducer<State, Action, Environment>{ state, action, environment in
        switch action {
        case let .onAppear(stationString):
            return environment.tidesAndCurrentProvider.nextTwoDaysOfPredictions(stationString)
                .receive(on: DispatchQueue.main)
                .print()
                .catchToEffect()
                .map(Action.predictionResponse)
            
        case let .predictionResponse(.success(response)):
            state.predictionReading = response
            return .none
            
        case let .predictionResponse(.failure(error)):
            state.predictionReading = TidePredictions(predictions: [])
            return .none
        }
    }
}

struct TideReadingView: View {
    @State var station: Station
    let store: Store<TideReading.State, TideReading.Action>
    
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
                    ForEach(viewStore.predictionReading.predictions) { prediction in
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
        TideReadingView(
            station: Station.init(
                id: "8454000",
                name: "Providence",
                state: "RI",
                latitude: 41.000,
                longitude: 21.000),
            store: Store(
                initialState: TideReading.State(stationID: "8454000", predictionReading: TidePredictions(predictions: [])),
                reducer: TideReading.reducer,
                environment: TideReading.Environment(tidesAndCurrentProvider: .live))
        )
    }
}
