//
// Created by 方泓睿 on 11/8/20.
//

public protocol Reader {
    var position: Int { get }

    func seek(_ position: Int)
    func read() -> Character
    func substring(_ startingAt: Int, _ endingAt: Int) -> String
    func eof() -> Bool
    func remainder() -> String
}
