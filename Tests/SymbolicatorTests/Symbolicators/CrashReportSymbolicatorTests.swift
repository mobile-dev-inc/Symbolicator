import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

final class CrashReportSymbolicatorTests: XCTestCase {
    func test() throws {
        let dsymPath = TestResources().crashDsymUrl.appendingPathComponent("Contents/Resources/DWARF/CovidCertificateVerifier").path
        let arch = "x86_64"
        let contents = try Data(contentsOf: TestResources().nonSymbolicatedCrashUrl)

        var symbolicator = CrashReportSymbolicator(contents)!
        symbolicator.setAppName("CovidCertificateVerifier")

        let stackFrames = symbolicator.stackFramesToSymbolize()
        let symbolized = stackFrames.map { address -> (StackFrame, String) in
            let symbol = try! atos(dsymPath, arch: arch, loadAddress: address.loadAddress, address: address.address)
            return (address, symbol)
        }

        symbolicator.addSymbolsToStackFrames(symbolized)

        let result = String(data: symbolicator.contents, encoding: .utf8)!

        XCTAssert(result.contains("0x000000010b8c0c40 AppDelegate.completedOnboarding() (in CovidCertificateVerifier) (AppDelegate.swift:122)"))
        XCTAssert(result.contains("0x000000010b8d9f2e VerificationState.wasRevocationSkipped.getter (in CovidCertificateVerifier) (Verifier.swift:108)"))
    }
}
