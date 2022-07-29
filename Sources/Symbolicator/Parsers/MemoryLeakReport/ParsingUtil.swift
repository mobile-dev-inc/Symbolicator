import Foundation

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

