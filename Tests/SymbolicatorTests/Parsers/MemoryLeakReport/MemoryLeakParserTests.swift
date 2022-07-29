import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

final class MemoryLeakParserTests: XCTestCase {
    func testParseHeaders() throws {
        let data = try Data(contentsOf: TestResources().memoryLeakUrl)
        let report = MemoryLeakParser(data: data).parse()
        XCTAssertEqual(report?.headers["Identifier"], "MemoryLeakingApp")
    }

    func testParseMetadata() throws {
        let data = try Data(contentsOf: TestResources().memoryLeakUrl)
        let report = MemoryLeakParser(data: data).parse()
        XCTAssertEqual(report?.metadata["leaks Report Version"], "4.0")
    }
}

