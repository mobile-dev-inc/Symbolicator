import Foundation
import Parsing

struct CycleSymbolicatedObjectParse: Parser {
    func parse(_ input: inout Substring) throws -> (String, Int) {
        try Parse {
            Skip { "<" }
            Prefix<Substring> { CharacterSet.alphanumerics.contains($0.unicodeScalars.first!) }
                .map { String($0) }
            Skip { Whitespace() }
            HexDecimal()
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
                    HexDecimal()
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
            HexDecimal()
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
            HexDecimal()
        }
        .parse(&input)
    }
}



struct CycleStepParse: Parser {
    func parse(_ input: inout Substring) throws -> LeakCycleStep {
        try Parse {
            Not {  // Make sure to not consume the "Total separator"
                Whitespace(.horizontal)
                "----"
            }
            
            Optionally {
                CyclePrefixParse()
                Whitespace(.horizontal)
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
        .map {
            LeakCycleStep(
                count: $0.0?.0,
                size: $0.0?.1,
                description: $0.1.0,
                address: $0.1.2)
        }
        .parse(&input)
    }
}

struct CycleParse: Parser {
    func parse(_ input: inout Substring) throws -> LeakInstance {
        try Parse {
            Many {
                Whitespace(.horizontal)

                CycleStepParse()
            } separator: {
                "\n"
            }
        }
        .map { LeakInstance.cycle(LeakCycle(steps: $0)) }
        .parse(&input)
    }
}

struct RootLeakParse: Parser {
    func parse(_ input: inout Substring) throws -> LeakInstance {
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
        .map {
            LeakInstance.root(LeakRoot(
                count: $0.0.0,
                size: $0.0.1,
                description: $0.1.0,
                address: $0.1.2))
        }
        .parse(&input)
    }
}

struct MultiLeakCycleParse: Parser {
    func parse(_ input: inout Substring) throws -> Array<LeakInstance> {
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
                CycleParse()
            } separator: {
                Whitespace()
                "----\n"
            }
        }
        .map { $0.1 }
        .parse(&input)
    }
}

struct MultiLeakRootParse: Parser {
    func parse(_ input: inout Substring) throws -> Array<LeakInstance> {
        //                 2 (64 bytes) << TOTAL >>
        //                    1 (32 bytes) ROOT LEAK: <LeakySwiftObject 0x600001431a40> [32]
        //                    1 (32 bytes) ROOT LEAK: <LeakySwiftObject 0x600001440440> [32]
        try Parse {
            Whitespace(.horizontal)
            
            CyclePrefixParse()
            " << TOTAL >>\n"
            Whitespace(.horizontal)

            Many {
                RootLeakParse()
            } separator: { Whitespace() }
        }
        .map { $0.1 }
        .parse(&input)
    }
}

struct LeakParse: Parser {
    func parse(_ input: inout Substring) throws -> Leak {
        try Parse {
            StackParse()
            OneOf {
                MultiLeakRootParse()
                MultiLeakCycleParse()
            }
        }
        .map {
            Leak(stack: $0.0, instances: $0.1)
        }
        .parse(&input)
    }
}
