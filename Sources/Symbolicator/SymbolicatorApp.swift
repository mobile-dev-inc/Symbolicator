import Foundation
import ArgumentParser

@main
struct SymbolicatorApp: ParsableCommand {
    @Argument(help: "Input file")
    var inputFileArgument: String
    
    @Option(help: "Dsym file, will attempt to symbolize if passed")
    var dsymFile: String?

    @Option(help: "App name")
    var appName: String?
    
    @Option(help: "Build architecture")
    var arch: String = "x86_64"

    @Flag(help: "JSON output")
    var json = false
    
    mutating func run() throws {
        printStderr("Symbolicator, arguments:")
        printStderr("   dsym: \(dsymFile ?? "none")")
        printStderr("   file: \(inputFileArgument)")
        
        let inputData: Data
        if inputFileArgument == "-" {
            printStderr("Reading from stdin")
            
            guard let data = try FileHandle.standardInput.readToEnd() else {
                throw ReadError()
            }
            
            inputData = data
        } else {
            let url = URL(fileURLWithPath: inputFileArgument)
            guard FileManager().fileExists(atPath: inputFileArgument) else {
                throw ValidationError("Input file not found at \(inputFileArgument)")
            }
            
            inputData = try Data(contentsOf: url)
        }


        parse(inputData)
    }
    
    func parse(_ data: Data) {
        guard let contents = String(data: data, encoding: .utf8) else { fatalError() }
            
        if contents.contains("leaks Report Version") {
            let result: String
            if let dsymFile = dsymFile {
                let symbolicator = MemoryLeakReportSymbolicator(contents)
                let runner = SymbolicatorRunner(symbolicator: symbolicator, dsymPath: dsymFile, arch: arch)
                result = runner.run(on: contents)
            } else {
                result = contents
            }
            
            if json {
                do {
                    let report = try MemoryLeakReportParser().parse(result)
                    let encoder = JSONEncoder()
                    let encoded = try encoder.encode(report)

                    print(String(data: encoded, encoding: .utf8)!)
                    
                } catch {
                    printStderr("Failed to parse memory leak report \(error.localizedDescription)")
                    printStderr(error)
                }
            } else {
                print(result)
            }
            
        } else if contents.contains("Crashed Thread:") {
            if let dsymFile = dsymFile {
                let appName = appName ?? "CrashReporter"
                let symbolicator = CrashReportSymbolicator(contents: contents, appName: appName)
                let runner = SymbolicatorRunner(symbolicator: symbolicator, dsymPath: dsymFile, arch: arch)
                let result = runner.run(on: symbolicator.swappedAppCrashFileContents)
                print(result)
            } else {
                print(contents)
            }
        }
    }
}

struct ReadError: Error {}
