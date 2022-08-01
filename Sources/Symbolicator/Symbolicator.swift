import Foundation

protocol Symbolicator {
    func getLoadAddress(_: String) -> String
    func getUnsymbolizedAddresses(_: String) -> [String]
}
