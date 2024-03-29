//
//  BepInExInstallView.swift
//  Trombone Champ Mod Manager
//
//  Created by Andrew Glaze on 2/2/23.
//

import SwiftUI
import ZIPFoundation

struct BepInExInstallView: View {
    @Binding var trmbChampDispPath: String
    @State var trmbChampUrl: String = ""
    @State var tmp = ""
    @State var progressText = "Waiting to start..."
    @State var installComplete: Bool = false
    @AppStorage("DidInstall") var didInstall: Bool = false
    @State var launchOptionsText = ""
    var contentView: ContentView
    var pathChanged: Bool = false
    
    var body: some View {
        Text("Welcome to Trombone Champ Mod Manager!").font(.title)
            .onAppear() {
                trmbChampUrl = URL(string: trmbChampDispPath)?.path(percentEncoded: false) ?? ""
                installComplete = didInstall
            }
        if !installComplete {
            
            if (trmbChampDispPath == "") {
                Text("We couldn't autmoatically find your installation of Trombone Champ. Please use the change button to select it manually.")
            }
            HStack {
                Text("Trombone Champ Location:")
                TextField(trmbChampUrl, text: $tmp)
                    .disabled(true)
                Spacer()
                Button("Change...") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    if panel.runModal() == .OK {
                        trmbChampDispPath = panel.url!.absoluteString
                        trmbChampUrl = URL(string: trmbChampDispPath)?.path(percentEncoded: false) ?? ""
                        contentView.checkBepInEx()
                    }
                    
                    
                    
                }
            }
            .padding(.bottom)
            
            Text("Let's quickly install BepInEx so that you can install mods!").font(.title3)
            
            HStack {
                Text(progressText)
                Spacer()
                Button("Install BepInEx!") {
                    Task {
                        await installBepInEx()
                        
                    }
                }
            }
        } else {
            VStack(alignment: .leading) {
                Text("There are just a couple more steps before you can install mods:")
                Text("1. Open Steam")
                Text("2. Right click on Trombone Champ in your games list")
                Text("3. Click on properties")
                Text("4. Click on General in the left sidebar")
                Text("5. Copy and paste the Text in the box below into the Launch Options field.")
                Text("6. Launch Trombone Champ at least once")
                
            }.onAppear() {
                ContentView.steamArgsSet = false
            }
            
            HStack {
                TextField(launchOptionsText, text: .constant(launchOptionsText))
                    .onAppear() {
                        if let trmbChampPath = URL(string: trmbChampDispPath) {
                            launchOptionsText = "\"\(trmbChampPath.appending(path: "run_bepinex.sh").path(percentEncoded: false))\" %command%"
                        }
                    }
                Button("Copy") {
                    let clipboard = NSPasteboard.general
                    clipboard.clearContents()
                    clipboard.setString(launchOptionsText, forType: .string)
                }
            }
            
            Button("I've Finished!") {
                ContentView.steamArgsSet = true
                didInstall = false
                contentView.checkBepInEx()
            }
        }
    }
    
    
    func installBepInEx() async {
        guard trmbChampDispPath != "", let trmbChampPath = URL(string: trmbChampDispPath) else {
            progressText = "Waiting to start..."
            contentView.showAlert("You didn't tell us where your trombone champ install is!")
            return
        }
        
        
        // Check if the trombone champ path is an actual trombone champ install
        if !FileManager.default.fileExists(atPath: trmbChampPath.appending(path: "Trombone Champ.app/Contents/MacOS/TromboneChamp").path(percentEncoded: false)) {
            progressText = "Error..."
            contentView.showAlert("The location you provided doesn't seem to have Trombone Champ.")
            return
        }
        
        progressText = "Downloading BepInEx..."
        // Download the thing
        let request = URLRequest(url: URL(string: "https://github.com/BepInEx/BepInEx/releases/download/v5.4.21/BepInEx_unix_5.4.21.0.zip")!)
        let task = URLSession.shared.downloadTask(with: request) {url, responce, err in
            if err != nil {
                progressText = "Error..."
                contentView.showAlert("Failed to download the BepInEx release. Do you have access to Github?")
                return
            }
            
            let bepinexURL = trmbChampPath.appending(path: "BepInEx.zip")
            do {
                if FileManager.default.fileExists(atPath: bepinexURL.path(percentEncoded: false)) {
                    try FileManager.default.removeItem(at: bepinexURL)
                }
            } catch {
                progressText = "Error..."
                contentView.showAlert("Failed to delete \(bepinexURL.path(percentEncoded: false))")
                return
            }
            
            do {
                try FileManager.default.moveItem(at: url!, to: bepinexURL)
            } catch {
                progressText = "Error..."
                contentView.showAlert("Failed to write to \(bepinexURL.path(percentEncoded: false)).")
                return
            }
            
            progressText = "Extracting BepInEx..."
            
            
            let bepinexZip = Archive(url: bepinexURL, accessMode: .read)
            
            bepinexZip?.forEach({ entry in
                let extractedFilePath = trmbChampPath.appending(path: entry.path)
                if FileManager.default.fileExists(atPath: extractedFilePath.path(percentEncoded: false)) {
                    try? FileManager.default.removeItem(at: extractedFilePath)
                }
                do {
                    _ = try bepinexZip?.extract(entry, to: extractedFilePath)
                } catch {
                    progressText = "Error..."
                    contentView.showAlert("Failed to extract \(extractedFilePath.path(percentEncoded: false)) from BepInEx.zip. Try deleting the file and installing again.")
                    return
                }
                
            })
            
            progressText = "Finishing up..."
            try? FileManager.default.removeItem(at: bepinexURL)
            if let scriptUrl = Bundle.main.url(forResource: "run_bepinex", withExtension: "sh") {
                try? FileManager.default.removeItem(at: trmbChampPath.appending(path: "run_bepinex.sh"))
                try? FileManager.default.copyItem(at: scriptUrl, to: trmbChampPath.appending(path: "run_bepinex.sh"))
            }
            do {
                var perms = try FileManager.default.attributesOfItem(atPath: trmbChampPath.appending(path: "run_bepinex.sh").path(percentEncoded: false))
                
                perms[.posixPermissions] = 493
                
                try FileManager.default.setAttributes(perms, ofItemAtPath: trmbChampPath.appending(path: "run_bepinex.sh").path(percentEncoded: false))
            } catch {
                progressText = "Error..."
                contentView.showAlert("Failed to set execute permissions for the file run_bepinex.sh")
                return
            }
            
            launchOptionsText = "\"\(trmbChampPath.appending(path: "run_bepinex.sh").path(percentEncoded: false))\" %command%"
            installComplete = true
            didInstall = true
            
            progressText = "Done!"
            
        }
        task.resume()
        
    }
}

