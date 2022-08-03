import Foundation

struct Leak: Codable {
    let name: String?
    let occurrenceCount: Int
    let totalLeakedBytes: Int
    let stack: String?
    let objectGraph: String
}
