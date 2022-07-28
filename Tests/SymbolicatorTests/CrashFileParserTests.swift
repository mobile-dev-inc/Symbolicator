import XCTest
@testable import Symbolicator

class CrashFileParserTests: XCTestCase {
    private var data: Data!
    
    override func setUpWithError() throws {
        data = try Data(contentsOf: TestResources().nonSymbolicatedCrashUrl)
    }

    override func tearDownWithError() throws {
        data = nil
    }
    
    func testEmptyFileExceptionThrown_whenDataIsEmpty() {
        var parser = CrashFileParser(data: Data(),
                                     appName: "MobileDev",
                                     dsymPath: "123")
        XCTAssertThrowsError(try parser.parse()) { error in
            XCTAssertEqual(error as! CrashFileParserError, CrashFileParserError.emptyFile)
        }
    }
    
    func testParserProvidesCorrectResults_whenDsymAndCrashfileAreValid() {
        var parser = CrashFileParser(data: data,
                                     appName: "CovidCertificateVerifier",
                                     dsymPath: TestResources().crashDsymUrl.path)
        let result = try! parser.parse()
        
        XCTAssertEqual(result.threads.count, 6)
        XCTAssertFalse(result.contents.isEmpty)
    
        // check one symbolicated and one non-symbolicated line
        XCTAssertTrue(result.threads.first!.lines[7].contains("static VerificationError.__derived_enum_less_than(_:_:) (in CovidCertificateVerifier)"))
        XCTAssertEqual(result.threads.first!.header, "Thread 0:: Dispatch queue: com.apple.main-thread")
        XCTAssertEqual(result.threads.first!.lines.first!, "0   libsystem_kernel.dylib            0x00007ff8187dd97a mach_msg_trap + 10")
        
        result.threads.forEach {
            XCTAssertFalse($0.header.isEmpty)
            XCTAssertFalse($0.lines.first!.isEmpty)
        }
    }
}
