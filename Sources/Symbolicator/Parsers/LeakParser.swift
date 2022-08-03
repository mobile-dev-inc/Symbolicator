import Foundation
import Parsing

struct LeakParser: Parser {
    func parse(_ input: inout Substring) throws -> Leak {
        try Parse {
            Optionally {
                StackParser()
            }
            
            Skip {
                Optionally { "\n\n" }
            }
            
            ObjectGraphParser()
        }
        .map {
            let stack = $0.0
            let objectGraph = $0.1
            
            let name = (
                try? stack.map { try? LeakNameFromStackParser().parse($0) }
                ?? LeakNameFromObjectGraphParser().parse(objectGraph))

            return Leak(
                name: name,
                totalLeakedBytes: 0,
                stack: stack,
                objectGraph: objectGraph)
        }
        .parse(&input)
    }
}

struct StackParser: Parser {
    func parse(_ input: inout Substring) throws -> String {
        try Parse {
            PrefixUpTo("\n====\n")
            "\n====\n"
        }
        .map { String($0) }
        .parse(&input)
    }
}

struct ObjectGraphParser: Parser {
    func parse(_ input: inout Substring) throws -> String {
        try OneOf {
            PrefixUpTo("\n\n")
            Rest()
        }
        .map { String($0) }
        .parse(&input)
    }
}

struct LeakNameFromStackParser: Parser {
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

struct LeakNameFromObjectGraphParser: Parser {
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
