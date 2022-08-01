import XCTest
import class Foundation.Bundle
@testable import Symbolicator
import Parsing

final class MemoryLeakParserTests: XCTestCase {
    func test() throws {
        let data = try Data(contentsOf: TestResources().memoryLeakUnsymbolicatedUrl)
        guard let string = String(data: data, encoding: .utf8) else { fatalError() }

        let symbolicator = MemoryLeakParser(string)
        let runner = SymbolicatorRunner(
            symbolicator: symbolicator,
            dsymPath: TestResources().dsymUrl.appendingPathComponent("Contents/Resources/DWARF/MemoryLeakingApp").path,
            arch: "x86_64")
        let result = runner.run(on: string)
        print(result)
    }
}
