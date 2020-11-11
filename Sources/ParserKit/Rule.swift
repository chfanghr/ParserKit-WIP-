//
// Created by 方泓睿 on 11/8/20.
//

import Foundation

public class Rule: Hashable {
    internal var matcher: Matcher

    public init(_ function: @escaping Matcher) {
        self.matcher = function
    }

    public func matches(_ parser: Parser, _ reader: Reader) throws -> Bool {
        try matcher(parser, reader)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }

    public static func ==(lhs: Rule, rhs: Rule) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    public final class Memorizing: Rule {
        public override func matches(_ parser: Parser, _ reader: Reader) throws -> Bool {
            let position = reader.position
            if let m = parser.matches[self]?[position] {
                return m
            }
            let r = try matcher(parser, reader)
            if parser.matches[self] == nil {
                parser.matches[self] = [position: r]
            } else {
                parser.matches[self]![position] = r
            }
            return r
        }
    }

    /// Wrap the rule with a nesting depth check. All rules wrapped with this check also increase the
    /// current nesting depth.
    public static func nest(_ rule: Rule) -> Rule {
        Rule { parser, reader in
            parser.nestingDepth += 1
            defer {
                parser.nestingDepth -= 1
            }

            if let nestingDepthLimit = parser.grammar.nestingDepthLimit {
                if parser.nestingDepth > nestingDepthLimit {
                    throw Error.exceedNestingDepthLimit
                }
            }
            return try rule.matches(parser, reader)
        }
    }

    public static func literal(_ string: String) -> Rule {
        Rule { parser, reader in
            let name = "literal '\(string)'"

            let pos = reader.position

            for ch in string {
                if ch != reader.read() {
                    reader.seek(pos)
                    parser.leave(name, false)
                    return false
                }
                return true
            }

            parser.leave(name, true)
            return true
        }
    }
}

