import Foundation

func atos(_ dsymPath: String,
          arch: String,
          loadAddress: String,
          address: String) throws -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.launchPath = "/usr/bin/atos"
    task.arguments = ["-o", dsymPath, "-arch", arch, "-l", loadAddress, address]
    task.standardInput = nil

    printStderr((task.launchPath ?? "") + " " + (task.arguments?.joined(separator: " ") ?? ""))
    
    try task.run()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}
