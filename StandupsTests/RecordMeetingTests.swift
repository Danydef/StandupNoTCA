//
//  RecordMeetingTests.swift
//  StandupsTests
//
//  Created by Daniel Personal on 12/10/23.
//

import Dependencies
import XCTest

@testable import Standups

@MainActor
class RecordMeetingTests: XCTestCase {
    func testTimer() async {
        await withDependencies {
            $0.continuousClock = ImmediateClock()
        } operation: {
            var standup = Standup.mock
            standup.duration = .seconds(6)
            let recordModel = RecordMettingModel(
                standud: standup
            )
            let expectation = expectation(description: "onMeetingFinished")
            recordModel.onMeetingFinshed = { _ in expectation.fulfill() }
            
            await recordModel.task()
            await fulfillment(of: [expectation], timeout: 0)
            XCTAssertEqual(recordModel.secondsElapsed, 6)
            XCTAssertEqual(recordModel.dismiss, true)
        }
    }
}
