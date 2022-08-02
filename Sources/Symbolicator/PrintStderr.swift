import Foundation

func printStderr(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let output = items
        .map { String(describing: $0) }
        .joined(separator: separator)
    
    FileHandle.standardError.write(output.data(using: .utf8)!)
}
