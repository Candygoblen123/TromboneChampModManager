//
//  Trombone_Champ_Mod_ManagerApp.swift
//  Trombone Champ Mod Manager
//
//  Created by Andrew Glaze on 2/2/23.
//

import SwiftUI

@main
struct Trombone_Champ_Mod_ManagerApp: App {
    static var contentView = ContentView()
    
    var body: some Scene {
        WindowGroup {
            Trombone_Champ_Mod_ManagerApp.contentView
        }
        Settings {
            SettingsView(contentView: Trombone_Champ_Mod_ManagerApp.contentView)
        }
    }
}
