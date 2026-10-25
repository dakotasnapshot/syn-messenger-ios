//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import MatrixRustSDK

enum SyndicatePermalink {
    private static let host = "synmessenger.com"
    private static let path = "/chat/"
    
    static func converting(_ matrixURL: URL) -> URL? {
        guard matrixURL.host() == "matrix.to",
              var components = URLComponents(url: matrixURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        components.scheme = "https"
        components.host = host
        components.path = path
        return components.url
    }
    
    static func user(_ userID: String) -> URL? {
        guard let matrixURL = try? URL(string: matrixToUserPermalink(userId: userID)) else {
            return nil
        }
        return converting(matrixURL)
    }
}
