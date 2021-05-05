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
        var station: Station?
        var predictionReading: TidePredictions
    }
    
    enum Action: Equatable {
        case onAppear(String?)
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
            if let stationString = stationString {
            return environment.tidesAndCurrentProvider.fetch48HourTidePredictions(stationString)
                .receive(on: DispatchQueue.main)
                .print()
                .catchToEffect()
                .map(Action.predictionResponse)
            } else {
                return .none
            }
            
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
                //Text("\(viewStore.station?.name ?? "")")
                List {
                    ForEach(viewStore.predictionReading.predictions, id: \.self) { prediction in
                        Text("\(prediction.time) - \(prediction.value) - \(prediction.type.rawValue)")
                    }
                }
            }
            .onChange(of: viewStore.station, perform: { value in
                viewStore.send(.onAppear(viewStore.state.station?.id))
            })
            .navigationTitle(Text("\(viewStore.state.station?.name ?? "")"))
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
                initialState: TideReading.State(station: Station(id: "12345678", name: "Test 1", state: "MN", latitude: 100.00, longitude: -100.00), predictionReading: TidePredictions(predictions: [])),
                reducer: TideReading.reducer,
                environment: TideReading.Environment(tidesAndCurrentProvider: .live))
        )
    }
}
