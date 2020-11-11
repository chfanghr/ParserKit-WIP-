//
// Created by 方泓睿 on 11/9/20.
//

import Foundation

public enum Error: LocalizedError {
    case exceedNestingDepthLimit
    case invalidPattern(pattern: String)

    public var errorDescription: String? {
        switch self {
        case .exceedNestingDepthLimit:
            return "nesting depth limit exceeded"
        case let .invalidPattern(pattern):
            return "\(pattern) is invalid"
        }
    }
}
