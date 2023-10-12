//
//  StandupListTests.swift
//  StandupsTests
//
//  Created by Daniel Personal on 12/10/23.
//

import Dependencies
import XCTest

@testable import Standups

@MainActor
class StandupListTests: XCTestCase {
    override func setUp() async throws {
        try? FileManager.default.removeItem(at: .documentsDirectory.appending(component: "standups.json"))
    }
    
    func testPersistence() {
        let mainQueue = DispatchQueue.test
        withDependencies {
            $0.mainQueue = mainQueue.eraseToAnyScheduler()
        } operation: {
            let listModel = StandupsListModel()
            
            XCTAssertEqual(listModel.standups.count, 0)
            
            listModel.addStandupButtonTapped()
            listModel.confirmAddStandupButtonTapped()
            XCTAssertEqual(listModel.standups.count, 1)
            
            mainQueue.run()
            
            let nextLauchListModel = StandupsListModel()
            XCTAssertEqual(nextLauchListModel.standups.count, 1)
        }
    }
}
