import Foundation

struct Leak: Codable {
    let name: String?
    let totalLeakedBytes: Int
    let stack: String?
    let objectGraph: String
}
