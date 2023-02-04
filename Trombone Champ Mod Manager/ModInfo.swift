//
//  ModInfo.swift
//  Trombone Champ Mod Manager
//
//  Created by Andrew Glaze on 2/3/23.
//

import CachedAsyncImage
import SwiftUI

struct ModInfo: View {
    @Binding var selectedPackage: PackagePreview?
    @State var fullInfo: Package?
    
    var body: some View {
        if let selectedPackage = selectedPackage {
            if let fullInfo = fullInfo {
                VStack(alignment: .center) {
                    CachedAsyncImage(url: URL(string: fullInfo.image_src))
                        .padding()
                    Text(fullInfo.package_name)
                        .font(.title2)
                    Text(fullInfo.description)
                        .padding(.horizontal)
                    Divider()
                    HStack {
                        Text("Total Downloads")
                        Spacer()
                        Text("\(fullInfo.download_count)")
                    }.padding(.horizontal)
                    Divider()
                    HStack {
                        Text("Latest Version")
                        Spacer()
                        Text(fullInfo.versions.first?.version_number ?? "Unknown")
                    }.padding(.horizontal)
                    
                    Divider()
                }.onChange(of: selectedPackage) { _ in
                    self.fullInfo = nil
                }
                
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        Task {
                            fullInfo = await fetchFullData(package: selectedPackage)
                        }
                    }
            }
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
