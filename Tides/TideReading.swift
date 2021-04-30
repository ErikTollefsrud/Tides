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
        case predictionResponse(Result<TidePredictions, NOAA_APIClientError>)
    }
    
    struct Environment {
        var tidesAndCurrentProvider: TideClient
    }
}

extension TideReading {
    static let reducer = Reducer<State, Action, Environment>{ state, action, environment in
        switch action {
        case let .onAppear(stationString):
            return environment.tidesAndCurrentProvider.fetch48HourTidePredictions(stationString)
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
    let store: Store<TideReading.State, TideReading.Action>
    
    var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack {
                List {
                    ForEach(viewStore.predictionReading.predictions, id: \.self) { prediction in
                        Text("\(prediction.time) - \(prediction.value) - \(prediction.type.rawValue)")
                    }
                }
            }
            .onAppear { viewStore.send(.onAppear(viewStore.state.stationID)) }
        }
    }
}

//List {
//    ForEach(viewStore.predictionReading.predictions) { prediction in
//        Text("\(prediction.time) - \(prediction.value) - \(prediction.type.rawValue)")
//    }
//}

//.onAppear { viewStore.send(.onAppear("\(station.id)")) }
//.navigationTitle(Text("\(station.name)"))

struct TideReading_Previews: PreviewProvider {
    static var previews: some View {
        TideReadingView(
            store: Store(
                initialState: TideReading.State(stationID: "8454000", predictionReading: TidePredictions(predictions: [])),
                reducer: TideReading.reducer,
                environment: TideReading.Environment(tidesAndCurrentProvider: .live))
        )
    }
}
