import ComposableArchitecture
import Foundation
//import MoviehubTypes
import TidesAndCurrentsClient
import SwiftUI

public struct SearchView: View {
  let store: Store<SearchState, SearchAction>

  public init(store: Store<SearchState, SearchAction>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        SearchBar(
          title: "Station Name...",
          searchText: viewStore.binding(
            get: { $0.query },
            send: { .textChanged($0) }
          ),
          isSearching: viewStore.shouldShowActivityIndicator
        )

        List(viewStore.filteredItems) { item in
//            NavigationLink(destination: Text(String(describing: item))) {
            SearchResultRow(station: item)
//          }
        }
        .listStyle(PlainListStyle())
        .animation(.default)
        .resignKeyboardOnDragGesture()
      }
      .navigationBarTitle("Search")
    }
  }
}

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.windows
            .filter{$0.isKeyWindow}
            .first?
            .endEditing(force)
    }
}

extension View {
    func resignKeyboardOnDragGesture() -> some View {
        return modifier(ResignKeyboardOnDragGesture())
    }
}

struct ResignKeyboardOnDragGesture: ViewModifier {
    var gesture = DragGesture().onChanged { _ in
        UIApplication.shared.endEditing(true)
    }
    func body(content: Content) -> some View {
        content.gesture(gesture)
    }
}

// MARK: Previews

struct SearchView_Previews: PreviewProvider {
  static let searchResult = [Station(id: "12345678", name: "Test 1", state: "MN", latitude: 100.00, longitude: -100.00),
                             Station(id: "87654321", name: "Test 2", state: "WI", latitude: 200.00, longitude: -200.00)]

  static var previews: some View {
    let store = Store<SearchState, SearchAction>(
      initialState: SearchState(
        query: "Test",
        items: searchResult,
        filteredItems: searchResult,
        shouldShowActivityIndicator: false),
      reducer: searchReducer,
      environment: .init(
        provider: .live,
        mainQueue: DispatchQueue.main.eraseToAnyScheduler()
      )
    )
    return NavigationView {
      SearchView(store: store)
    }
    .environment(\.locale, Locale(identifier: "sv_SE"))
  }
}
