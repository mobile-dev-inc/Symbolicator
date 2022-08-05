import Foundation

protocol Symbolicator {
    func getLoadAddress() throws -> String
    func getUnsymbolizedAddresses() throws -> [String]
}
