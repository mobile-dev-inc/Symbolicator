import XCTest
import class Foundation.Bundle
@testable import Symbolicator

final class SymbolicatorTests: XCTestCase {
    
    func runProcess(setup: (Process) throws -> ()) throws -> (Int32, String, String) {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            fatalError()
        }
        
        // Mac Catalyst won't have `Process`, but it is supported for executables.
        #if !targetEnvironment(macCatalyst)

        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        var stdoutData = Data()
        var stderrData = Data()

        process.executableURL = productsDirectory.appendingPathComponent("Symbolicator")
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try setup(process)
        
        try process.run()
        
        DispatchQueue(label: "timer").async {
            usleep(20_000_000)
            if process.isRunning {
                print(String(data: stdoutData, encoding: .utf8)!)
                print(String(data: stderrData, encoding: .utf8)!)
                process.terminate()
            }
        }
        
        DispatchQueue(label: "reader").async {
            while process.isRunning {
                let stdoutAvailableData = stdoutPipe.fileHandleForReading.availableData
                if !stdoutAvailableData.isEmpty {
                    stdoutData.append(contentsOf: stdoutAvailableData)
                }
                
                let stderrAvailableData = stderrPipe.fileHandleForReading.availableData
                if !stderrAvailableData.isEmpty {
                    stderrData.append(contentsOf: stderrAvailableData)
                }
            }
        }
        
        process.waitUntilExit()
        
        let status = process.terminationStatus

        let output = String(data: stdoutData, encoding: .utf8)!
        let error = String(data: stderrData, encoding: .utf8)!
        
        return (status, output, error)
        
        #endif
    }
    
    func testJSONOutput() throws {
        let (status, output, _) = try runProcess { process in
            process.arguments = [
                TestResources().memoryLeakNoStackUrl.path,
                "--json"
            ]
        }
        
        XCTAssertEqual(status, 0)
        let decoder = JSONDecoder()
        
        let data = output.data(using: .utf8)!
        
        let report = AssertNoThrow {
            try decoder.decode(MemoryLeakReport.self, from: data)
        }
        
        XCTAssert(report?.leaks.first?.objectGraph.contains("1 (32 bytes) ROOT LEAK: <LeakySwiftObject 0x600001440440> [32]") ?? false)
    }
    
    func testStdin() throws {
        let (status, output, _) = try runProcess { process in
            process.arguments = [
                "-",
            ]
            
            let data = try Data(contentsOf: TestResources().memoryLeakNoStackUrl)
            let pipe = Pipe()
            process.standardInput = pipe
            try pipe.fileHandleForWriting.write(contentsOf: data)
            pipe.fileHandleForWriting.closeFile()
        }
        
        XCTAssertEqual(status, 0)
        XCTAssert(output.contains("1 (32 bytes) ROOT LEAK: <LeakySwiftObject 0x600001440440> [32]"))
    }

    /*
     The Symbolicator executable hangs while printing to stdout.
     I attempted to read and flush the stdout pipe to no avail..

     Stack of the Symbolicator process, while timing out:
     (lldb) bt
     * thread #1, queue = 'com.apple.main-thread', stop reason = signal SIGSTOP
       * frame #0: 0x00007ff81370c9ce libsystem_kernel.dylib`__write_nocancel + 10
         frame #1: 0x00007ff813624ee5 libsystem_c.dylib`_swrite + 87
         frame #2: 0x00007ff8136163bb libsystem_c.dylib`__sfvwrite + 510
         frame #3: 0x00007ff813637d0c libsystem_c.dylib`fwrite + 136
         frame #4: 0x00007ff820d2b572 libswiftCore.dylib`Swift._Stdout.write(Swift.String) -> () + 146
         frame #5: 0x00007ff820d2b689 libswiftCore.dylib`protocol witness for Swift.TextOutputStream.write(Swift.String) -> () in conformance Swift._Stdout : Swift.TextOutputStream in Swift + 9
         frame #6: 0x00007ff820c9b72e libswiftCore.dylib`Swift._print_unlocked<τ_0_0, τ_0_1 where τ_0_1: Swift.TextOutputStream>(τ_0_0, inout τ_0_1) -> () + 494
         frame #7: 0x00007ff820d32120 libswiftCore.dylib`merged generic specialization <Swift._Stdout> of Swift._print<τ_0_0 where τ_0_0: Swift.TextOutputStream>(_: Swift.Array<Any>, separator: Swift.String, terminator: Swift.String, to: inout τ_0_0) -> () + 464
         frame #8: 0x00007ff820d30d12 libswiftCore.dylib`merged Swift.print(_: Any..., separator: Swift.String, terminator: Swift.String) -> () + 194
         frame #9: 0x000000010000e0c6 Symbolicator`SymbolicatorApp.parse(data=131114 bytes, self=Symbolicator.SymbolicatorApp @ 0x00007ff7bfefea70) at SymbolicatorApp.swift:74:17
         frame #10: 0x000000010000d5db Symbolicator`SymbolicatorApp.run(self=Symbolicator.SymbolicatorApp @ 0x0000000100b0a3b0) at SymbolicatorApp.swift:45:9
         frame #11: 0x0000000100010c7d Symbolicator`protocol witness for ParsableCommand.run() in conformance SymbolicatorApp at <compiler-generated>:0
         frame #12: 0x0000000100061669 Symbolicator`static ParsableCommand.main(arguments=nil, self=Symbolicator.SymbolicatorApp) at ParsableCommand.swift:136:19
         frame #13: 0x0000000100061d57 Symbolicator`static ParsableCommand.main(self=Symbolicator.SymbolicatorApp) at ParsableCommand.swift:153:10
         frame #14: 0x000000010000ecfe Symbolicator`static SymbolicatorApp.$main(self=Symbolicator.SymbolicatorApp) at SymbolicatorApp.swift:4:1
         frame #15: 0x0000000100010e59 Symbolicator`main at SymbolicatorApp.swift:0
         frame #16: 0x000000010071151e dyld`start + 462


    func testSymbolication() throws {
        let (status, output, _) = try runProcess { process in
            process.arguments = [
                TestResources().memoryLeakUnsymbolicatedUrl.path,
//                "--dsym-file", TestResources().dsymUrl.path
            ]
        }

        XCTAssertEqual(status, 0)
//        XCTAssert(output.contains("0x102d6026e main (in MemoryLeakingApp) (<compiler-generated>:0)"))
    }
     */
    
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

func AssertNoThrow<T>(_ code: () throws -> T) -> T? {
    do {
        return try code()
    } catch {
        XCTFail("AssertNoThrow did throw: \(error)")
        return nil
    }
}
