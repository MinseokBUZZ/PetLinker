//
//  PetLinkerProjectApp.swift
//  PetLinkerProject
//
//  Created by Minseok Shim on 2023-12-24.
//

import SwiftUI

@main
struct PetLinkerProjectApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: PetViewModel(container: persistenceController.container))
        }

    }
}

