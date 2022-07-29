import Foundation

struct StackFrame {
    let stackIndex: Int
    let frameworkName: String
    let address: Int
    let name: String?
    let loadAddress: Int?
    let offset: Int
    let origin: String?
}

