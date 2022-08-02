import XCTest
import Foundation
@testable import Symbolicator

final class MemoryLeakParserTests: XCTestCase {
    func parseFile(at url: URL) throws -> (MemoryLeakReport, String) {
        let data = try Data(contentsOf: url)
        guard let string = String(data: data, encoding: .utf8) else { fatalError() }
        var input = string[...]
        
        return (try MemoryLeakParser().parse(&input), String(input))
    }
    
    func test_simpleLeak() throws {
        let (report, rest) = try parseFile(at: TestResources().memoryLeakUrl)
        
        XCTAssert(rest.isEmpty)
        
        XCTAssert(report.headers.contains("Load Address:    0x10ae33000"))
        XCTAssert(report.leaks.first?.objectGraph.contains("ROOT LEAK: <LeakySwiftObject 0x600001431a40> [32]") ?? false)
    }

    func test_unsymbolicated() throws {
        let (report, rest) = try parseFile(at: TestResources().memoryLeakUnsymbolicatedUrl)
        
        XCTAssert(rest.starts(with: "Binary Images:"))
        
        XCTAssert(report.headers.starts(with: "Process:"))
        XCTAssert(report.headers.contains("Process 6258: 3 leaks for 96 total leaked bytes."))
                  
        XCTAssert(report.leaks.first?.objectGraph.contains("1 (32 bytes) ROOT LEAK: <LeakySwiftObject 0x60000003d140> [32]") ?? false)
    }
    
    func test_symbolicated_with_stacktrace() throws {
        let (report, rest) = try parseFile(at: TestResources().memoryLeakWithSymbolicatedStacktraceUrl)
        
        XCTAssert(rest.starts(with: "Binary Images:"))
        
        XCTAssert(report.headers.starts(with: "Process:"))
        XCTAssert(report.headers.contains("Process 40903: 8 leaks for 384 total leaked bytes."))
        
        XCTAssertEqual(report.leaks.count, 4)
        XCTAssert(((report.leaks[2].stack?.contains("0x110e0dd91 _malloc_zone_malloc + 241")) ?? false))
        XCTAssert(report.leaks[3].objectGraph.contains("1 (16 bytes) ROOT LEAK: <LeakyObjcObject 0x600002678b80> [16]"))
    }

}

