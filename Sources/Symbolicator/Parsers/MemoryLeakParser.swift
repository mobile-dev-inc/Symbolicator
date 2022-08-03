import Foundation
import Parsing

struct MemoryLeakParser: Parser {
    func parse(_ input: inout Substring) throws -> MemoryLeakReport {
        try Parse {
            PrefixUpTo("\nleaks Report Version:").map { String($0) }
            PrefixUpTo("\n\n").map { String($0) }
 
            Whitespace()
            
            Many {
                Not { "\n\n\n" }
                LeakParse()
            }
            
            Whitespace()
            
            Optionally {
                Rest().map { String($0) }
            }
        }
        .map {
            MemoryLeakReport(
                headers: $0.0 + $0.1,
                leaks: $0.2,
                binaryImages: $0.3
            )
        }
        .parse(&input)
    }
}

struct LeakParse: Parser {
    func parse(_ input: inout Substring) throws -> Leak {
        try Parse {
            Optionally {
                StackParse()
            }
            
            Skip {
                Optionally { "\n\n" }
            }
            
            ObjectGraphParse()
        }
        .map {
            let stack = $0.0
            let objectGraph = $0.1
            
            let name = (
                try? stack.map { try? LeakNameFromStackParse().parse($0) }
                ?? LeakNameFromObjectGraphParse().parse(objectGraph))

            return Leak(
                name: name,
                totalLeakedBytes: 0,
                stack: stack,
                objectGraph: objectGraph)
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
        try OneOf {
            PrefixUpTo("\n\n")
            Rest()
        }
        .map { String($0) }
        .parse(&input)
    }
}

struct LeakNameFromStackParse: Parser {
    func parse(_ input: inout Substring) throws -> String {
        try Parse {
            OneOf {
                Parse {
                    Skip {
                        OneOf {
                            PrefixThrough("'ROOT LEAK: <")
                            PrefixThrough("'ROOT CYCLE: <")
                        }
                    }
                    PrefixUpTo(">'").map { String($0) }
                }
                Parse {
                    Skip {
                        OneOf {
                            PrefixThrough("'ROOT LEAK: ")
                            PrefixThrough("'ROOT CYCLE: ")
                        }
                    }
                    PrefixUpTo("'").map { String($0) }
                }
            }
            Skip { Rest() }
        }
        .parse(&input)
    }
}

struct LeakNameFromObjectGraphParse: Parser {
    func parse(_ input: inout Substring) throws -> String {
        try Parse {
            OneOf {
                Parse {
                    OneOf {
                        Skip { PrefixThrough("ROOT LEAK: <") }
                        Skip { PrefixThrough("ROOT CYCLE: <") }
                    }
                    PrefixUpTo(" 0x").map { String($0) }
                }
                Parse {
                    Skip {
                        PrefixThrough("ROOT LEAK: 0x")
                        PrefixThrough(" [")
                    }
                    PrefixUpTo("]").map { "malloc<\($0)>" }
                }
            }
            
            Skip { Rest() }
        }
        .parse(&input)
    }
}
