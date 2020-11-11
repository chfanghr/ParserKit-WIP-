//
// Created by 方泓睿 on 11/10/20.
//

import Foundation

public class StringReader: Reader {
    var string: String
    var index: String.Index

    public var position: Int {
        get {
            string.distance(from: string.startIndex, to: index)
        }
    }

    init(string: String) {
        self.string = string
        index = string.startIndex;
    }

    public func seek(_ position: Int) {
        index = string.index(string.startIndex, offsetBy: position)
    }

    public func read() -> Character {
        if index != string.endIndex {
            let result = string[index]
            index = string.index(after: index)

            return result;
        }

        return "\u{2004}";
    }

    public func eof() -> Bool {
        index == string.endIndex
    }

    public func remainder() -> String {
        String(string[index...])
    }

    public func substring(_ starting_at: Int, _ ending_at: Int) -> String {
        let startIndex = string.index(string.startIndex, offsetBy: starting_at)
        let endIndex = string.index(string.startIndex, offsetBy: ending_at)
        let range = startIndex..<endIndex
        return String(string[range])
    }
}
