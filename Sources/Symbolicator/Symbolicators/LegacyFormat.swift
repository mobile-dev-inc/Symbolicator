import Foundation

func findUnsymbolicatedStackFramesInLegacyFormat(in string: String) -> [StackFrame] {
    // Mach: 0x6000024250e0 0x6000024250e0 +
    // But don't match: <LeakySwiftObject 0x6000024250e0>
    let regex = try! NSRegularExpression(pattern: #"(0x[0-9a-fA-F]+) (0x[0-9a-fA-F]+)(?= \+)"#)

    let range = NSRange(string.startIndex..<string.endIndex, in: string)
    let matches = regex.matches(in: string, options: [], range: range)

    return matches.map { match -> StackFrame in
        let nsString = string as NSString
        let tag = nsString.substring(with: match.range(at: 0))
        let address = nsString.substring(with: match.range(at: 1))
        let loadAddress = nsString.substring(with: match.range(at: 2))
        return StackFrame(tag: tag, loadAddress: loadAddress, address: address)!
    }
}
