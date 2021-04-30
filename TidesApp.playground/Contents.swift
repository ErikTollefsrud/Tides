import UIKit
import Combine
import TidesAndCurrentsClient

let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd"
    return formatter
}()

let timeTest = formatter.string(from: Date())


print(timeTest)

print(Date().description(with: .current))


let startDate = formatter.string(from: Date())
let endDate = formatter.string(from: Date().addingTimeInterval(172_800))

print(endDate)

var cancellables = Set<AnyCancellable>()

let client = _TideClient.live

let _ = client
    .fetch48HourTidePredictions("1612340")
    .sink(receiveCompletion: { completion in
        print(completion)
    }, receiveValue: { value in
        value.predictions.map{ print($0.value)}
        //print(value.predictions)
    })
    .store(in: &cancellables)

//let _ = client
//    .fetch
//    .sink(receiveCompletion: { completion in
//        print(completion)
//    }, receiveValue: { value in
//        print(value)
//    })
//    .store(in: &cancellables)

