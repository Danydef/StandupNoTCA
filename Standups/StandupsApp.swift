//
//  StandupsApp.swift
//  Standups
//
//  Created by Daniel Personal on 9/10/23.
//

import SwiftUI

@main
struct StandupsApp: App {
    var body: some Scene {
        WindowGroup {
            StandupsList(model: StandupsListModel(standups: [.mock]))
        }
    }
}
