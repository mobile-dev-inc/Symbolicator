import Foundation
import Parsing

struct HexDecimal: Parser {
    func parse(_ input: inout Substring) throws -> Int {
        // Fail if the 0x is not present
        guard input.hasPrefix("0x") || input.hasPrefix("0X") else {
            throw ParsingError.expectedInput("0x", at: input)
        }
        input = input.dropFirst(2)
        
        // Consume any characters that can be represented as a hex digit
        var nibbles = [Int]()
        while let hexDigit = input.first?.hexDigitValue {
            input.removeFirst()
            nibbles.append(hexDigit)
        }
        
        guard !nibbles.isEmpty else {
            throw ParsingError.expectedInput("hex decimal digit", at: input)
        }
        
        var value = 0
        var nibbleOffset = 1
        for nibble in nibbles.reversed() {
            let fourBitValue = nibble
            value += fourBitValue * nibbleOffset
            nibbleOffset <<= 4
        }
        
        return value
    }
}
