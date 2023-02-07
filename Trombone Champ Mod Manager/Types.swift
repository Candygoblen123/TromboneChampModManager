//
//  Types.swift
//  Trombone Champ Mod Manager
//
//  Created by Andrew Glaze on 2/2/23.
//

import Foundation

struct GithubRelease: Codable {
    let assets: [GithubAssets]
}

struct GithubAssets: Codable {
    let name: String
    var browser_download_url: String
}

struct ThunderstorePackages: Codable {
    let categories: [ThunderstoreCategory]
    let community_name: String
    let has_more_pages: Bool
    let packages: [PackagePreview]
}

struct PackagePreview: Codable, Identifiable, Hashable {
    let categories: [ThunderstoreCategory]
    let description: String
    let download_count: Int
    let image_src: String
    let is_nsfw: Bool
    let is_pinned: Bool
    let last_updated: String
    let namespace: String
    let package_name: String
    let rating_score: Int
    let team_name: String
    var id: String { "\(namespace)-\(package_name)" }
}

struct Package: Codable {
    let dependencies: [Dependency]
    let dependency_string: String
    let description: String
    let download_count: Int
    let download_url: String
    let image_src: String
    let install_url: String
    let last_updated: String
    let markdown: String
    let namespace: String
    let package_name: String
    let rating_score: Int
    let team_name: String
    let versions: [PackageVersion]
    let website: String
    var id: String { "\(namespace)-\(package_name)" }
}

struct Dependency: Codable {
    let community_identifier: String
    let package_name: String
    let namespace: String
    let version_number: String
    let description: String
    let community_name: String
    let image_src: String
}

struct ThunderstoreManifest: Codable {
    let name: String
    let version_number: String
}

struct PackageVersion: Codable {
    let date_created: String
    let download_count: Int
    let download_url: String
    let install_url: String
    let version_number: String
}

struct ThunderstoreCategory: Codable, Hashable {
    let name: String
    let slug: String
}
