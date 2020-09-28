import UIKit
import Combine

var cancels = Set<AnyCancellable>()

let stationsURL = URL(string: "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json?type=waterlevels")!
let aStationURL = URL(string: "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?range=24&station=1611400&product=water_level&datum=mllw&units=metric&time_zone=gmt&application=web_services&format=json")!

enum MeasuringUnits: String, Codable {
    case english = "feet"
    case metic = "meters"
}

struct TidesAndCurrentRoot: Codable {
    let count: Int
    let stations: [Station]
    //let units: MeasuringUnits?
}

struct Station: Codable {
    let id: String
    let name: String
    let lat: Double
    let lng: Double
}

enum APIError: Error {
    case urlError(URL, URLError)
    case badResponse(URL, URLResponse)
    case badResponseStatus(URL, HTTPURLResponse)
    case jsonDecodingError(URL, Error, String)
}

func validateHttpResponse(data: Data, response: URLResponse) throws -> Data {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.badResponse(stationsURL, response)
    }
    guard httpResponse.statusCode == 200 else {
        throw APIError.badResponseStatus(stationsURL, httpResponse)
    }
    return data
}

//URLSession.DataTaskPublisher(
//    request: URLRequest(url: stationsURL),
//    session: .shared)
//    .mapError { APIError.urlError(stationsURL, $0) }
//    .tryMap(validateHttpResponse)
//    .mapError { $0 as! APIError }
//    .decode(type: TidesAndCurrentRoot.self, decoder: JSONDecoder())
//    //.replaceError(with: [TidesAndCurrentRoot.Type])
//    .receive(on: DispatchQueue.main)
//    .sink { (completion) in
//        print("Completion: \(completion)")
//    } receiveValue: { (value) in
//        print("Value: \(value)")
//    }
//    .store(in: &cancels)


struct WaterLevel {
    let time: Date
    let value: String
    let sigma: String?
    let flags: String
    let qualityAssurance: String
}

extension WaterLevel: Decodable {
    
//    enum QualityAssurance: String, Codable {
//        case preliminary
//        case verified
//    }
    
//    init(time: Date, value: String, sigma: String?, flags: String, qualityAssurance: String) {
//        self.time = time
//        self.value = value
//        self.sigma = sigma
//        self.flags = flags
//        self.qualityAssurance = qualityAssurance
//    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let timeString = try container.decode(String.self, forKey: .time)
        let time = WaterLevel.formatter.date(from: timeString)!
        
        let value = try container.decode(String.self, forKey: .value)
        let sigma = try container.decode(String.self, forKey: .sigma)
        let flags = try container.decode(String.self, forKey: .flags)
        let qualityAssurance = try container.decode(String.self, forKey: .qualityAssurance)
        
        self.init(time: time, value: value, sigma: sigma, flags: flags, qualityAssurance: qualityAssurance)
    }
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    private enum CodingKeys: String, CodingKey {
        case time = "t"
        case value = "v"
        case sigma = "s"
        case flags = "f"
        case qualityAssurance = "q"
    }
}

struct WaterStation: Decodable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude = "lat"
        case longitude = "lon"
    }
    
    init(id: Int, name: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idString = try container.decode(String.self, forKey: .id)
        let id = Int(idString)!
        
        let name = try container.decode(String.self, forKey: .name)
        
        let latString = try container.decode(String.self, forKey: .latitude)
        let latitude = Double(latString)!
        
        let lonString = try container.decode(String.self, forKey: .longitude)
        let longitude = Double(lonString)!
        
        self.init(id: id, name: name, latitude: latitude, longitude: longitude)
    }
}

struct WaterLevelReading: Decodable {
    let station: WaterStation
    let data: [WaterLevel]
    
    enum CodingKeys: String, CodingKey {
        case station = "metadata"
        case data = "data"
    }
}


URLSession.DataTaskPublisher(
    request: URLRequest(url: aStationURL),
    session: .shared)
    .mapError { APIError.urlError(stationsURL, $0) }
    .tryMap(validateHttpResponse)
    .mapError { $0 as! APIError }
    .decode(type: WaterLevelReading.self, decoder: JSONDecoder())
    .receive(on: DispatchQueue.main)
    .sink { (completion) in
        print("Completion: \(completion)")
    } receiveValue: { (value) in
        print("Value: \(value)")
    }
    .store(in: &cancels)


let json = """
    {
    "metadata":
        {"id":"1611400",
        "name":"Nawiliwili",
        "lat":"21.9544",
        "lon":"-159.3561"},
    "data":
        [
            {
                "t":"2020-09-10 16:06",
                "v":"0.351", "s":"0.013",
                "f":"1,0,0,0",
                "q":"p"
            },
            {
                "t":"2020-09-10 16:12",
                "v":"0.365",
                "s":"0.019",
                "f":"1,0,0,0",
                "q":"p"
            },
            {
                "t":"2020-09-10 16:18",
                "v":"0.374", "s":"0.016",
                "f":"0,0,0,0",
                "q":"p"
            }
        ]
    }
"""

