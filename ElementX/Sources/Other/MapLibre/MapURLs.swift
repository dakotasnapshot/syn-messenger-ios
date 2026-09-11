//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation

extension MapTilerConfiguration: MapTilerURLBuilderProtocol {
    /// For interactive MGLMap components
    func interactiveMapURL(for style: MapTilerStyle) -> URL? {
        if usesBundledMapStyle {
            return Bundle.main.url(forResource: bundledStyleName(for: style), withExtension: "json")
        }
        
        var url = styleURL(for: style)
        url?.appendPathComponent("style.json", conformingTo: .json)
        return url
    }
    
    /// Used in the timeline where a full MGLMapView loading is unwanted
    func staticMapTileImageURL(for style: MapTilerStyle,
                               coordinates: CLLocationCoordinate2D,
                               zoomLevel: Double,
                               size: CGSize,
                               attribution: MapTilerAttributionPlacement) -> URL? {
        guard !usesBundledMapStyle else { return nil }
        
        var url = styleURL(for: style)
        url?.appendPathComponent(String(format: "static/%f,%f,%f/%dx%d@2x.png",
                                        coordinates.longitude,
                                        coordinates.latitude,
                                        zoomLevel,
                                        Int(size.width),
                                        Int(size.height)),
                                 conformingTo: .png)
        url?.append(queryItems: [.init(name: "attribution", value: attribution.rawValue)])
        return url
    }
}

// MARK: - Private

private extension MapTilerConfiguration {
    var usesBundledMapStyle: Bool {
        baseURL.scheme == "syn-map"
    }
    
    func bundledStyleName(for style: MapTilerStyle) -> String {
        switch style {
        case .light: lightStyleID
        case .dark: darkStyleID
        }
    }
    
    func styleURL(for style: MapTilerStyle) -> URL? {
        guard let apiKey else { return nil }
        
        var url: URL = baseURL
        url.appendPathComponent(styleID(for: style), conformingTo: .item)
        if !apiKey.isEmpty {
            url.append(queryItems: [URLQueryItem(name: "key", value: apiKey)])
        }
        return url
    }
    
    func styleID(for style: MapTilerStyle) -> String {
        switch style {
        case .light: lightStyleID
        case .dark: darkStyleID
        }
    }
}
