import Foundation
import Parsing

struct StackFrameParse: Parser {
    func parse(_ input: inout Substring) throws -> StackFrame {
        try Parse {
            Parse {
                Int.parser()
                Skip { Whitespace(.horizontal) }
                PrefixUpTo("  ").map { String($0) }
                Skip { Whitespace(.horizontal) }
                HexDecimal()
                Skip { Whitespace(.horizontal) }
            }
            Parse {

                OneOf {
                    HexDecimal()
                        .map { (Optional($0), Optional<String>.none) }
                    
                    PrefixUpTo(" + ")
                        .map { (Optional<Int>.none, Optional(String($0))) }
                }
                
                Skip {
                    Optionally { " " }
                    "+ "
                }
                
                Int.parser()
                
                Optionally {
                    Skip { Whitespace(.horizontal) }
                    Prefix { $0 != "\n" }.map { String($0) }
                }
            }
        }
        .map {
          // ((Int, String, Int), ((Optional<Int>, Optional<String>), Int))
          StackFrame(
            stackIndex: $0.0.0,
            frameworkName: $0.0.1,
            address: $0.0.2,
            name: $0.1.0.1,
            loadAddress: $0.1.0.0,
            offset: $0.1.1,
            origin: $0.1.2)
        }
        .parse(&input)
    }
}

struct StackParse: Parser {
    func parse(_ input: inout Substring) throws -> Stack {
        try Parse {
            "STACK OF "
            Int.parser()
            " INSTANCES OF '"
            Prefix { $0 != "'" }.map { String($0) }
            "':\n"
                        
            Many {
                StackFrameParse()
            } separator: { "\n" } terminator: { "\n====" }
        }
        .map { Stack(context: $0.1, frames: $0.2) }
        .parse(&input)
    }
}

