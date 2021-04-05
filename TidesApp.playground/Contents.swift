import UIKit
import Combine
//import TidesAndCurrentsClient

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

let testString = "TEST String"
testString.localizedCapitalized
