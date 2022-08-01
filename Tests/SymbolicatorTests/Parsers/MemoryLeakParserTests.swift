import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

final class MemoryLeakParserTests: XCTestCase {
    func test() throws {
        let data = try Data(contentsOf: TestResources().memoryLeakUnsymbolicatedUrl)
        guard let string = String(data: data, encoding: .utf8) else { fatalError() }

        let symbolicator = MemoryLeakReportParser(string)
        let runner = SymbolicatorRunner(
            symbolicator: symbolicator,
            dsymPath: TestResources().dsymUrl.appendingPathComponent("Contents/Resources/DWARF/MemoryLeakingApp").path,
            arch: "x86_64")
        let result = runner.run(on: string)
        
        XCTAssert(result.contains("0x102d6026e main (in MemoryLeakingApp) (<compiler-generated>:0)"))
        XCTAssert(result.contains("0x102d62777 closure #2 in closure #1 in closure #1 in closure #1 in ContentView.body.getter (in MemoryLeakingApp) (ContentView.swift:40)"))
    }
}
