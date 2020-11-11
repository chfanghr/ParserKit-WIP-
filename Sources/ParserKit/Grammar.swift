//
// Created by 方泓睿 on 11/8/20.
//

import Foundation

public class Grammar {
    public var whitespace: Rule = (" " | "\t" | "\r\n" | "\r" | "\n")*
    public var nestingDepthLimit: Int? = nil
    public var startRule: Rule! = nil

    internal var namedRules: [String: Rule] = [:]

    init() {
    }

    public init(_ creator: (Grammar) throws -> Rule) throws {
        startRule = try creator(self)
    }

    public subscript(name: String) -> Rule {
        get {
            namedRules[name]!
        }
        set {
            namedRules[name] = newValue
        }
    }
}
