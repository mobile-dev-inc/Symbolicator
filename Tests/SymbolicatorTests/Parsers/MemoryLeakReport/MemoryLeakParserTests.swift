import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

final class MemoryLeakParserTests: XCTestCase {
    func memoryLeakReport(from: URL) throws -> MemoryLeakReport? {
        let data = try Data(contentsOf: TestResources().memoryLeakUrl)
        return MemoryLeakParser(data: data).parse()
    }
    
    func testParseHeaders() throws {
        let report = try memoryLeakReport(from: TestResources().memoryLeakUrl)
        XCTAssertEqual(report?.headers["Identifier"], "MemoryLeakingApp")
    }

    func testParseMetadata() throws {
        let report = try memoryLeakReport(from: TestResources().memoryLeakUrl)
        XCTAssertEqual(report?.metadata["leaks Report Version"], "4.0")
    }
    
    func testParseLeaks() throws {
        let report = try memoryLeakReport(from: TestResources().memoryLeakUrl)
        XCTAssertEqual(report?.leaks.count, 1)
        XCTAssertEqual(report?.leaks.first?.occurences.count, 2)
    }
}
