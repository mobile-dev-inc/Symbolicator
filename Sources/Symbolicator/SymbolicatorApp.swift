import Foundation
import ArgumentParser

@main
struct SymbolicatorApp: ParsableCommand {
    @Argument(help: "Dsym file")
    var dsymArgument: String

    @Argument(help: "Input file")
    var inputFileArgument: String
    
    @Option(help: "App name")
    var appName: String?
    
    @Option(help: "Build architecture")
    var arch: String = "x86_64"

    @Flag(help: "JSON output")
    var json = false
    
    mutating func run() throws {
        printStderr("Symbolicator, arguments:")
        printStderr("   \(dsymArgument)")
        printStderr("   \(inputFileArgument)")
        
//        guard FileManager().fileExists(atPath: dsymArgument) else {
//            throw ValidationError("Dsym file not found")
//        }
        
        let inputData: Data
        if inputFileArgument == "-" {
            var buffer = Data()
            while (FileHandle.standardInput.availableData.count > 0) {
                buffer.append(FileHandle.standardInput.availableData)
            }
            
            inputData = buffer
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
            let symbolicator = MemoryLeakReportSymbolicator(contents)
            let runner = SymbolicatorRunner(symbolicator: symbolicator, dsymPath: dsymArgument, arch: arch)
            let result = runner.run(on: contents)
            
            if json {
                do {
                    let report = try MemoryLeakParser().parse(result)
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
            let appName = appName ?? "CrashReporter"
            let symbolicator = CrashReportSymbolicator(contents: contents, appName: appName)
            let runner = SymbolicatorRunner(symbolicator: symbolicator, dsymPath: dsymArgument, arch: arch)
            let result = runner.run(on: symbolicator.swappedAppCrashFileContents)
            print(result)
        }
    }
}
