//
//  ContentView.swift
//  Trombone Champ Mod Manager
//
//  Created by Andrew Glaze on 2/2/23.
//

import SwiftUI

struct ContentView: View {
    @State var trmbChampDispPath : URL? = checkDefaultInstallPath()
    @State var isbepinexInstalled = false
    @State var errPopup = false
    @State var errMessage = ""
    @State var selectedPackage: PackagePreview?
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading) {
                if !isbepinexInstalled {
                    BepInExInstallView(trmbChampDispPath: trmbChampDispPath, contentView: self).padding()
                } else {
                    ModList(trmbChampDispPath: trmbChampDispPath, selectedPackage: $selectedPackage)
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
            checkBepInEx()
        }
        .alert(isPresented: $errPopup, content: {
            Alert(title: Text("An error occoured"), message: Text(errMessage))
        })
        .padding([.top], 0)
    }
    
    static func checkDefaultInstallPath() -> URL? {
        guard let trmbChampDefaultPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appending(path: "Steam/steamapps/common/TromboneChamp") else { return nil }
        if FileManager().fileExists(atPath: trmbChampDefaultPath.path(percentEncoded: false)) {
            return trmbChampDefaultPath
        }
        return nil
    }
    
    public func checkBepInEx() {
        guard let bepPath = trmbChampDispPath?.appending(path: "BepInEx/core/BepInEx.dll").path(percentEncoded: false) else { isbepinexInstalled = false; return}
        
        isbepinexInstalled = FileManager.default.fileExists(atPath: bepPath)
    }
    
    public func showAlert(_ errMessage: String) {
        self.errMessage = errMessage
        self.errPopup = true
    }
    
    
    
}

