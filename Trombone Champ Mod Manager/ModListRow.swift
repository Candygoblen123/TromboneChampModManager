//
//  ModListRow.swift
//  Trombone Champ Mod Manager
//
//  Created by Andrew Glaze on 2/3/23.
//

import SwiftUI
import CachedAsyncImage
import ZIPFoundation

struct ModListRow: View {
    @State var trmbChampDispPath: URL?
    @State var installingPackages: [String] = []
    @AppStorage("installedPackages") var installedPackages: [String] = []
    var package: PackagePreview
    
    var body: some View {
        HStack {
            CachedAsyncImage(url: URL(string: package.image_src), content: { $0.resizable() }, placeholder: { ProgressView() })
                .frame(width: 50, height: 50)
            Text(package.package_name)
            Spacer()
            if installingPackages.contains([package.id]) {
                ProgressView().padding(.trailing)
                Button("Working...") {
                    Task {
                        await installPackage(package)
                    }
                }.disabled(true)
            } else if installedPackages.contains([package.id]) {
                Text("Installed")
                    .tint(.green)
                Image(systemName: "checkmark.circle")
                    .padding(.horizontal)
                    .tint(.green)
                Button("Reinstall") {
                    Task {
                        await installPackage(package)
                    }
                }
                Button("Uninstall") {
                    Task {
                        await uninstallPackage(package)
                    }
                }
            } else {
                Button("Install") {
                    Task {
                        await installPackage(package)
                    }
                }
            }
        }
    }
    
    
    func installPackage(_ package: PackagePreview) async {
        let fullPkg = await fetchFullData(package: package)
        await installPackage(fullPkg)
    }
    
    func installDependencies(_ dependencies: [Dependency]) async {
        for dependency in dependencies {
            if dependency.package_name == "BepInExPack_TromboneChamp" { continue } // We already installed it!
            let fullDepData = await fetchFullData(namespace: dependency.namespace, package_name: dependency.package_name, community_identifier: dependency.community_identifier)
            await installPackage(fullDepData)
        }
    }
    
    func uninstallPackage(_ package: PackagePreview) async {
        let fullPkg = await fetchFullData(package: package)
        await uninstallPackage(fullPkg)
    }
    
    func uninstallPackage(_ package: Package) async {
        guard let trmbChampPath = trmbChampDispPath else { return }
        installingPackages.append(package.id)
        print("Uninstalling \(package.namespace)-\(package.package_name)")
        
        let urlOrNil: URL
        do {
            (urlOrNil, _) = try await URLSession.shared.download(from: URL(string: package.download_url)!)
        } catch {
            ContentView().showAlert("Failed to download the mod release. Do you have access to Github?")
            return
        }
        
        let modArchive = Archive(url: urlOrNil, accessMode: .read)
        modArchive?.forEach({ entry in
            var extractPath = trmbChampPath
            if !entry.path.hasPrefix("BepInEx") {
                extractPath = trmbChampPath.appending(path: "BepInEx/plugins/\(package.id)/\(entry.path)")
            } else if entry.path.hasPrefix("BepInEx/config") {
                extractPath = trmbChampPath.appending(path: entry.path)
            } else {
                var pathComponents = URL(string: entry.path)!.pathComponents
                if pathComponents.count >= 2 {
                    pathComponents.insert(package.id, at: 2)
                    
                    var finalURL = trmbChampPath
                    for component in pathComponents {
                        finalURL.append(path: component)
                    }
                    extractPath = finalURL
                } else {
                    extractPath = trmbChampPath.appending(path: entry.path)
                }
            }
            
            let isDir = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
            if FileManager.default.fileExists(atPath: extractPath.path(percentEncoded: false), isDirectory: isDir) {
                if !isDir.pointee.boolValue && !entry.path.hasPrefix("BepInEx/config") {
                    try! FileManager.default.removeItem(at: extractPath)
                }
            }
        })
        
        try? FileManager.default.removeItem(at: urlOrNil)
        try? FileManager.default.removeItem(at: trmbChampPath.appending(path: "BepInEx/plugins/\(package.id)"))
        installingPackages.removeLast()
        
        if let packageIndex = installedPackages.firstIndex(of: package.id) {
            installedPackages.remove(at: packageIndex)
        }
    }
    
    func installPackage(_ package: Package) async {
        guard let trmbChampPath = trmbChampDispPath else { return }
        installingPackages.append(package.id)
        await installDependencies(package.dependencies)
        print("Installing \(package.namespace).\(package.package_name)")
        
        let urlOrNil: URL
        do {
            (urlOrNil, _) = try await URLSession.shared.download(from: URL(string: package.download_url)!)
        } catch {
            ContentView().showAlert("Failed to download the mod release. Do you have access to Github?")
            return
        }
        
        let modArchive = Archive(url: urlOrNil, accessMode: .read)
        modArchive?.forEach({ entry in
            var extractPath = trmbChampPath
            if !entry.path.hasPrefix("BepInEx") {
                extractPath = trmbChampPath.appending(path: "BepInEx/plugins/\(package.id)/\(entry.path)")
            } else if entry.path.hasPrefix("BepInEx/config") {
                extractPath = trmbChampPath.appending(path: entry.path)
            } else {
                var pathComponents = URL(string: entry.path)!.pathComponents
                if pathComponents.count >= 2 {
                    pathComponents.insert(package.id, at: 2)
                    
                    var finalURL = trmbChampPath
                    for component in pathComponents {
                        finalURL.append(path: component)
                    }
                    extractPath = finalURL
                } else {
                    extractPath = trmbChampPath.appending(path: entry.path)
                }
                
            }
            
            let isDir = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
            if FileManager.default.fileExists(atPath: extractPath.path(percentEncoded: false), isDirectory: isDir) {
                if !isDir.pointee.boolValue {
                    try! FileManager.default.removeItem(at: extractPath)
                    _ = try! modArchive?.extract(entry, to: extractPath)
                }
            } else {
                _ = try! modArchive?.extract(entry, to: extractPath)
            }
        })
        
        try? FileManager.default.removeItem(at: urlOrNil)
        installingPackages.removeLast()
        
        if !installedPackages.contains([package.id]) {
            installedPackages.append(package.id)
        }
    }
    
    func fetchFullData(namespace: String, package_name: String, community_identifier: String = "trombone-champ") async -> Package {
        let packageURL = URL(string: "https://thunderstore.io/api/experimental/frontend/c/\(community_identifier)/p/\(namespace)/\(package_name)")!
        let (data, _) = try! await URLSession.shared.data(from: packageURL)
        let packageData = try! JSONDecoder().decode(Package.self, from: data)
        return packageData
    }
    
    func fetchFullData(package: PackagePreview) async -> Package {
        return await fetchFullData(namespace: package.namespace, package_name: package.package_name)
    }
}

