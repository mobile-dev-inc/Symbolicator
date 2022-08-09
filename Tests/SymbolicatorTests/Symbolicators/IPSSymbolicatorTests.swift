import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import GenericJSON

final class IPSSymbolicatorTests: XCTestCase {
    func test() throws {
        let dsymFile = TestResources().dsymUrl.appendingPathComponent("Contents/Resources/DWARF/MemoryLeakingApp").path
        let arch = "x86_64"
        let contents = try Data(contentsOf: TestResources().memoryLeakingAppIPS)

        var symbolicator = IPSSymbolicator(contents)!

        let stackFrames = try symbolicator.stackFramesToSymbolize()
        let atos = AddressToSymbol(dsymFile: dsymFile, arch: arch)
        let symbolized = try atos.symbols(for: stackFrames)
        symbolicator.addSymbolsToStackFrames(symbolized)

        let expected = #""symbol" : "closure #3 in closure #1 in closure #1 in closure #1 in ContentView.body.getter (in MemoryLeakingApp) (ContentView.swift:46)""#
            .data(using: .utf8)!

        XCTAssertNotNil(symbolicator.contents.range(of: expected))
    }
}
