import Foundation
import ArgumentParser
import GenericJSON

@main
struct Symbolicator: ParsableCommand {
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
                throw SymbolicatorError("Error reading from stdin")
            }

            inputData = data
        } else {
            let url = URL(fileURLWithPath: inputFileArgument)
            guard FileManager().fileExists(atPath: inputFileArgument) else {
                throw ValidationError("Input file not found at \(inputFileArgument)")
            }

            inputData = try Data(contentsOf: url)
        }

        let symbolicatorTypes: [SymbolicatorProtocol.Type] = [
            CrashReportSymbolicator.self,
            MemoryLeakReportSymbolicator.self,
            IPSSymbolicator.self
        ]

        let applicableSymbolicators = symbolicatorTypes.compactMap { symbolicatorType in
            symbolicatorType.init(inputData)
        }

        guard applicableSymbolicators.count == 1 else {
            throw SymbolicatorError("Expecting one symbolicator to match, found \(symbolicatorTypes.count)")
        }

        var symbolicator = applicableSymbolicators[0]

        let stackFrames = try symbolicator.stackFramesToSymbolize()
        if let dsymFile = dsymFile {
            let atos = AddressToSymbol(dsymFile: dsymFile, arch: arch)
            let symbolized = try atos.symbols(for: stackFrames)
            symbolicator.addSymbolsToStackFrames(symbolized)
        }

        if json {
            let jsonData = try symbolicator.jsonContents
            try FileHandle.standardOutput.write(contentsOf: jsonData)
        } else {
            try FileHandle.standardOutput.write(contentsOf: symbolicator.contents)
        }
    }
}
