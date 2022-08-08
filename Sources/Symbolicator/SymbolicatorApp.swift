import Foundation
import ArgumentParser
import GenericJSON

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
            try symbolicateLegacyCrashReport(contents)
        } else if contents.hasPrefix("{"),
            let firstNewline = contents.firstIndex(of: "\n"),
                  contents[contents.index(before: firstNewline)] == "}" {
            try symbolicateIPSCrashReport(from: inputData)
        } else {
            throw SymbolicatorAppError("Unrecognised file format")
        }
    }

    fileprivate func symbolicateMemoryLeakReport(_ contents: String) throws {
        let result: String
        if let dsymFile = dsymFile {
            let symbolicator = MemoryLeakReportSymbolicator(contents)
            let runner = SymbolicatorRunner(symbolicator: symbolicator, dsymPath: dsymFile, arch: arch)
            result = try runner.run(on: contents)
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

    fileprivate func symbolicateLegacyCrashReport(_ contents: String) throws {
        if let dsymFile = dsymFile {
            let appName = appName ?? "CrashReporter"
            let symbolicator = CrashReportSymbolicator(contents: contents, appName: appName)
            let runner = SymbolicatorRunner(symbolicator: symbolicator, dsymPath: dsymFile, arch: arch)
            let result = try runner.run(on: symbolicator.swappedAppCrashFileContents)
            print(result)
        } else {
            print(contents)
        }
    }

    fileprivate func symbolicateIPSCrashReport(from data: Data) throws {
        let newline = Character("\n").asciiValue!
        let newlineIndex = data.firstIndex(of: newline)!

        let decoder = JSONDecoder()
        let header = try decoder.decode([String: JSON].self, from: data[..<newlineIndex])
        var body = try decoder.decode([String: JSON].self, from: data[newlineIndex...])

        for threadIndex in body["threads"]!.arrayValue!.indices {
            let thread = body["threads"]!.arrayValue![threadIndex]
            let frames = thread["frames"]!.arrayValue!

            for frameIndex in frames.indices {
                let frame = frames[frameIndex].objectValue!
                if frame["symbol"]?.stringValue != nil { continue }

                let usedImages = body["usedImages"]!.arrayValue!
                let imageIndex = Int(frame["imageIndex"]!.doubleValue!)
                let image = usedImages[imageIndex].objectValue!
                let base = Int(image["base"]!.doubleValue!)

                let imageOffset = Int(frame["imageOffset"]!.doubleValue!)
                let loadAddress = String(base, radix: 16, uppercase: false)
                let address = String(base + imageOffset, radix: 16, uppercase: false)

                let symbol = try atos(
                    dsymFile!,
                    arch: arch,
                    loadAddress: "0x" + loadAddress,
                    address: "0x" + address)

                body["threads"]!
                    .arrayValue![threadIndex]["frames"]!
                    .arrayValue![frameIndex]["symbol"] = try JSON(symbol)
            }
        }

        let headerData = try JSONEncoder().encode(header)
        let bodyEncoder = JSONEncoder()
        bodyEncoder.outputFormatting = .prettyPrinted
        let bodyData = try bodyEncoder.encode(body)

        var result = headerData
        result.append(contentsOf: [newline])
        result.append(contentsOf: bodyData)
        print(String(data: result, encoding: .utf8)!)
    }
}

struct SymbolicatorAppError: Error, CustomStringConvertible {
    let description: String
    init(_ message: String) {
        self.description = message
    }
}
