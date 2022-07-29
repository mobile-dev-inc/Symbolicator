import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

final class HexDecimalParseTests: XCTestCase {
    func test() throws {
        let input = "0x10f00c1ee"

        let int = try HexDecimal().parse(input)
        
        XCTAssertEqual(int, 4546675182)
    }
}
