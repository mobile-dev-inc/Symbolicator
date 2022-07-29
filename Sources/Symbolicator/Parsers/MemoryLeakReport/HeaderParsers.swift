import Foundation
import Parsing

struct SingleHeaderParse: Parser {
    func parse(_ input: inout Substring) throws -> (Substring, Substring) {
        try Parse {
            Prefix { $0 != ":" && $0 != "\n" }
            ":"
            Skip { Whitespace(.horizontal) }
            Prefix { $0 != "\n" }
        }
        .parse(&input)
    }
}

struct HeadersParse: Parser {
    func parse(_ input: inout Substring) throws -> Dictionary<Substring, Substring> {
        try Many(
            element: {
                Skip { Many { "\n" } }
                SingleHeaderParse()
            },
            terminator: {
                "\n----"
            })
        .parse(&input)
        .reduce(into: [:]) { $0[$1.0] = $1.1 }
    }
}

struct MetadataParse: Parser {
    func parse(_ input: inout Substring) throws -> Dictionary<Substring, Substring> {
        try Parse {
            "\n"
            Many(
                element: {
                    Skip { "\n" }
                    SingleHeaderParse()
                },
                terminator: {
                    "\n\n"
                })
        }
        .parse(&input)
        .reduce(into: [:]) {
            if let value = $0[$1.0] {
                $0[$1.0] = value + "\n" + $1.1
            } else {
                $0[$1.0] = $1.1
            }
        }
    }
}
