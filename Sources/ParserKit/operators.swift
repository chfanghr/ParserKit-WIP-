//
//  operators.swift
//  ParserKit
//
//  Created by 方泓睿 on 11/8/20.
//

import Foundation
import Regex

/// EOF operator
postfix operator *!*

public postfix func *!*(rule: Rule) -> Rule {
    Rule {
        try rule.matches($0, $1) && $1.eof()
    }
}

/// Call a named rule. Could cause a cycle, be careful!
prefix operator ^

public prefix func ^(name: String) -> Rule {
    Rule.Memorizing {
        let ruleName = "named rule: \(name)"
        $0.enter(ruleName)
        let result = try $0.grammar[name].matcher($0, $1)
        $0.leave(ruleName, result)
        return result
    }
}

/// Match a regexp
prefix operator %!

public prefix func %!(pattern: String) -> Rule {
    Rule { parser, reader in
        let regexpName = "regex '\(pattern)'"
        parser.enter(regexpName)

        let pos = reader.position

        var found = true
        let remainder = reader.remainder()

        do {
            guard let regex = pattern.r else {
                throw Error.invalidPattern(pattern: pattern)
            }
            if let match = regex.findFirst(in: remainder) {
                let res = remainder[match.range]
                reader.seek(pos + res.count)
                parser.leave(regexpName, true)
                return true
            }
        } catch {
            found = false
        }

        if (!found) {
            reader.seek(pos)
            parser.leave(regexpName, false)
        }

        return false
    }
}

/// Match a literal string
prefix operator %

public prefix func %(lit: String) -> Rule {
    Rule.literal(lit)
}

/// Match a range of characters, for example: `"0"-"9"`
public func -(left: Character, right: Character) -> Rule {
    Rule { parser, reader in
        parser.enter("range [\(left)-\(right)]")

        let pos = reader.position

        let lower = String(left)
        let upper = String(right)

        let ch = String(reader.read())
        let found = (lower <= ch && ch <= upper)
        parser.leave("range \t\t\(ch)", found)

        if (!found) {
            reader.seek(pos)
        }

        return found
    }
}

/// Invert match
postfix operator +

public postfix func +(rule: Rule) -> Rule {
    Rule { parser, reader in
        let pos = reader.position
        var found = false
        var flag: Bool

        let name = "one or more"

        parser.enter(name)

        repeat {
            flag = try rule.matches(parser, reader)
            found = flag || found
        } while (flag)

        if (!found) {
            reader.seek(pos)
        }
        parser.leave(name, found)
        return found
    }
}

public postfix func +(lit: String) -> Rule {
    Rule.literal(lit)+
}

/// Match zero or more
postfix operator *

public postfix func *(rule: Rule) -> Rule {
    Rule { parser, reader in
        var flag: Bool
        var matched = false

        let name = "zero or more"
        parser.enter(name)

        repeat {
            let pos = reader.position
            flag = try rule.matches(parser, reader)
            if (!flag) {
                reader.seek(pos)
            }
            matched = matched || flag
        } while (flag)

        parser.leave(name, matched)
        return true
    }
}

/// Optional
postfix operator /~

public postfix func /~(rule: Rule) -> Rule {
    Rule { parser, reader in
        let name = "optionally"

        let pos = reader.position
        let result = try rule.matches(parser, reader)
        if (!result) {
            reader.seek(pos)
        }

        parser.leave(name, true)
        return true
    }
}

public postfix func /~(lit: String) -> Rule {
    Rule.literal(lit)/~
}

/// Match either
public func |(left: Rule, right: Rule) -> Rule {
    Rule.Memorizing { parser, reader in
        let name = "|"
        parser.enter(name)
        let pos = reader.position
        var result = try left.matches(parser, reader)
        if (!result) {
            reader.seek(pos)
            result = try right.matches(parser, reader)
        }

        if (!result) {
            reader.seek(pos)
        }

        parser.leave(name, result)
        return result
    }
}

public func |(left: String, right: String) -> Rule {
    Rule.literal(left) | Rule.literal(right)
}

public func |(left: Rule, right: String) -> Rule {
    left | Rule.literal(right)
}

public func |(left: String, right: Rule) -> Rule {
    Rule.literal(left) | right
}

precedencegroup MinPrecedence {
    associativity: left
    higherThan: AssignmentPrecedence
}

precedencegroup MaxPrecedence {
    associativity: left
    higherThan: MinPrecedence
}

/// Match all
infix operator ~: MinPrecedence

public func ~(left: Rule, right: Rule) -> Rule {
    Rule { parser, reader in
        let name = "~"
        parser.enter(name)
        let res = try left.matches(parser, reader) && right.matches(parser, reader)
        parser.leave(name, res)
        return res
    }
}

public func ~(left: String, right: String) -> Rule {
    Rule.literal(left) ~ Rule.literal(right)
}

public func ~(left: String, right: Rule) -> Rule {
    Rule.literal(left) ~ right
}

public func ~(left: Rule, right: String) -> Rule {
    left ~ Rule.literal(right)
}

/// On match
infix operator =>: MaxPrecedence

public func =>(rule: Rule, action: @escaping Action) -> Rule {
    Rule { parser, reader in
        let name = "=>"

        let start = reader.position
        let captureCount = parser.captures.count

        parser.enter(name)

        if try rule.matches(parser, reader) {
            let capture = Parser.Capture(start: start, end: reader.position, action: action, reader: reader)
            parser.captures.append(capture)
            parser.leave(name, true)
            return true
        }

        while parser.captures.count > captureCount {
            parser.captures.removeLast()
        }
        parser.leave(name, false)
        return false
    }
}

public func =>(rule: Rule, action: @escaping PureAction) -> Rule {
    rule => { _ in
        try action()
    }
}

/// Match two following elements, optionally with whitespace (`Parser.grammar.whitespace`) in between
infix operator ~~: MinPrecedence

public func ~~(left: Rule, right: Rule) -> Rule {
    Rule { parser, reader in
        try left.matches(parser, reader)
                && parser.grammar.whitespace.matches(parser, reader)
                && right.matches(parser, reader)
    }
}

public func ~~(left: String, right: String) -> Rule {
    Rule.literal(left) ~~ Rule.literal(right)
}

public func ~~(left: Rule, right: String) -> Rule {
    left ~~ Rule.literal(right)
}

public func ~~(left: String, right: Rule) -> Rule {
    Rule.literal(left) ~~ right
}

/// Match the given parser rule at least once, but possibly more
public postfix func ++(left: Rule) -> Rule {
    left ~~ left*
}