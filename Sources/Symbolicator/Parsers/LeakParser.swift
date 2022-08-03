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
            
            let name = try? LeakNameFromObjectGraphParser().parse(objectGraph)
            let occuranceCount = try? LeakOccurenceCountParser().parse(objectGraph)
            let totalLeakedBytes = try? TotalLeakedBytesParser().parse(objectGraph)
            
            return Leak(
                name: name,
                occuranceCount: occuranceCount ?? 1,
                totalLeakedBytes: totalLeakedBytes ?? 0,
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

struct LeakOccurenceCountParser: Parser {
    func parse(_ input: inout Substring) throws -> Int {
        // If there is no TOTOL header, this parser will fail
        // In that case there is only one leak
        try Parse {
            // Skip the TOTAL header
            Skip {
                PrefixThrough("<< TOTAL >>")
                PrefixThrough("\n")
            }
            
            // Count the lines starting with 6 spaces
            Many {
                "      "
                OneOf {
                    PrefixThrough("\n")
                    Rest()
                }
            }
        }
        .map {
            // Skip separators (starting with "----")
            //  and objects-referred-to-by-root-leak (starting with " ")
            $0
                .filter { !$0.starts(with: " ") && !$0.starts(with: "----") }
                .count
        }
        .parse(&input)
    }
}

struct TotalLeakedBytesParser: Parser {
    func parse(_ input: inout Substring) throws -> Int {
        try Parse {
            Skip {
                Optionally { Whitespace(.horizontal) }
                Int.parser()
            }
            " ("
            OneOf {
                Parse {
                    Int.parser()
                    " bytes)"
                }
                Parse {
                    Double.parser().map { Int($0 * 1000) }
                    "K)"
                }
                Parse {
                    Double.parser().map { Int($0 * 1000 * 1000) }
                    "M)"
                }
                Parse {
                    Double.parser().map { Int($0 * 1000 * 1000 * 1000) }
                    "G)"
                }
            }
            Skip { Rest() }
        }
        .parse(&input)
    }
}
