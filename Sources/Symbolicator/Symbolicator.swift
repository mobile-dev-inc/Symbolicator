import Foundation

protocol Symbolicator {
    init(_: String)
    func getLoadAddress() -> String
    func getUnsymbolizedAddresses() -> [String]
}
