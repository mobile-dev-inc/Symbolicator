import Foundation

struct SymbolicatorRunner<S: Symbolicator> {
    let symbolicator: S
    let dsymPath: String
    let arch: String
        
    func run(on string: String) -> String {
        var string = string
        let loadAddress = symbolicator.getLoadAddress(string)
        
        for address in symbolicator.getUnsymbolizedAddresses(string) {
            let symbolized = try! atos(dsymPath, arch: arch, loadAddress: loadAddress, address: address)
            print(symbolized)
            
            string = string.replacingOccurrences(of: address + " " + loadAddress, with: address + " " + symbolized)
        }
        
        return string
    }
}
