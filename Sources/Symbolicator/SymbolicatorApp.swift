import Foundation
import ArgumentParser

@main
struct SymbolicatorApp: ParsableCommand {
    @Argument(help: "Dsym file")
    var dsymArgument: String

    @Argument(help: "Input file")
    var inputFileArgument: String
    
    @Argument(help: "App name")
    var appName: String
    
    mutating func run() throws {
        print("Symbolicator, arguments:")
        print("   \(dsymArgument)")
        print("   \(inputFileArgument)")
        
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
            let symbolicator = MemoryLeakReportParser(contents)
            let runner = SymbolicatorRunner(symbolicator: symbolicator, dsymPath: dsymArgument, arch: "x86_64")
            let result = runner.run(on: contents)
            print(result)
        } else if contents.contains("Crashed Thread:") {
            let symbolicator = CrashReportParser(contents: contents, appName: appName)
            let runner = SymbolicatorRunner(symbolicator: symbolicator, dsymPath: dsymArgument, arch: "x86_64")
            let result = runner.run(on: symbolicator.swappedAppCrashFileContents)
            print(result)
        }
    }
}
