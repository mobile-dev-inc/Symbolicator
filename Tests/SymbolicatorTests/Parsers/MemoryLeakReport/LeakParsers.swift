import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

final class CycleSymbolicatedObjectParseTests: XCTestCase {
    func test() throws {
        let input = "<LeakyObjcObject 0x600002678b80>"
        let symbol = try CycleSymbolicatedObjectParse().parse(input)
            
        XCTAssertEqual(symbol.0, "LeakyObjcObject")
        XCTAssertEqual(symbol.1, 105553156606848)
    }
}

final class CycleObjectDescriptionParseTests: XCTestCase {
    func testUnsymbolicated() throws {
        let input = "0x6000013746e0 [176]"
        
        let description = try CycleObjectDescriptionParse().parse(input)
        
        XCTAssertEqual(description.0, "")
        XCTAssertEqual(description.1, 105553136666336)
        XCTAssertEqual(description.2, 176)
    }
    
    func testSymbolicated() throws {
        let input = "<LeakySwiftObject 0x600002424860> [32]"
        
        let description = try CycleObjectDescriptionParse().parse(input)
        
        XCTAssertEqual(description.0, "LeakySwiftObject")
        XCTAssertEqual(description.1, 105553154164832)
        XCTAssertEqual(description.2, 32)
    }
}

final class CyclePrefixParseTests: XCTestCase {
    func test() throws {
        let input = "4 (128 bytes)"
        let prefix = try CyclePrefixParse().parse(input)
        XCTAssertEqual(prefix.0, 4)
        XCTAssertEqual(prefix.1, 128)
    }
}

final class CycleItemSymbolicatedParseTests: XCTestCase {
    func test() throws {
        let input = "ROOT CYCLE: <LeakySwiftObject 0x600002431220>"
        let item = try CycleItemSymbolicatedParse().parse(input)
        XCTAssertEqual(item.0, "ROOT CYCLE:")
        XCTAssertEqual(item.1, "LeakySwiftObject")
        XCTAssertEqual(item.2, 105553154216480)
    }
}

final class CycleItemUnsymbolicatedParseTests: XCTestCase {
    func test() throws {
        let input = "ROOT CYCLE: 0x7ff29c304630"
        let item = try CycleItemUnsymbolicatedParse().parse(input)
        XCTAssertEqual(item.0, "ROOT CYCLE:")
        XCTAssertNil(item.1)
        XCTAssertEqual(item.2, 140679979222576)
    }
    
    func testUnnamedCycleStep() throws {
        let input = "0x7ff29c305230"
        let item = try CycleItemUnsymbolicatedParse().parse(input)
        XCTAssertNil(item.0)
        XCTAssertNil(item.1)
        XCTAssertEqual(item.2, 0x7ff29c305230)
    }
}

final class CycleParseTests: XCTestCase {
    func testSymbolicated() throws {
        let input = """
                2 (64 bytes) ROOT CYCLE: <LeakySwiftObject 0x600002431220> [32]
                   1 (32 bytes) cycle --> ROOT CYCLE: <LeakySwiftObject 0x600002431240> [32]
                      cycle --> CYCLE BACK TO <LeakySwiftObject 0x600002431220> [32]
            """

        let cycle = try CycleParse().parse(input)
        
        XCTAssertEqual(cycle.count, 3)
        XCTAssertEqual(cycle[0].1.0.0, "ROOT CYCLE:")
        XCTAssertEqual(cycle[1].1.0.0, "cycle --> ROOT CYCLE:")
    }
    
    func testUnsymbolicated() throws {
        let input = """
                    4 (272 bytes) ROOT CYCLE: 0x7ff29c304500 [16]
                       3 (256 bytes) ROOT CYCLE: 0x7ff29c304630 [80]
                          CYCLE BACK TO 0x7ff29c304500 [16]
                          2 (176 bytes) 0x7ff29c305230 [144]
                             1 (32 bytes) 0x7ff29c304510 [32]
            """
        
        let cycle = try CycleParse().parse(input)
        
        XCTAssertEqual(cycle.count, 5)
        XCTAssertEqual(cycle.last?.1.0.2, 0x7ff29c304510)
    }
    
    func testDontParseSeparatorSymbolicated() {
        let input = """
                ----
            ROOT CYCLE: <LeakySwiftObject 0x600002431220>
            """
        
        XCTAssertThrowsError(try CycleParse().parse(input))
    }

    func testDontParseSeparatorUnsymbolicated() {
        let input = """
                ----
            ROOT CYCLE: 0x7ff29c304630 [80]
            """
        
        XCTAssertThrowsError(try CycleParse().parse(input))
    }
}

class SingleLeakParseTests: XCTestCase {
    func test() throws {
        let input = """
                      2 (64 bytes) ROOT CYCLE: <LeakySwiftObject 0x600002424860> [32]
                         1 (32 bytes) cycle --> ROOT CYCLE: <LeakySwiftObject 0x600002424880> [32]
                            cycle --> CYCLE BACK TO <LeakySwiftObject 0x600002424860> [32]
            """
        
        let leak = try SingleLeakParse().parse(input)
        
        print(leak)
    }
}


class MultiLeakParseTests: XCTestCase {
    func test() throws {
        let input = """
                4 (128 bytes) << TOTAL >>
                  ----
                  2 (64 bytes) ROOT CYCLE: <LeakySwiftObject 0x600002424860> [32]
                     1 (32 bytes) cycle --> ROOT CYCLE: <LeakySwiftObject 0x600002424880> [32]
                        cycle --> CYCLE BACK TO <LeakySwiftObject 0x600002424860> [32]
                  ----
                  2 (64 bytes) ROOT CYCLE: <LeakySwiftObject 0x6000024250e0> [32]
                     1 (32 bytes) cycle --> ROOT CYCLE: <LeakySwiftObject 0x600002425120> [32]
                        cycle --> CYCLE BACK TO <LeakySwiftObject 0x6000024250e0> [32]
            """
        
        
        let cycles = try MultiLeakParse().parse(input)
        XCTAssertEqual(cycles.0.0, 4)
        XCTAssertEqual(cycles.0.1, 128)
        XCTAssertEqual(cycles.1.count, 2)
    }
}
