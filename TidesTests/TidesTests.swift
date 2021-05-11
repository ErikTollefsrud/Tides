//
//  TidesTests.swift
//  TidesTests
//
//  Created by Erik Tollefsrud on 8/6/20.
//

import XCTest
@testable import Tides
import TidesAndCurrentsClient
import TidesAndCurrentsClientLive
import Combine
import ComposableArchitecture
import SwiftUI
import Commons

class TidesTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    // will fail ...
    // experiment with failures
    func test_fetchStationsBad() throws {
        let receivedCompletion = XCTestExpectation(description: "receivedCompletion")
        let api = APIRequest.fetchStationsBad(.tidePredictions)
        let publisher = api
            .dataTaskPublisher()
            .tryMap { try api.decode(StationResponse.self, from: $0) }
            .mapError { $0.apiError }
            .eraseToAnyPublisher()

        _ = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    Commons.log("receiveCompletion: OK")
                    break
                case .failure(let error):
                    Commons.log("receiveCompletion, error: \(error.localizedDescription)")
                }
                receivedCompletion.fulfill()
            },
            receiveValue: { input in
                Commons.log("success: \(input)")
            })
        
        let result = XCTWaiter.wait(for: [receivedCompletion], timeout: 10.0)
        Commons.log("waited enough ...")

        if result != .completed {
            XCTFail("Timed out waiting for the effect to complete")
        } else {
        }
    }
    
    // will work
    // just call one api and show us the data ...
    func test_fetchStationsHappy() throws {
        let receivedCompletion = XCTestExpectation(description: "receivedCompletion")
        let publisher = TideClient.live
            .fetchTidePredictionStations()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        Commons.log("receiveCompletion: OK")
                        break
                    case .failure(let error):
                        Commons.log("receiveCompletion, error: \(error.localizedDescription)")
                    }
                    receivedCompletion.fulfill()
                },
                receiveValue: { stationResponse in
                    Commons.log("---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ")
                    Commons.log("success got: \(stationResponse.count) stations")
                    var stations = stationResponse.stations
                    
                    stations.removeAll { $0.id.isEmpty }
                    stations.forEach { station in
                        Commons.log("fetch: station: \(station.name) state: \(station.state)")
                        try? self.test_fetch48HourTidePredictions(stationID: station.id)
                    }
                    receivedCompletion.fulfill()
                })

        let result = XCTWaiter.wait(for: [receivedCompletion], timeout: 6000.0)
        Commons.log("waited enough ...")

        if result != .completed {
            XCTFail("Timed out waiting for the effect to complete")
        } else {
        }
    }

    func test_fetch48HourTidePredictions(stationID: String) throws {
        let receivedCompletion = XCTestExpectation(description: "receivedCompletion")
        let publisher = TideClient.live
            .fetch48HourTidePredictions(stationID)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        Commons.log("receiveCompletion: OK")
                        break
                    case .failure(let error):
                        Commons.log("receiveCompletion, error: \(error.localizedDescription)")
                    }
                    receivedCompletion.fulfill()
                },
                receiveValue: { tidePredictions in
                    Commons.log("success got: \(tidePredictions.tides.count) tides")
                    receivedCompletion.fulfill()
                })
        
        let result = XCTWaiter.wait(for: [receivedCompletion], timeout: 600)
        Commons.log("waited enough ...")
        
        if result != .completed {
            XCTFail("Timed out waiting for the effect to complete")
        } else {
        }
    }

    func test_fetch48HourTidePredictions() throws {
        try? test_fetch48HourTidePredictions(stationID: "1610367")
    }

    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
