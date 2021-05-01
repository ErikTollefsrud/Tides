import ComposableArchitecture
import Foundation
import TidesAndCurrentsClient
import UIKit

// MARK: State

public struct Search {
    public struct State: Equatable {
        public var query: String
        public var items: [Station]
        public var filteredItems: [Station]
        public var shouldShowActivityIndicator: Bool
        public var shouldSearchLocally: Bool = false
        
        public init(
            query: String = "",
            items: [Station] = [],
            filteredItems: [Station] = [],
            shouldShowActivityIndicator: Bool = false
        ) {
            self.query = query
            self.items = items
            self.shouldShowActivityIndicator = shouldShowActivityIndicator
            self.filteredItems = filteredItems
        }
    }
    
    // MARK: Action
    
    public enum Action: Equatable {
        case textChanged(String)
        case performSearch
        case resultChanged([Station])
        case showActivityIndicator
        case downloadAllStations
        case recieveAllStations(Result<StationResponse, NOAA_APIClientError>)
        case stationTapped(Station)
    }
    
    // MARK: Environment
    
    public struct Environment {
        var provider: TideClient
        var mainQueue: AnySchedulerOf<DispatchQueue>
        
        public init(provider: TideClient, mainQueue: AnySchedulerOf<DispatchQueue>) {
            self.provider = provider
            self.mainQueue = mainQueue
        }
    }
}

// MARK: Reducer
public extension Search {
    static let reducer = Reducer<State, Action, Environment> { state, action, environment in
        struct PerformSeachId: Hashable {}
        struct MultiSearchId: Hashable {}
        struct SearchActiveId: Hashable {}
        struct DownloadInProgressId: Hashable {}
        
        switch action {
        case let .textChanged(query):
            state.query = query
            guard !query.isEmpty else {
                return .merge(
                    Effect(value: .resultChanged([])),
                    .cancel(id: PerformSeachId()),
                    .cancel(id: MultiSearchId())
                )
            }
            
            let downloadAndSearchEffect = Effect<Action, Never>.concatenate(
                Effect(value: .downloadAllStations),
                Effect(value: .performSearch)
                    .debounce(
                        id: PerformSeachId(),
                        for: .milliseconds(300),
                        scheduler: environment.mainQueue
                    )
            )
            
            let searchEffect = Effect<Action, Never>(value: Action.performSearch)
                .debounce(
                    id: PerformSeachId(),
                    for: .milliseconds(300),
                    scheduler: environment.mainQueue
                )
            return state.items.isEmpty
                ? downloadAndSearchEffect
                : searchEffect
            
        case let .resultChanged(items):
            state.shouldShowActivityIndicator = false
            state.filteredItems = items
            return .none
            
        case .performSearch:
            let query = state.query
            //print("Searching: \(query)")
            let activateSearchEffect = Effect<Action, Never>(value: .showActivityIndicator)
                .delay(for: .milliseconds(300), scheduler: environment.mainQueue)
                .eraseToEffect()
                .cancellable(id: SearchActiveId(), cancelInFlight: true)
            
            let cachedSearchEffect = Effect.concatenate(
                state.items
                    .publisher
                    .filter { $0.name.contains(query) || $0.state.contains(query) }
                    .collect()
                    .eraseToEffect()
                    .map(Action.resultChanged)
                    .cancellable(id:MultiSearchId(), cancelInFlight: true),
                .cancel(id: SearchActiveId())
            )
            return .merge(activateSearchEffect, cachedSearchEffect)
            
        case .showActivityIndicator:
            state.shouldShowActivityIndicator = true
            return .none
            
        case .downloadAllStations:
            //print("downloading...")
            return environment.provider
                .fetchTidePredictionStations()
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(Action.recieveAllStations)
                .cancellable(id: DownloadInProgressId(), cancelInFlight: false)
            
        case let .recieveAllStations(.success(stationResponse)):
            //print("stations: \(stationResponse.stations.count)")
            state.items = stationResponse.stations
            return .none
            
        case let .recieveAllStations(.failure(error)):
            state.items = []
            return .none
            
        case let .stationTapped(station):
            return .none
        }
    }
}
