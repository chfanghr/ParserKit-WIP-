//
// Created by 方泓睿 on 11/8/20.
//

import Foundation

public typealias Matcher = (_ parser: Parser, _ reader: Reader) throws -> Bool
public typealias Action = (_ parser: Parser) throws -> ()
public typealias PureAction = () throws -> ()

open class Parser {
    public struct Capture: CustomStringConvertible {
        public var start: Int
        public var end: Int
        public var action: Action

        let reader: Reader

        var text: String {
            reader.substring(start, end)
        }
        public var description: String {
            "[\(start),\(end):\(text)]"
        }
    }

    public var captures: [Capture] = []
    public var currentCapture: Capture?
    public var lastCapture: Capture?

    public var currentReader: Reader?

    public var grammar: Grammar

    internal var nestingDepth = 0

    internal var matches: [Rule: [Int: Bool]] = [:]

    public var text: String {
        get {
            if let capture = currentCapture {
                return capture.text
            }
            return ""
        }
    }

    public init() {
        grammar = Grammar()
    }

    public init(grammar: Grammar) {
        self.grammar = grammar
    }

    func enter(_ name: String) {
        depth += 1
        inDebugBuilds {
            out("++ \(name)")
        }
    }

    func leave(_ name: String, _ res: Bool) {
        inDebugBuilds {
            out("-- \(name):\t\(res)")
        }
        depth -= 1
    }

    func leave(_ name: String) {
        inDebugBuilds {
            out("-- \(name)")
        }
        depth -= 1
    }

    func out(_ name: String) {
        var space = ""
        for _ in 0..<depth - 1 {
            space += " "
        }
        print("\(space)\(name)")
    }

    var depth = 0

    public func parse(_ string: String) throws -> Bool {
        try parse(from: StringReader(string: string))
    }

    public func parse(from reader: Reader) throws -> Bool {
        matches.removeAll(keepingCapacity: false)
        captures.removeAll(keepingCapacity: false)

        currentCapture = nil
        lastCapture = nil

        defer {
            currentReader = nil
            currentCapture = nil
            lastCapture = nil

            matches.removeAll(keepingCapacity: false)
            captures.removeAll(keepingCapacity: false)
        }

        if try grammar.startRule.matches(self, reader) {
            currentReader = reader

            for capture in captures {
                lastCapture = currentCapture
                currentCapture = capture
                try capture.action(self)
            }

            return true
        }

        return false
    }
}

internal func inDebugBuilds(_ code: () -> Void) {
    assert({
        code(); return true
    }())
}