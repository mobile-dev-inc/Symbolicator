import Foundation
import Parsing

struct MemoryLeakOutput: Parser {
    func parse(_ input: inout Substring) throws -> MemoryLeakReport {
        try Parse {
            PrefixUpTo("\nleaks Report Version:").map { String($0) }
            PrefixUpTo("\n\n").map { String($0) }
 
            Whitespace()
            
            Many {
                Not { "\n\n\n" }
                Optionally {
                    StackParse()
                }
                
                Skip {
                    Optionally { "\n\n" }
                }
                
                ObjectGraphParse()
            }
            
            Whitespace()
        }
        .map {
            MemoryLeakReport(
                headers: $0.0 + $0.1,
                leaks: $0.2.map { Leak(stack: $0.0, objectGraph: $0.1) })
        }
        .parse(&input)
    }
}

struct StackParse: Parser {
    func parse(_ input: inout Substring) throws -> String {
        try Parse {
            PrefixUpTo("\n====\n")
            "\n====\n"
        }
        .map { String($0) }
        .parse(&input)
    }
}

struct ObjectGraphParse: Parser {
    func parse(_ input: inout Substring) throws -> String {
        try Parse {
            OneOf {
                PrefixUpTo("\n\n")
                Rest()
            }
        }
            .map { String($0) }
            .parse(&input)
    }
}
