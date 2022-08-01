import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

class RegexTests: XCTestCase {
    func test() throws {
        let string = """
                    4 (272 bytes) ROOT CYCLE: 0x7ff29c304500 [16]
                       3 (256 bytes) ROOT CYCLE: 0x7ff29c304630 [80]
                          CYCLE BACK TO 0x7ff29c304500 [16]
                          2 (176 bytes) 0x7ff29c305230 [144]
                             1 (32 bytes) 0x7ff29c304510 [32]
            """
        
        
        // NOT <LeakySwiftObject 0x6000024250e0>
        // BUT 0x6000024250e0
        let regex = try! NSRegularExpression(pattern: #"0x([0-9a-fA-F]+)\b(?!>)"#)
        let matches = regex.matches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.utf16.count))
        
        for match in matches {
            let range = match.range(at: 1)
            
            let start = String.Index.init(utf16Offset: range.lowerBound, in: string)
            let end = String.Index.init(utf16Offset: range.upperBound, in: string)
            
            let hex = string[start..<end]
            
            print(hex)
        }
        
    }
}
