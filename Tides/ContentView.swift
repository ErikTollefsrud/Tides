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

struct Root {
    struct State: Equatable {
        var selectedTab = Tab.stationReading
        var selectedStation: Station?
        var searchText: String = ""
        var errorMessage: String = ""
        var stationsSearchResult: [Station] = []
        var filteredStations: [Station] = []
        var searchShouldShowActivityIndicator: Bool = false
        var predictionReading: TidePredictions?
        
        var search: Search.State {
            get {
                return Search.State(
                    query: self.searchText,
                    items: self.stationsSearchResult,
                    filteredItems: self.filteredStations,
                    shouldShowActivityIndicator: self.searchShouldShowActivityIndicator
                )
            }
            set {
                self.searchText = newValue.query
                self.stationsSearchResult = newValue.items
                self.filteredStations = newValue.filteredItems
                self.searchShouldShowActivityIndicator = newValue.shouldShowActivityIndicator
            }
        }
        
        var tideReadingState: TideReading.State {
            get {
                return TideReading.State(
                    station: self.selectedStation,
                    predictionReading: self.predictionReading ?? TidePredictions.init(predictions: []))
            }
            set {
                self.selectedStation = newValue.station
                self.predictionReading = newValue.predictionReading
            }
        }
        
        enum Tab {
            case stationReading
            case locationSearch
        }
    }
    
    enum Action: Equatable {
        case setSelectedTab(tab: Root.State.Tab)
        case search(Search.Action)
        case tideReading(TideReading.Action)
    }
    
    struct Environment {
        var tidesClient: TideClient
        var mainQueue: AnySchedulerOf<DispatchQueue>
    }
    
}

extension Root.Environment {
    var search: Search.Environment {
        .init(provider: self.tidesClient, mainQueue: self.mainQueue)
    }
    var tideReading: TideReading.Environment {
        .init(tidesAndCurrentProvider: self.tidesClient)
    }
}

extension Root {
    static let searchToStationReadingReducer = Reducer<Root.State, Search.Action, Root.Environment> { state, action, env in
        switch action {
        case let .stationTapped(station):
            state.selectedStation = station
            state.selectedTab = .stationReading
            return .none
        default:
            ()
        }
        return .none
    }
    
    static let reducer: Reducer<State, Action, Environment> = .combine(
        Search.reducer.pullback(
            state: \.search,
            action: /Action.search,
            environment: \.search
        ),
        searchToStationReadingReducer.pullback(
            state: \.self,
            action: /Action.search,
            environment: identity),
        TideReading.reducer.pullback(
            state: \.tideReadingState,
            action: /Action.tideReading,
            environment: \.tideReading),
        Reducer { state, action, environment in
            switch action {
            case .setSelectedTab(tab: let tab):
                state.selectedTab = tab
                return .none
            default:
                ()
            }
            return .none
        }
    )
}


struct ContentView: View {
    let store: Store<Root.State, Root.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            TabView(selection: viewStore.binding(
                        get: \.selectedTab,
                        send: Root.Action.setSelectedTab(tab:))
            ) {
                NavigationView {
                    TideReadingView(
                        store: self.store.scope(
                            state: { $0.tideReadingState},
                            action: { .tideReading($0)}
                        )
                    )
                }
                .tabItem{
                    Image(systemName: "mappin.and.ellipse")
                    Text("Data")
                }.tag(Root.State.Tab.stationReading)
                
                NavigationView {
                    SearchView(
                        store: self.store.scope(
                            state: { $0.search },
                            action: { .search($0) }
                        )
                    )
                }
                .tabItem {
                    Image(systemName: "map")
                    Text("Stations")
                }.tag(Root.State.Tab.locationSearch)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store(
                initialState: Root.State(
                    errorMessage: "", stationsSearchResult: [
                        Station(id: "12345678", name: "Test 1", state: "MN", latitude: 100.00, longitude: -100.00),
                        Station(id: "87654321", name: "Test 2", state: "WI", latitude: 200.00, longitude: -200.00)
                    ], predictionReading: TidePredictions.init(
                        predictions: [
                            Tide(time: Date(), value: 10.0, type: .high),
                            Tide(time: Date(), value: -5.0, type: .low)])
                ),
                reducer: Root.reducer,
                environment: Root.Environment(
                    tidesClient: .live,
                    mainQueue: DispatchQueue.main.eraseToAnyScheduler())
            )
        )
    }
}

public func identity<T>(_ t: T) -> T { t }
