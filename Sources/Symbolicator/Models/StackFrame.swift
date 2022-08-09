import Foundation

struct StackFrame {
    let tag: String
    let base: Int
    let offset: Int

    init(tag: String, base: Int, offset: Int) {
        self.tag = tag
        self.base = base
        self.offset = offset
    }

    init?(tag: String, loadAddress: String, address: String) {
        self.tag = tag

        var loadAddress = loadAddress
        if loadAddress.hasPrefix("0x") { loadAddress.removeFirst(2) }

        var address = address
        if address.hasPrefix("0x") { address.removeFirst(2) }

        guard let base = Int(loadAddress, radix: 16),
              let addressInt = Int(address, radix: 16) else {
            return nil
        }
        self.base = base
        self.offset = addressInt - base
    }

    var loadAddress: String { "0x" + String(base, radix: 16, uppercase: false) }

    var address: String { "0x" + String(offset + base, radix: 16, uppercase: false) }
}
