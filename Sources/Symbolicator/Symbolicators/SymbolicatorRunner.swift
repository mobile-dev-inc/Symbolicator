import Foundation

struct SymbolicatorRunner<S: Symbolicator> {
    let symbolicator: S
    let dsymPath: String
    let arch: String
        
    func run(on string: String) -> String {
        var string = string
        let loadAddress = symbolicator.getLoadAddress()
        
        for address in symbolicator.getUnsymbolizedAddresses() {
            let symbolized = try! atos(dsymPath, arch: arch, loadAddress: loadAddress, address: address)            
            string = string.replacingOccurrences(of: address + " " + loadAddress, with: address + " " + symbolized)
        }
        
        return string
    }
}
