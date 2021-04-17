import SwiftUI
import TidesAndCurrentsClient

struct SearchResultRow: View {
  let station: Station
  var body: some View {
    HStack {
      Image(systemName: "mappin.and.ellipse")
      if station.state.isEmpty {
        Text(station.name)
      } else {
        VStack(alignment: .leading){
          Text("\(station.name)")
          Text("\(stateDictionary[station.state] ?? "")")
            .font(.caption2)
        }
      }
    }
    .padding([.leading, .trailing])
    .listRowInsets(.init())
  }
}

struct SearchResultRow_Previews: PreviewProvider {
  static let previewItems = [
    Station.init(
      id: "1",
      name: "My Station",
      state: "MN",
      latitude: 10.0,
      longitude: 10.0),
    
    Station.init(
      id: "2",
      name: "My Second Station",
      state: "WI",
      latitude: 5.0,
      longitude: 5.0),
  ]
  
  static var previews: some View {
    Group{
      ForEach(previewItems) { item in
        SearchResultRow(station: item)
        .previewLayout(.sizeThatFits)
          .previewDisplayName("\(item.name)")
      }
    }
  }
}


let stateDictionary: [String : String] = [
  "AK" : "Alaska",
  "AL" : "Alabama",
  "AR" : "Arkansas",
  "AS" : "American Samoa",
  "AZ" : "Arizona",
  "CA" : "California",
  "CO" : "Colorado",
  "CT" : "Connecticut",
  "DC" : "District of Columbia",
  "DE" : "Delaware",
  "FL" : "Florida",
  "GA" : "Georgia",
  "GU" : "Guam",
  "HI" : "Hawaii",
  "IA" : "Iowa",
  "ID" : "Idaho",
  "IL" : "Illinois",
  "IN" : "Indiana",
  "KS" : "Kansas",
  "KY" : "Kentucky",
  "LA" : "Louisiana",
  "MA" : "Massachusetts",
  "MD" : "Maryland",
  "ME" : "Maine",
  "MI" : "Michigan",
  "MN" : "Minnesota",
  "MO" : "Missouri",
  "MS" : "Mississippi",
  "MT" : "Montana",
  "NC" : "North Carolina",
  "ND" : " North Dakota",
  "NE" : "Nebraska",
  "NH" : "New Hampshire",
  "NJ" : "New Jersey",
  "NM" : "New Mexico",
  "NV" : "Nevada",
  "NY" : "New York",
  "OH" : "Ohio",
  "OK" : "Oklahoma",
  "OR" : "Oregon",
  "PA" : "Pennsylvania",
  "PR" : "Puerto Rico",
  "RI" : "Rhode Island",
  "SC" : "South Carolina",
  "SD" : "South Dakota",
  "TN" : "Tennessee",
  "TX" : "Texas",
  "UT" : "Utah",
  "VA" : "Virginia",
  "VI" : "Virgin Islands",
  "VT" : "Vermont",
  "WA" : "Washington",
  "WI" : "Wisconsin",
  "WV" : "West Virginia",
  "WY" : "Wyoming"]
