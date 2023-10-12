//
//  EditStandupTests.swift
//  StandupsTests
//
//  Created by Daniel Personal on 9/10/23.
//

import XCTest

@testable import Standups

final class EditStandupTests: XCTestCase {
    func testDeletion() {
        let model = EditStandupModel(
            standup: Standup(id: Standup.ID(UUID()),
                             attendees: [
                                Attendee(id: Attendee.ID(UUID()), name: "Dani"),
                                Attendee(id: Attendee.ID(UUID()), name: "Dani Jr")
                             ]
            )
        )
        
        model.deleteAttendees(atOffsets: [1])
        
        XCTAssertEqual(model.standup.attendees.count, 1)
        XCTAssertEqual(model.standup.attendees[0].name, "Dani")
        XCTAssertEqual(model.focus, .attendee(model.standup.attendees[0].id))
    }
    
    func testAdd() {
        let model = EditStandupModel(standup: Standup(id: Standup.ID(UUID())))
        
        XCTAssertEqual(model.standup.attendees.count, 1)
        XCTAssertEqual(model.focus, .title)
        
        model.addAttendeeButtonTapped()
        XCTAssertEqual(model.standup.attendees.count, 2)
        XCTAssertEqual(model.focus, .attendee(model.standup.attendees[1].id))
    }
    
}
