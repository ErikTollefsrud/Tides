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
    var searchText: String = ""
    var errorMessage: String = ""
    var stationsSearchResult: [Station] = []
    var filteredStations: [Station] = []
    var searchShouldShowActivityIndicator: Bool = false
}

extension AppState {
    var search: SearchState {
        get {
            return SearchState(
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
}

enum AppAction: Equatable {
    case search(SearchAction)
}

struct AppEnvironment {
    var tidesClient: TidesClient
    var tidesAndCurrentProvider: TidesAndCurrentsProvider
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

extension AppEnvironment {
  var search: SearchEnvironment { .init(provider: self.tidesAndCurrentProvider, mainQueue: self.mainQueue) }
}

let appReducer: Reducer<AppState, AppAction, AppEnvironment> =
  searchReducer.pullback(state: \.search, action: /AppAction.search, environment: \.search)

struct ContentView: View {
    let store: Store<AppState, AppAction>
    
    var body: some View {
        TabView {
            Text("Tab 1")
                .tabItem{
                    Image(systemName: "star")
                    Text("Favorites")
                }
            
            NavigationView {
              SearchView(
                store: self.store.scope(
                    state: { $0.search },
                  action: { .search($0) }
                )
              )
            }
            .tabItem {
              Image(systemName: "magnifyingglass")
              Text("Locations")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store(
                initialState: AppState(
                    errorMessage: "", stationsSearchResult: [
                        Station(id: "12345678", name: "Test 1", state: "MN", latitude: 100.00, longitude: -100.00),
                        Station(id: "87654321", name: "Test 2", state: "WI", latitude: 200.00, longitude: -200.00)
                    ]
                ),
                reducer: appReducer,
                environment: AppEnvironment(
                    tidesClient: .mock,
                    tidesAndCurrentProvider: .live,
                    mainQueue: DispatchQueue.main.eraseToAnyScheduler())
            )
        )
    }
}
