import ComposableArchitecture
import Foundation
import TidesAndCurrentsClient
import UIKit

// MARK: State

public struct SearchState: Equatable {
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

public enum SearchAction: Equatable {
  case textChanged(String)
  case performSearch
  case resultChanged([Station]?)
  case showActivityIndicator
  case downloadAllStations
  case recieveAllStations([Station]?)
}

// MARK: Environment

public struct SearchEnvironment {
  var provider: TidesAndCurrentsProvider
  var mainQueue: AnySchedulerOf<DispatchQueue>
  
  public init(provider: TidesAndCurrentsProvider, mainQueue: AnySchedulerOf<DispatchQueue>) {
    self.provider = provider
    self.mainQueue = mainQueue
  }
}

// MARK: Reducer

public let searchReducer = Reducer<SearchState, SearchAction, SearchEnvironment> { state, action, environment in
  struct PerformSeachId: Hashable {}
  struct MultiSearchId: Hashable {}
  struct SearchActiveId: Hashable {}
  struct DownloadInProgressId: Hashable {}
  
  switch action {
  case let .textChanged(query):
    state.query = query
    guard !query.isEmpty else {
      return .merge(
        Effect(value: .resultChanged(nil)),
        .cancel(id: PerformSeachId()),
        .cancel(id: MultiSearchId())
      )
    }
    
    let downloadAndSearchEffect = Effect<SearchAction, Never>.concatenate(
      Effect(value: SearchAction.downloadAllStations),
      Effect(value: SearchAction.performSearch)
        .debounce(
          id: PerformSeachId(),
          for: .milliseconds(300),
          scheduler: environment.mainQueue
        )
    )
    
    let searchEffect = Effect<SearchAction, Never>(value: SearchAction.performSearch)
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
    state.filteredItems = items ?? []
    return .none

  case .performSearch:
    let query = state.query
    print("Searching: \(query)")
    let activateSearchEffect = Effect<SearchAction, Never>(value: .showActivityIndicator)
      .delay(for: .milliseconds(300), scheduler: environment.mainQueue)
      .eraseToEffect()
      .cancellable(id: SearchActiveId(), cancelInFlight: true)
    
    let cachedSearchEffect = Effect.concatenate(
      state.items
        .publisher
        .filter { $0.name.contains(query) || $0.state.contains(query) }
        .collect()
        .eraseToEffect()
        .map(SearchAction.resultChanged)
        .cancellable(id:MultiSearchId(), cancelInFlight: true),
      .cancel(id: SearchActiveId())
    )
    return .merge(activateSearchEffect, cachedSearchEffect)
    
  case .showActivityIndicator:
    state.shouldShowActivityIndicator = true
    return .none
    
  case .downloadAllStations:
    print("downloading...")
    return environment.provider
      .tidePredictionStations()
      .receive(on: environment.mainQueue)
      .eraseToEffect()
      .map(SearchAction.recieveAllStations)
      .cancellable(id: DownloadInProgressId(), cancelInFlight: false)
    
  case let .recieveAllStations(stations):
    print("recieving...")
    if let stations = stations {
      state.items = stations
    }
    return .none
  }
}
