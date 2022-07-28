import Foundation

struct ThreadBlock: Codable {
    let header: String
    let appName: String
    private(set) var lines: [String] = []
    
    var hasAppLines: Bool {
        lines.count > 1
    }
    
    mutating func appendLine(line: String) {
        lines.append(line)
    }
}
