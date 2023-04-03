//
//  SettingsView.swift
//  Trombone Champ Mod Manager
//
//  Created by Andrew Glaze on 2/16/23.
//

import SwiftUI

struct SettingsView: View {
    @State var tmp = ""
    @State var trmbChampUrl: String = ""
    @State var launchOptionsText = ""
    var contentView: ContentView
    
    var body: some View {
        VStack {
            HStack {
                Text("Trombone Champ Location:")
                    .onAppear() {
                        trmbChampUrl = ContentView.storedInstallPath
                    }
                TextField(URL(string: trmbChampUrl)?.path(percentEncoded: false) ?? "", text: $tmp)
                    .disabled(true)
                Spacer()
                Button("Change...") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    if panel.runModal() == .OK {
                        ContentView.storedInstallPath = panel.url!.absoluteString
                        trmbChampUrl = URL(string: ContentView.storedInstallPath)?.path(percentEncoded: false) ?? ""
                        contentView.checkBepInEx()
                    }
                    
                    
                    
                }
            }
            
            HStack {
                Text("Steam Arguments:")
                TextField(launchOptionsText, text: .constant(launchOptionsText))
                    .onAppear() {
                        if let trmbChampPath = URL(string: ContentView.storedInstallPath) {
                            launchOptionsText = "\"\(trmbChampPath.appending(path: "run_bepinex.sh").path(percentEncoded: false))\" %command%"
                        }
                    }
                Button("Copy") {
                    let clipboard = NSPasteboard.general
                    clipboard.clearContents()
                    clipboard.setString(launchOptionsText, forType: .string)
                }
            }
        }.padding()
    }
}
