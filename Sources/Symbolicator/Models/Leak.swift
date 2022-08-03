import Foundation

struct Leak: Codable {
    let name: String?
    let occuranceCount: Int
    let totalLeakedBytes: Int
    let stack: String?
    let objectGraph: String
}
