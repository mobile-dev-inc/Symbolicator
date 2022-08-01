import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

final class CrashReportParserTests: XCTestCase {
    func test() throws {
        let data = try Data(contentsOf: TestResources().nonSymbolicatedCrashUrl)
        guard let contents = String(data: data, encoding: .utf8) else { fatalError() }

        let symbolicator = CrashReportParser(contents: contents,
                                             appName: "CovidCertificateVerifier")
        let runner = SymbolicatorRunner(
            symbolicator: symbolicator,
            dsymPath: TestResources().crashDsymUrl.appendingPathComponent("Contents/Resources/DWARF/CovidCertificateVerifier").path,
            arch: "x86_64")
        let result = runner.run(on: contents)
        
        XCTAssert(result.contains("0x000000010b8c0c40 AppDelegate.completedOnboarding() (in CovidCertificateVerifier) (AppDelegate.swift:122)"))
        XCTAssert(result.contains("0x000000010b8d9f2e VerificationState.wasRevocationSkipped.getter (in CovidCertificateVerifier) (Verifier.swift:108)"))
    }
}
