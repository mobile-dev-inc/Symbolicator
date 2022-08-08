import Foundation

struct CrashReportSymbolicator: Symbolicator {

    var contents: Data

    init?(_ contents: Data) {
        let crashedThread = "Crashed Thread:".data(using: .utf8)!
        if contents.range(of: crashedThread) == nil {
            return nil
        }

        self.contents = contents
    }

    mutating func setAppName(_ appName: String) {
        let oldAppName = "ReportCrash"
        let oldAppNameData = oldAppName.data(using: .utf8)!
        while let range = contents.range(of: oldAppNameData) {
            contents[range] = appName.data(using: .utf8)!
        }
    }

    func stackFramesToSymbolize() -> [StackFrame] {
        let contentsString = String(data: contents, encoding: .utf8)!

        let start = contentsString.range(of: "\nThread")?.upperBound ?? contentsString.startIndex
        let end = contentsString.range(of: "Binary Images:")?.lowerBound ?? contentsString.endIndex

        return findUnsymbolicatedStackFramesInLegacyFormat(in: String(contentsString[start..<end]))
    }

    mutating func addSymbolsToStackFrames(_ stackFrames: [(StackFrame, String)]) {
        for (address, symbol) in stackFrames {
            let search = address.tag.data(using: .utf8)!
            let a = "0x" + String(address.offset + address.base, radix: 16, uppercase: false)
                .padLeft(toLength: 16, withPad: "0")
            
            let replace = a + " " + symbol
            let replaceData = replace.data(using: .utf8)!

            while let range = contents.range(of: search) {
                contents[range] = replaceData
            }
        }
    }

    var jsonContents: Data {
        get throws {
            throw SymbolicatorError("--json option is unsupported for crash reports")
        }
    }
}

private extension String {
    func padLeft(toLength: Int, withPad: String) -> String {
        if count >= toLength {
            return self
        } else {
            let padding = String(repeating: withPad, count: toLength - count)
            return padding + self
        }
    }
}
