import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

final class MemoryLeakSymbolicatorTests: XCTestCase {
    let dsymPath = TestResources().dsymUrl.appendingPathComponent("Contents/Resources/DWARF/MemoryLeakingApp").path
    let arch = "x86_64"

    func testNoBinaryImages() throws {
        let contents = try Data(contentsOf: TestResources().memoryLeakNoStackUrl)
        var symbolicator = MemoryLeakReportSymbolicator(contents)!

        let stackFrames = symbolicator.stackFramesToSymbolize()
        let symbolized = stackFrames.map { address -> (StackFrame, String) in
            let symbol = try! atos(dsymPath, arch: arch, loadAddress: address.loadAddress, address: address.address)
            return (address, symbol)
        }

        symbolicator.addSymbolsToStackFrames(symbolized)

        let result = String(data: symbolicator.contents, encoding: .utf8)!

        XCTAssert(result.starts(with: "Process:         MemoryLeakingApp [14968]"))
        XCTAssert(result.contains("1 (32 bytes) ROOT LEAK: <LeakySwiftObject 0x600001440440> [32]"))
    }
    
    func testSymbolication() throws {
        let contents = try Data(contentsOf: TestResources().memoryLeakUnsymbolicatedUrl)
        var symbolicator = MemoryLeakReportSymbolicator(contents)!

        let addresses = symbolicator.stackFramesToSymbolize()
        let stackFrames = addresses.map { address -> (StackFrame, String) in
            let symbol = try! atos(dsymPath, arch: arch, loadAddress: address.loadAddress, address: address.address)
            return (address, symbol)
        }

        symbolicator.addSymbolsToStackFrames(stackFrames)

        let result = String(data: symbolicator.contents, encoding: .utf8)!

        XCTAssert(result.contains("0x102d6026e main (in MemoryLeakingApp) (<compiler-generated>:0)"))
        XCTAssert(result.contains("0x102d62777 closure #2 in closure #1 in closure #1 in closure #1 in ContentView.body.getter (in MemoryLeakingApp) (ContentView.swift:40)"))
    }
}
