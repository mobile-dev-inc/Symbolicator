import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

final class MemoryLeakSymbolicatorTests: XCTestCase {
    
    func testNoBinaryImages() throws {
        let data = try Data(contentsOf: TestResources().memoryLeakNoStackUrl)
        guard let string = String(data: data, encoding: .utf8) else { fatalError() }

        let symbolicator = MemoryLeakReportSymbolicator(string)
        let runner = SymbolicatorRunner(
            symbolicator: symbolicator,
            dsymPath: TestResources().dsymUrl.appendingPathComponent("Contents/Resources/DWARF/MemoryLeakingApp").path,
            arch: "x86_64")
        let result = try runner.run(on: string)
        
        XCTAssert(result.starts(with: "Process:         MemoryLeakingApp [14968]"))
        XCTAssert(result.contains("1 (32 bytes) ROOT LEAK: <LeakySwiftObject 0x600001440440> [32]"))
    }
    
    func test() throws {
        let data = try Data(contentsOf: TestResources().memoryLeakUnsymbolicatedUrl)
        guard let string = String(data: data, encoding: .utf8) else { fatalError() }

        let symbolicator = MemoryLeakReportSymbolicator(string)
        let runner = SymbolicatorRunner(
            symbolicator: symbolicator,
            dsymPath: TestResources().dsymUrl.appendingPathComponent("Contents/Resources/DWARF/MemoryLeakingApp").path,
            arch: "x86_64")
        let result = try runner.run(on: string)
        
        XCTAssert(result.contains("0x102d6026e main (in MemoryLeakingApp) (<compiler-generated>:0)"))
        XCTAssert(result.contains("0x102d62777 closure #2 in closure #1 in closure #1 in closure #1 in ContentView.body.getter (in MemoryLeakingApp) (ContentView.swift:40)"))
    }
}
