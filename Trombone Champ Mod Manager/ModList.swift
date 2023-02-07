//
//  ModList.swift
//  Trombone Champ Mod Manager
//
//  Created by Andrew Glaze on 2/2/23.
//

import SwiftUI
import ZIPFoundation
import CachedAsyncImage

struct ModList: View {
    @State var communityPackageList: [PackagePreview]?
    @State var trmbChampDispPath: URL?
    @Binding var selectedPackage: PackagePreview?
    @State var installedPackages: [String] = []
    
    var body: some View {
        if let packages = communityPackageList {
            List(packages, id: \.self, selection: $selectedPackage) { package in
                ModListRow(trmbChampDispPath: trmbChampDispPath, installedPackages: $installedPackages, package: package)
            }
        } else {
            ProgressView()
                .onAppear() {
                    Task {
                        installedPackages = getInstalledPackages()
                        await fetchPackages()
                    }
                }
        }
        Button("Launch Trombone Champ!") {
            let steam = URL(string: "steam://rungameid/1059990")!
            NSWorkspace.shared.open(steam)
            
        }
        .frame(maxWidth: .infinity, alignment: .bottomTrailing)
        .padding(.top, 3)
        .padding([.horizontal, .bottom])
    }
    
    func fetchPackages() async {
        let communityUrl = URL(string: "https://thunderstore.io/api/experimental/frontend/c/trombone-champ/packages/")!
        let (data, _) = try! await URLSession.shared.data(from: communityUrl)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let communityPackages = try! decoder.decode(ThunderstorePackages.self, from: data)
        
        communityPackageList = communityPackages.packages.filter({ $0.package_name != "BepInExPack_TromboneChamp" && $0.package_name != "r2modman" })
    }
    
    func getInstalledPackages() -> [String] {
        guard let trmbChampPath = trmbChampDispPath else { return [] }
        
        let contents = try? FileManager.default.contentsOfDirectory(atPath: trmbChampPath.appending(path: "BepInEx/plugins/").path(percentEncoded: false))
        
        return contents ?? []
    }
}

extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
