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
    
    func run() {
        do {
            try symbolicate()
        } catch let error {
            printStderr("Error:", error)
            Foundation.exit(1)
        }
    }

    func symbolicate() throws {
        let inputData: Data
        if inputFileArgument == "-" {
            guard let data = try FileHandle.standardInput.readToEnd() else {
                throw SymbolicatorAppError("Error reading from stdin")
            }

            inputData = data
        } else {
            let url = URL(fileURLWithPath: inputFileArgument)
            guard FileManager().fileExists(atPath: inputFileArgument) else {
                throw ValidationError("Input file not found at \(inputFileArgument)")
            }

            inputData = try Data(contentsOf: url)
        }

        guard let contents = String(data: inputData, encoding: .utf8) else { fatalError() }

        if contents.contains("leaks Report Version") {
            try symbolicateMemoryLeakReport(contents)
        } else if contents.contains("Crashed Thread:") {
            symbolicateLegacyCrashReport(contents)
        } else {
            throw SymbolicatorAppError("Unrecognised file format")
        }
    }

    fileprivate func symbolicateMemoryLeakReport(_ contents: String) throws {
        let result: String
        if let dsymFile = dsymFile {
            let symbolicator = MemoryLeakReportSymbolicator(contents)
            let runner = SymbolicatorRunner(symbolicator: symbolicator, dsymPath: dsymFile, arch: arch)
            result = runner.run(on: contents)
        } else {
            result = contents
        }

        guard json else {
            print(result)
            return
        }

        let report = try MemoryLeakReportParser().parse(result)
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(report)
        
        print(String(data: encoded, encoding: .utf8)!)
    }

    fileprivate func symbolicateLegacyCrashReport(_ contents: String) {
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

struct SymbolicatorAppError: Error, CustomStringConvertible {
    let description: String
    init(_ message: String) {
        self.description = message
    }
}
