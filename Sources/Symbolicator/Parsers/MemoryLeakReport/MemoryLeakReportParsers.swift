
import Foundation
import Parsing

//protocol ParserW: Parser where Input: Collection {
//    associatedtype Parsers: Parser
//    where Output == Parsers.Output, Parsers.Input == Input.SubSequence
//    //'Self.Parsers.Input' and 'Self.Input.SubSequence' be equivalent
//
//    @ParserBuilder func body(_ input: inout Input) -> Parsers
//}
//
//extension ParserW {
//    func parse(_ input: inout Input) throws -> Output {
//        try body(&input).parse(&input)
//    }
//}
//
//struct SingleHeaderParseW: ParserW {
//    // 'PrarserW' requires the types 'Substring.SubSequence' (aka 'Substring') and '(some Parser).Input' be equivalent
//    typealias Input = Substring
//
//    func body(_ input: inout Substring) -> some Parser {
//        Prefix { $0 != ":" && $0 != "\n" }
//        ":"
//        Skip { Whitespace(.horizontal) }
//        Prefix { $0 != "\n" }
//    }
//}

//protocol ParseP: Parser where Input: Collection {
//    associatedtype Parsers: Parser
//    where Parsers.Output == Output,
//          Parsers.Input == Input
//
//    @ParserBuilder
//    var body: Parsers { get }
//}
//
//extension ParseP {
//    func parse(_ input: inout Input) throws -> Output {
//        try body.parse(&input)
//    }
//}
//
//struct SingleHeaderParse: ParseP {
//    // 'ParseP' requires the types 'SingleHeaderParse.Input' (aka 'Substring') and '(some Parser).Input' be equivalent
////    typealias Input = Substring
////    typealias Output = (Substring, Substring)
//
//    var body: some Parser {
//        Parse {
//        Prefix { $0 != ":" && $0 != "\n" }
//        ":"
//        Skip { Whitespace(.horizontal) }
//        Prefix { $0 != "\n" }
//        }
//    }
//}

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

struct HexDecimalParse: Parser {
    func parse(_ input: inout Substring) throws -> Int {
        // Remove the 0x prefix if present
        guard input.hasPrefix("0x") || input.hasPrefix("0X") else {
            throw ParsingError.expectedInput("0x", at: input)
        }
        input = input.dropFirst(2)
        
        // Consume any characters that can be represented as a hex digit
        var nibbles = [Int]()
        while let hexDigit = input.first?.hexDigitValue {
            input.removeFirst()
            nibbles.append(hexDigit)
        }
        
        guard !nibbles.isEmpty else {
            throw ParsingError.expectedInput("hex decimal digit", at: input)
        }
        
        var value = 0
        var nibbleOffset = 1
        for nibble in nibbles.reversed() {
            let fourBitValue = nibble
            value += fourBitValue * nibbleOffset
            nibbleOffset <<= 4
        }
        
        return value
    }
}

struct StackObject {
    let name: String?
    let address: Int
    let loadAddress: Int?
}

struct StackFrameParse: Parser {
    func parse(_ input: inout Substring) throws -> StackFrame {
        try Parse {
            Parse {
                Int.parser()
                Skip { Whitespace(.horizontal) }
                PrefixUpTo("  ").map { String($0) }
                Skip { Whitespace(.horizontal) }
                HexDecimalParse()
                Skip { Whitespace(.horizontal) }
            }
            Parse {

                OneOf {
                    HexDecimalParse()
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
            Prefix { $0 != "\n" }.map { String($0) }
            "\n"
            Many {
                StackFrameParse()
            } separator: { "\n" } terminator: { "\n====" }
        }
        .map { Stack(context: $0.0, frames: $0.1) }
        .parse(&input)
    }
}

struct CycleSymbolicatedObjectParse: Parser {
    func parse(_ input: inout Substring) throws -> (String, Int) {
        try Parse {
            Skip { "<" }
            Prefix<Substring> { CharacterSet.alphanumerics.contains($0.unicodeScalars.first!) }
                .map { String($0) }
            Skip { Whitespace() }
            HexDecimalParse()
            Skip { ">" }
        }
        .parse(&input)
    }
}

struct CycleObjectDescriptionParse: Parser {
    func parse(_ input: inout Substring) throws -> (String, Int, Int) {
        try Parse {
            OneOf {
                AnyParser(CycleSymbolicatedObjectParse())
                AnyParser(Parse {
                    Always("")
                    HexDecimalParse()
                })
            }
            Skip { Whitespace(.horizontal) }
            "["
            Int.parser()
            "]"
        }
        .map({ v in
            (v.0.0, v.0.1, v.1)
        })
        .parse(&input)
    }
}

struct CyclePrefixParse: Parser {
    func parse(_ input: inout Substring) throws -> (Int, Int) {
        try Parse {
            Int.parser()
            Skip {
                Whitespace(.horizontal)
                "("
            }
            Int.parser()
            Skip { " bytes)"}
        }
        .parse(&input)
    }
}

struct CycleItemSymbolicatedParse: Parser {
    func parse(_ input: inout Substring) throws -> (String?, String?, Int) {
        //        2 (64 bytes) ROOT CYCLE: <LeakySwiftObject 0x600002431220> [32]
        //           1 (32 bytes) cycle --> ROOT CYCLE: <LeakySwiftObject 0x600002431240> [32]
        //              cycle --> CYCLE BACK TO <LeakySwiftObject 0x600002431220> [32]
        
        try Parse {
            Optionally {
                Not { " <" }
                PrefixUpTo(" <").map { String($0) }
            }
            
            Whitespace(.horizontal)

            //            CycleSymbolicatedObjectParse()

            Parse {
                "<"
                Prefix<Substring> { CharacterSet.alphanumerics.contains($0.unicodeScalars.first!) }
                    .map { String($0) }
            }
            
            Whitespace()
            HexDecimalParse()
            ">"
        }
        .parse(&input)
    }
}

struct CycleItemUnsymbolicatedParse: Parser {
    func parse(_ input: inout Substring) throws -> (String?, String?, Int) {
        //        4 (272 bytes) ROOT CYCLE: 0x7ff29c304500 [16]
        //           3 (256 bytes) ROOT CYCLE: 0x7ff29c304630 [80]
        //              CYCLE BACK TO 0x7ff29c304500 [16]
        //              2 (176 bytes) 0x7ff29c305230 [144]
        //                 1 (32 bytes) 0x7ff29c304510 [32]
        
        try Parse {
            Optionally {
                Not { "0x" }
                PrefixUpTo(" 0x").map { String($0) }
                Whitespace(.horizontal)
            }

            Always(Optional<String>.none)
            HexDecimalParse()
        }
        .parse(&input)
    }
}



struct CycleStepParse: Parser {
    func parse(_ input: inout Substring) throws -> ((String?, String?, Int), Int) {
        try Parse {
            Not {  // Make sure to not consume the "Total separator"
                Whitespace(.horizontal)
                "----"
            }
            
            OneOf {
                CycleItemSymbolicatedParse()
                CycleItemUnsymbolicatedParse()
            }
            
            Whitespace(.horizontal)
            
            Parse {
                "["
                Int.parser()
                "]"
            }
        }
        .parse(&input)
    }
}

struct CycleParse: Parser {
    func parse(_ input: inout Substring) throws -> Array<((Int, Int)?, ((String?, String?, Int), Int))> {
        try Parse {
            Many {
                Whitespace(.horizontal)
                
                Optionally {
                    CyclePrefixParse()
                    Whitespace(.horizontal)
                }
                
                CycleStepParse()
            } separator: {
                "\n"
            }
        }
        .parse(&input)
    }
}

struct RootLeakParse: Parser {
    func parse(_ input: inout Substring) throws -> ((Int, Int), (String, Int, Int)) {
        try Parse {
            Whitespace(.horizontal)
            CyclePrefixParse()
            Skip {
                Whitespace()
                "ROOT LEAK:"
                Whitespace()
            }
            CycleObjectDescriptionParse()
        }
        .parse(&input)
    }
}

struct SingleLeakParse: Parser {
    func parse(_ input: inout Substring) throws -> LeakInstance {
        try Parse {
            OneOf {
                RootLeakParse().map { l -> LeakInstance in print("Root leak \(l)"); return LeakInstance() }
                CycleParse().map { l -> LeakInstance in print("Cycle \(l)"); return LeakInstance() }
            }
        }
        .parse(&input)
    }
}

struct MultiLeakParse: Parser {
    func parse(_ input: inout Substring) throws -> ((Int, Int), Array<LeakInstance>) {
        //        4 (128 bytes) << TOTAL >>
        //          ----
        //          2 (64 bytes) ROOT CYCLE: <LeakySwiftObject 0x600002424860> [32]
        //             1 (32 bytes) cycle --> ROOT CYCLE: <LeakySwiftObject 0x600002424880> [32]
        //                cycle --> CYCLE BACK TO <LeakySwiftObject 0x600002424860> [32]
        //          ----
        //          2 (64 bytes) ROOT CYCLE: <LeakySwiftObject 0x6000024250e0> [32]
        //             1 (32 bytes) cycle --> ROOT CYCLE: <LeakySwiftObject 0x600002425120> [32]
        //                cycle --> CYCLE BACK TO <LeakySwiftObject 0x6000024250e0> [32]
        
        try Parse {
            Whitespace(.horizontal)
            
            CyclePrefixParse()
            " << TOTAL >>\n"
            Whitespace(.horizontal)
            "----\n"

            Many {
                Whitespace()
                SingleLeakParse()
            } separator: {
                Whitespace()
                "----\n"
            }
        }
        .parse(&input)
    }
}


struct MemoryLeakReportParse: Parser {
    func parse(_ input: inout Substring) throws -> MemoryLeakReport {
        let (headers, metadata, rest) = try Parse {
            HeadersParse()
            MetadataParse()
            
            Skip {
                Many {
                    StackParse()
                    MultiLeakParse()
                }
            }

            Rest()
        }
        .parse(&input)
        
        print("REST")
        print(rest)
        
        return MemoryLeakReport(
            headers: headers.toString,
            metadata: metadata.toString,
            leaks: [])
    }
}

extension Dictionary where Key == Substring, Value == Substring {
    var toString: Dictionary<String, String> {
        Dictionary<String, String>(uniqueKeysWithValues: map { key, value in
            (String(key), String(value))
        })
    }
}


struct MemoryLeakParser {
    let data: Data
    
    func parse() -> MemoryLeakReport? {
        guard let string = String(data: data, encoding: .utf8),
              string.starts(with: "Process:")
        else { return nil }

        var str = string[...]
        let result = try! MemoryLeakReportParse().parse(&str)
        print(result)
        return result
    }
}
