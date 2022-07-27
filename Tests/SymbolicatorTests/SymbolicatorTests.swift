import XCTest
import class Foundation.Bundle

final class SymbolicatorTests: XCTestCase {
    
    func runProcess(setup: (Process) -> (), test: (String, String) -> ()) throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        // Mac Catalyst won't have `Process`, but it is supported for executables.
        #if !targetEnvironment(macCatalyst)

        print(productsDirectory)
        let binary = productsDirectory.appendingPathComponent("Symbolicator")
        
        let process = Process()
        process.executableURL = binary

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        setup(process)
        
        try process.run()
        process.waitUntilExit()

        let output = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!
        let error = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!
        
        test(output, error)
        #endif
    }
    
    func testExample() throws {
        try runProcess { process in
            process.arguments = [
                TestResounces().dsymUrl.path,
                TestResounces().memoryLeakUrl.path,
            ]
        } test: { output, error in
            XCTAssertEqual(output, "")
            XCTAssertEqual(error, "")
        }
    }

    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }
}
