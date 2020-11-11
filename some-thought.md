```swift
// "a" followed by "b"
let rule = "a" ~ "b"

// "a" followed by "b", with possible whitespace in between
// to change what is considered whitespace, change the parser.whitespace rule
let rule = "a" ~~ "b"

// at least one "a", but possibly more
let rule = "a"++

// "a" or "b"
let rule = "a" | "b"

// "a" followed by something other than "b"
let rule = "a" ~ !"b"

// "a" followed by one or more "b"
let rule = "a" ~ "b"+

// "a" followed by zero or more "b"
let rule = "a" ~ "b"*

// "a" followed by a numeric digit
let rule = "a" ~ ("0"-"9")

// "a" followed by the rule named "blah"
let rule = "a" ~ ^"blah"

// "a" optionally followed by "b"
let rule = "a" ~ "b"/~

// "a" followed by the end of input
let rule = "a"*!*

// a single "," 
let rule = %","
    
// regular expression: consecutive word or space characters
let rule = %!"[\\w\\s]+"
```

```swift
import SwiftParser
class Adder : Parser {
    var stack: Int[] = []
    
    func push(_ text: String) {
        stack.append(text.toInt()!)
    }
    
    func add() {
        let left = stack.removeLast()
        let right = stack.removeLast()
        
        stack.append(left + right)
    }

	override init() {
		super.init()

		self.grammar = Grammar { [unowned self] g in
			g["number"] = ("0"-"9")+ => { [unowned self] parser in self.push(parser.text) }
			return (^"number" ~ "+" ~ ^"number") => add
		}
	}
}
```

```swift
self.grammar = Grammar { [unowned self] g in
	g["number"] = ("0"-"9")+ => { [unowned self] parser in self.push(parser.text) }

	g["primary"] = ^"secondary" ~ (("+" ~ ^"secondary" => add) | ("-" ~ ^"secondary" => sub))*
	g["secondary"] = ^"tertiary" ~ (("*" ~ ^"tertiary" => mul) | ("/" ~ ^"tertiary" => div))*
	g["tertiary"] = ("(" ~ ^"primary" ~ ")") | ^"number"

	return (^"primary")*!*
}
```
