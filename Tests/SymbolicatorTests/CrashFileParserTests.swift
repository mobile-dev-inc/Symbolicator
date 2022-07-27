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
        let parser = CrashFileParser(data: Data(),
                                     appName: "MobileDev")
        XCTAssertThrowsError(try parser.parse()) { error in
            XCTAssertEqual(error as! CrashFileParserError, CrashFileParserError.emptyFile)
        }
    }
    
    func test() {
        let parser = CrashFileParser(data: data,
                                     appName: "MobileDev")
        try! parser.parse()
    }
}
