import Foundation

struct AddressToSymbol {
    let dsymFile: String
    let arch: String

    func symbols(for stackFrames: [StackFrame]) throws -> [(StackFrame, String)] {
        var byLoadAddress = [String: [StackFrame]]()

        for stackFrame in stackFrames {
            byLoadAddress[stackFrame.loadAddress, default: []]
                .append(stackFrame)
        }

        var result = [(StackFrame, String)]()
        for (loadAddress, stackFrames) in byLoadAddress {
            let addresses = stackFrames.map { $0.address }
            let symbols = try symbolsFor(loadAddress: loadAddress, addresses: addresses)
            result += zip(stackFrames, symbols)
        }

        return result
    }

    func symbolsFor(loadAddress: String, addresses: [String]) throws -> [String] {
        let task = Process()
        let pipe = Pipe()
    
        task.standardOutput = pipe
        task.standardError = pipe
        task.launchPath = "/usr/bin/atos"
        task.arguments = ["-o", dsymFile, "-arch", arch, "-l", loadAddress] + addresses
        task.standardInput = nil

        printStderr((task.launchPath ?? "") + " " + (task.arguments?.joined(separator: " ") ?? ""))

        try task.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let symbols = String(data: data, encoding: .utf8)!
        return symbols.split(separator: "\n").map { String($0) }
    }
}
