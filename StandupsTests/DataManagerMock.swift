//
//  DataManagerMock.swift
//  StandupsTests
//
//  Created by Daniel Personal on 12/10/23.
//

import Foundation
import Dependencies
@testable import Standups

extension DataManager {
    static func mock(
        initialData: Data = Data()
    ) -> DataManager {
        let data = LockIsolated(initialData)
        return DataManager(
            load: { _ in data.value },
            save: { newData, _ in data.setValue(newData) }
        )
    }
}
