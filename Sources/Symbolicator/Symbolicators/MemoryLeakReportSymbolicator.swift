import Foundation

struct MemoryLeakReportSymbolicator: Symbolicator {

    var contents: Data

    init?(_ contents: Data) {
        let leakReport = "leaks Report Version".data(using: .utf8)!
        if contents.range(of: leakReport) == nil {
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

        let start = contentsString.range(of: "\n----\n")?.upperBound ?? contentsString.startIndex
        let end = contentsString.range(of: "Binary Images:")?.lowerBound ?? contentsString.endIndex

        return findUnsymbolicatedStackFramesInLegacyFormat(in: String(contentsString[start..<end]))
    }

    mutating func addSymbolsToStackFrames(_ stackFrames: [(StackFrame, String)]) {
        for (address, symbol) in stackFrames {
            let search = address.tag.data(using: .utf8)!
            let replace = address.address + " " + symbol
            let replaceData = replace.data(using: .utf8)!

            while let range = contents.range(of: search) {
                contents[range] = replaceData
            }
        }
    }

    var jsonContents: Data {
        get throws {
            let report = try MemoryLeakReportParser().parse(String(data: contents, encoding: .utf8)!)
            return try JSONEncoder().encode(report)
        }
    }
}
