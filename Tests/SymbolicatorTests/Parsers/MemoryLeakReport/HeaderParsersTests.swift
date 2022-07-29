import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

final class SingleHeaderParseTests: XCTestCase {
    func test() throws {
        let input = "Process:         MemoryLeakingApp [14968]"
        
        let header = try SingleHeaderParse().parse(input)
        
        XCTAssertEqual(header.0, "Process")
        XCTAssertEqual(header.1, "MemoryLeakingApp [14968]")
    }
}

final class HeadersParseTests: XCTestCase {
    func test() throws {
        let input = """
            Code Type:       X86-64
            Platform:        iOS Simulator
            Parent Process:  launchd_sim [12679]

            Date/Time:       2022-07-26 12:11:47.963 +0400
            Launch Time:     2022-07-25 19:25:29.886 +0400
            OS Version:      iPhone OS 15.5 (19F70)
            ----
            """
        
        let headers = try HeadersParse().parse(input)
        
        XCTAssertEqual(headers.count, 6)
        XCTAssertEqual(headers["OS Version"], "iPhone OS 15.5 (19F70)")
    }
}

final class MetadataParseTests: XCTestCase {
    func test() throws {
        let input = """
            
            
            leaks Report Version: 4.0
            Process 14968: 32077 nodes malloced for 6030 KB
            Process 14968: 2 leaks for 64 total leaked bytes.
            
            
            """
        
        let metadata = try MetadataParse().parse(input)

        XCTAssertEqual(metadata.count, 2)
        XCTAssertEqual(metadata["leaks Report Version"], "4.0")
        XCTAssertEqual(metadata["Process 14968"], "32077 nodes malloced for 6030 KB\n2 leaks for 64 total leaked bytes.")
    }
}
