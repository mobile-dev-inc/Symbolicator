import XCTest
import class Foundation.Bundle
@testable import Symbolicator

final class AddressToSymbolTests: XCTestCase {
    func test() throws {
        let dsymFile = TestResources().crashDsymUrl.appendingPathComponent("Contents/Resources/DWARF/CovidCertificateVerifier").path
        let arch = "x86_64"

        let atos = AddressToSymbol(dsymFile: dsymFile, arch: arch)

        let loadAddress = "0x10b8b8000"
        let addresses = [
            "0x10b8d9514",
            "0x10b8c0c40",
            "0x10b8c1b25",
            "0x10b8d8fa2",
            "0x10b8d92a9",
            "0x10b8d9f2e",
            "0x10b8da03c",
            "0x10b8d7622",
            "0x10b8d7622",
        ]
        let stackFrames = addresses.compactMap {
            StackFrame(tag: $0, loadAddress: loadAddress, address: $0)
        }

        let symbolized = try atos.symbols(for: stackFrames)

        XCTAssertEqual(symbolized.count, addresses.count)
        XCTAssertEqual(symbolized.first?.0.tag, "0x10b8d9514")
        XCTAssertEqual(symbolized.first?.1, "static VerificationError.__derived_enum_less_than(_:_:) (in CovidCertificateVerifier) (<compiler-generated>:0)")

        XCTAssertEqual(symbolized.last?.0.tag, "0x10b8d7622")
        XCTAssertEqual(symbolized.last?.1, "VerifierManager.addObserver(_:for:forceUpdate:block:) (in CovidCertificateVerifier) (VerifierManager.swift:56)")
    }
}
