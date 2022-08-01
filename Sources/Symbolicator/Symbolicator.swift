import Foundation

protocol Symbolicator {
    func getLoadAddress() -> String
    func getUnsymbolizedAddresses() -> [String]
}
