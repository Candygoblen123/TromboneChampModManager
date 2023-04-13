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
    @Binding var trmbChampDispPath: String
    @State var installingPackages: [String] = []
    @State var needsUpdate: Bool = false
    @State var progress = 0.0
    @Binding var installedPackages: [String]
    
    var package: PackagePreview
    
    var body: some View {
        HStack {
            CachedAsyncImage(url: URL(string: package.image_src), content: { $0.resizable() }, placeholder: { ProgressView() })
                .frame(width: 50, height: 50)
            Text(package.package_name)
            Spacer()
            
            if installingPackages.contains(where: {$0 == package.id}) {
                ProgressView(value: progress).progressViewStyle(.circular).padding(.trailing)
                Button("Working...") {
                    Task {
                        await installPackage(package)
                    }
                }.disabled(true)
            } else if installedPackages.contains(where: {$0 == package.id}) {
                if needsUpdate {
                    Text("Update Available!")
                    Button("Update") {
                        Task {
                            await installPackage(package)
                            needsUpdate = false
                        }
                    }
                } else {
                    Text("Installed")
                        .onAppear() {
                            Task {
                                needsUpdate = await checkForUpdate()
                            }
                        }
                    Image(systemName: "checkmark.circle")
                        .padding(.horizontal)
                    Button("Reinstall") {
                        Task {
                            await installPackage(package)
                        }
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
    
    func checkForUpdate() async -> Bool {
        guard let trmbChampPath = URL(string: trmbChampDispPath) else { return false }
        let manifestPath = trmbChampPath.appending(path: "BepInEx/plugins/\(package.id)/manifest.json")
        guard let manifestData = FileManager.default.contents(atPath: manifestPath.path(percentEncoded: false)) else { return false }
        let manifest = try? JSONDecoder().decode(ThunderstoreManifest.self, from: manifestData)
        guard let fullPkg = try? await fetchFullData(package: package) else { return false }
        guard let latest_version = fullPkg.versions.first?.version_number else { return false }
        if let manifest = manifest {
            let versionCompare = manifest.version_number.compare(latest_version, options: .numeric)
            if versionCompare == .orderedAscending {
                return true
            }
        }
        
        return false
    }
    
    func installPackage(_ package: PackagePreview) async {
        do {
            let fullPkg = try await fetchFullData(package: package)
            await installPackage(fullPkg)
        } catch {
            ContentView().showAlert("Failed to download the mod metadata.")
            return
        }
    }
    
    func installDependencies(_ dependencies: [Dependency]) async {
        for dependency in dependencies {
            if dependency.package_name == "BepInExPack_TromboneChamp" { continue } // We already installed it!
            if installedPackages.contains(where: {$0 == "\(dependency.namespace)-\(dependency.package_name)"}) { continue }
            do {
                let fullDepData = try await fetchFullData(namespace: dependency.namespace, package_name: dependency.package_name, community_identifier: dependency.community_identifier)
                await installPackage(fullDepData)
            } catch {
                ContentView().showAlert("Failed to download the mod metadata.")
                return
            }
        }
    }
    
    func uninstallPackage(_ package: PackagePreview) async {
        do {
            let fullPkg = try await fetchFullData(package: package)
            await uninstallPackage(fullPkg)
        } catch {
            ContentView().showAlert("Failed to download the mod metadata.")
            return
        }
        
    }
    
    func uninstallPackage(_ package: Package) async {
        guard let trmbChampPath = URL(string: trmbChampDispPath) else { return }
        progress = 0.0
        installingPackages.append(package.id)
        print("Uninstalling \(package.namespace)-\(package.package_name)")
        
        let urlOrNil: URL
        do {
            (urlOrNil, _) = try await URLSession.shared.download(from: URL(string: package.download_url)!)
        } catch {
            ContentView().showAlert("Failed to download the mod release.")
            return
        }
        
        let modArchive = Archive(url: urlOrNil, accessMode: .read)
        modArchive?.forEach({ entry in
            var extractPath = trmbChampPath
            if entry.path.hasPrefix("plugins") {
                extractPath = trmbChampPath.appending(path: "BepInEx/plugins/\(package.id)/\(entry.path[entry.path.index(entry.path.startIndex, offsetBy: 7)..<entry.path.endIndex])")
            } else if !entry.path.hasPrefix("BepInEx") {
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
                    do {
                        try FileManager.default.removeItem(at: extractPath)
                        if extractPath.pathExtension == "dylib" {
                            try FileManager.default.removeItem(at: trmbChampPath.appending(path: "BepInEx/native/\(extractPath.lastPathComponent)"))
                        }
                    } catch {
                        ContentView().showAlert("Failed to delete \(extractPath).")
                        return
                    }
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
        guard let trmbChampPath = URL(string: trmbChampDispPath) else { return }
        progress = 0.0
        installingPackages.append(package.id)
        await installDependencies(package.dependencies)
        print("Installing \(package.namespace).\(package.package_name)")
        
        let urlOrNil: URL
        do {
            (urlOrNil, _) = try await URLSession.shared.download(for: .init(url: URL(string: package.download_url)!), delegate: SessionTaskDelegate(modListRow: self))
        } catch {
            ContentView().showAlert("Failed to download the mod release.")
            return
        }
        
        let modArchive = Archive(url: urlOrNil, accessMode: .read)
        modArchive?.forEach({ entry in
            var extractPath = trmbChampPath
            if entry.path.hasPrefix("plugins") {
                extractPath = trmbChampPath.appending(path: "BepInEx/plugins/\(package.id)/\(entry.path[entry.path.index(entry.path.startIndex, offsetBy: 7)..<entry.path.endIndex])")
            } else if !entry.path.hasPrefix("BepInEx") {
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
            
            do {
                let isDir = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
                if FileManager.default.fileExists(atPath: extractPath.path(percentEncoded: false), isDirectory: isDir) {
                    if !isDir.pointee.boolValue {
                        try FileManager.default.removeItem(at: extractPath)
                        _ = try modArchive?.extract(entry, to: extractPath)
                    }
                } else {
                    _ = try modArchive?.extract(entry, to: extractPath)
                }
                
                if extractPath.pathExtension == "dylib" {
                    if !FileManager.default.fileExists(atPath: trmbChampPath.appending(path: "BepInEx/native/").path(percentEncoded: false)) {
                        try FileManager.default.createDirectory(atPath: trmbChampPath.appending(path: "BepInEx/native/").path(percentEncoded: false), withIntermediateDirectories: true)
                    }
                    try FileManager.default.copyItem(at: extractPath, to: trmbChampPath.appending(path: "BepInEx/native/\(extractPath.lastPathComponent)"))
                    
                    let xattr = Process()
                    xattr.executableURL = URL(string: "file:///usr/bin/xattr")
                    xattr.arguments = ["-d", "com.apple.quarantine", "\(trmbChampPath.appending(path: "BepInEx/native/\(extractPath.lastPathComponent)").path(percentEncoded: false))"]
                    try xattr.run()
                    xattr.waitUntilExit()
                }
            } catch {
                ContentView().showAlert("Failed to extract the file \(extractPath). Does it already exist?")
                return
            }
        })
        
        try? FileManager.default.removeItem(at: urlOrNil)
        installingPackages.removeLast()
        
        if !installedPackages.contains(where: { $0 == package.id }) {
            installedPackages.append(package.id)
        }
    }
    
    func fetchFullData(namespace: String, package_name: String, community_identifier: String = "trombone-champ") async throws -> Package {
        let packageURL = URL(string: "https://thunderstore.io/api/experimental/frontend/c/\(community_identifier)/p/\(namespace)/\(package_name)")!
        let (data, _) = try await URLSession.shared.data(from: packageURL)
        let packageData = try JSONDecoder().decode(Package.self, from: data)
        return packageData
    }
    
    func fetchFullData(package: PackagePreview) async throws -> Package {
        return try await fetchFullData(namespace: package.namespace, package_name: package.package_name)
    }
    
    
}


class SessionTaskDelegate: NSObject, URLSessionTaskDelegate {
    var progressObservation: NSKeyValueObservation?
    var modListRow: ModListRow
    
    init(modListRow: ModListRow) {
        self.modListRow = modListRow
        super.init()
    }
    
    public func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        progressObservation = task.progress.observe(\.fractionCompleted) { progress, value in
            self.modListRow.progress = progress.fractionCompleted
        }
    }
}

