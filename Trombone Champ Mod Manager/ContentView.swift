//
//  ContentView.swift
//  Trombone Champ Mod Manager
//
//  Created by Andrew Glaze on 2/2/23.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("TrmbChampInstallPath") static var storedInstallPath: String = ""
    @AppStorage("SteamArgCheck") static var steamArgsSet: Bool = true
    @State var isbepinexInstalled = false
    @State var errPopup = false
    @State var errMessage = ""
    @State var selectedPackage: PackagePreview?
    @State static var needChangeArguments: Bool = false
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading) {
                if !isbepinexInstalled {
                    BepInExInstallView(trmbChampDispPath: ContentView.$storedInstallPath, contentView: self).padding()
                } else {
                    ModList(trmbChampDispPath: ContentView.$storedInstallPath, selectedPackage: $selectedPackage)
                }
                
            }
            .layoutPriority(1)
            .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
            
            
            if isbepinexInstalled {
                VStack(alignment: .center) {
                    if selectedPackage == nil {
                        Text("Select a mod to see info about it here!")
                    } else {
                        ModInfo(selectedPackage: $selectedPackage)
                    }
                }
                .frame(minWidth: 200, maxWidth: .infinity, maxHeight: .infinity)
            }
            
        }
        .frame(minWidth: 600, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
        .onAppear() {
            checkDefaultInstallPath()
            checkBepInEx()
        }
        .alert(isPresented: $errPopup, content: {
            Alert(title: Text("An error occoured"), message: Text(errMessage))
        })
        .padding([.top], 0)
    }
    
    func checkDefaultInstallPath() {
//        if ContentView.storedInstallPath != "" {
//            if let trmbChampDefaultPath = URL(string: ContentView.storedInstallPath) {
//                if FileManager().fileExists(atPath: trmbChampDefaultPath.path(percentEncoded: false)) {
//                    trmbChampDispPath = trmbChampDefaultPath
//                }
//            }
//        }
        if ContentView.storedInstallPath == "" {
            guard let trmbChampDefaultPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first?.appending(path: "Steam/steamapps/common/TromboneChamp") else { return }
            if FileManager().fileExists(atPath: trmbChampDefaultPath.path(percentEncoded: false)) {
                ContentView.storedInstallPath = trmbChampDefaultPath.absoluteString
            }
        }
    }
    
    public func checkBepInEx() {
        guard let trmbChampPath = URL(string: ContentView.storedInstallPath) else {isbepinexInstalled = false; return}
        let bepPath = trmbChampPath.appending(path: "BepInEx/core/BepInEx.dll").path(percentEncoded: false)
        ContentView.storedInstallPath = trmbChampPath.absoluteString
        if ContentView.steamArgsSet {
            isbepinexInstalled = FileManager.default.fileExists(atPath: bepPath)
        }
    }
    
    public func showAlert(_ errMessage: String) {
        self.errMessage = errMessage
        self.errPopup = true
    }
    
    
    
}

