import XCTest
import Foundation
@testable import Symbolicator

final class MemoryLeakParserTests: XCTestCase {
    func parseFile(at url: URL) throws -> MemoryLeakReport {
        let data = try Data(contentsOf: url)
        guard let string = String(data: data, encoding: .utf8) else { fatalError() }
        return try MemoryLeakReportParser().parse(string)
    }
    
    func test_no_stack() throws {
        let report = try parseFile(at: TestResources().memoryLeakNoStackUrl)
        
        XCTAssert(report.headers.contains("Load Address:    0x10ae33000"))
        
        guard let leak = report.leaks.first else {
            XCTFail("No leak in report")
            return
        }
        
        XCTAssertEqual(leak.name, "LeakySwiftObject")
        XCTAssertEqual(leak.occurrenceCount, 2)
        XCTAssertEqual(leak.totalLeakedBytes, 64)
        XCTAssert(leak.objectGraph.contains("ROOT LEAK: <LeakySwiftObject 0x600001431a40> [32]"))
        XCTAssertNil(leak.stack)
        XCTAssertNil(report.binaryImages)
    }

    func test_unsymbolicated() throws {
        let report = try parseFile(at: TestResources().memoryLeakUnsymbolicatedUrl)

        XCTAssert(report.headers.starts(with: "Process:"))
        XCTAssert(report.headers.contains("Process 6258: 3 leaks for 96 total leaked bytes."))

        guard let leak = report.leaks.first else {
            XCTFail("No leak in report")
            return
        }

        XCTAssertEqual(leak.name, "LeakySwiftObject")
        XCTAssertEqual(leak.occurrenceCount, 3)
        XCTAssertEqual(leak.totalLeakedBytes, 96)
        XCTAssert(leak.objectGraph.hasPrefix("    3 (96 bytes) << TOTAL >>"))
        XCTAssert(leak.objectGraph.hasSuffix("<LeakySwiftObject 0x60000003d140> [32]\n"))

        guard let stack = leak.stack else {
            XCTFail("No stack for leak \(leak)")
            return
        }

        XCTAssert(stack.hasPrefix("31  dyld"))
        XCTAssert(stack.hasSuffix("_malloc_zone_malloc + 241 \n"))

        XCTAssert(report.binaryImages?.starts(with: "Binary Images:") ?? false)
    }
    
    func test_symbolicated_with_stacktrace() throws {
        let report = try parseFile(at: TestResources().memoryLeakWithSymbolicatedStacktraceUrl)
        
        XCTAssert(report.headers.hasPrefix("Process:"))
        XCTAssert(report.headers.contains("Process 40903: 8 leaks for 384 total leaked bytes."))
        
        XCTAssertEqual(report.leaks.count, 4)
        
        XCTAssertEqual(report.leaks[0].name, "malloc<176>")
        XCTAssertEqual(report.leaks[0].occurrenceCount, 1)
        XCTAssertEqual(report.leaks[0].totalLeakedBytes, 176)

        XCTAssertEqual(report.leaks[1].name, "LeakySwiftObject")
        XCTAssertEqual(report.leaks[1].occurrenceCount, 2)
        XCTAssertEqual(report.leaks[1].totalLeakedBytes, 128)

        XCTAssertEqual(report.leaks[2].name, "LeakySwiftObject")
        XCTAssertEqual(report.leaks[2].occurrenceCount, 1)
        XCTAssertEqual(report.leaks[2].totalLeakedBytes, 64)

        XCTAssertEqual(report.leaks[3].name, "LeakyObjcObject")
        XCTAssertEqual(report.leaks[3].occurrenceCount, 1)
        XCTAssertEqual(report.leaks[3].totalLeakedBytes, 16)

        XCTAssert(((report.leaks[2].stack?.contains("0x110e0dd91 _malloc_zone_malloc + 241")) ?? false))
        XCTAssert(report.leaks[3].objectGraph.contains("1 (16 bytes) ROOT LEAK: <LeakyObjcObject 0x600002678b80> [16]"))

        XCTAssert(report.binaryImages?.starts(with: "Binary Images:") ?? false)
    }

    func test_unicode_unsymbolicated() throws {
        let report = try parseFile(at: TestResources().memoryLeakUnicodeUnsymbolicatedUrl)
        
        XCTAssert(report.headers.starts(with: "Process:"))
        XCTAssert(report.headers.contains("Physical footprint (peak):  72.3M"))
        
        XCTAssertEqual(report.leaks.count, 4)
        
        XCTAssertEqual(report.leaks[0].name, "MemoryLeakingApp.LeakySwiftObject💦")
        XCTAssertEqual(report.leaks[0].occurrenceCount, 1)
        XCTAssertEqual(report.leaks[0].totalLeakedBytes, 256 * 1000)

        XCTAssertEqual(report.leaks[1].name, "MemoryLeakingApp.LeakySwiftObject💦")
        XCTAssertEqual(report.leaks[1].occurrenceCount, 1)
        XCTAssertEqual(report.leaks[1].totalLeakedBytes, 256 * 1000)

        XCTAssertEqual(report.leaks[2].name, "malloc<176>")
        XCTAssertEqual(report.leaks[2].occurrenceCount, 3)
        XCTAssertEqual(report.leaks[2].totalLeakedBytes, 528)

        XCTAssertEqual(report.leaks[3].name, "LeakyObjcObject")
        XCTAssertEqual(report.leaks[3].occurrenceCount, 4)
        XCTAssertEqual(report.leaks[3].totalLeakedBytes, 64)

        XCTAssert(report.leaks[0].objectGraph.contains("ROOT CYCLE: <MemoryLeakingApp.LeakySwiftObject💦 0x600002ffb7a0> [32]"))
        
        XCTAssert(report.binaryImages?.starts(with: "Binary Images:") ?? false)
    }

    func test_with_excludes() throws {
        let report = try parseFile(at: TestResources().memoryLeakWithExcludesUrl)

        XCTAssertEqual(report.leaks.count, 1)
        XCTAssertEqual(report.excludedLeakCount, 56)
    }
}

