import Foundation

struct CrashFileParserResult: Codable {
    let contents: String
    let threads: [ThreadBlock]
}
