import Foundation

struct CrashReportSymbolicator: Symbolicator {
    let appName: String
    let swappedAppCrashFileContents: String

    init(contents: String, appName: String) {
        self.swappedAppCrashFileContents = contents.replacingOccurrences(of: "ReportCrash", with: appName)
        self.appName = appName
    }
    
    func getLoadAddress() -> String {
        let regex = try! NSRegularExpression(pattern: #"\s*\d+\s+\S*\#(appName)\s+0x\w+\s(\w+)\s+"#)

        let range = NSRange(location: 0, length: swappedAppCrashFileContents.utf16.count)
        
        guard let match = regex.firstMatch(in: swappedAppCrashFileContents, range: range) else {
            fatalError()
        }
        
        let matchRange = match.range(at: 1)
        
        let start = String.Index.init(utf16Offset: matchRange.lowerBound, in: swappedAppCrashFileContents)
        let end = String.Index.init(utf16Offset: matchRange.upperBound, in: swappedAppCrashFileContents)
        
        return String(swappedAppCrashFileContents[start..<end])
    }

    func getUnsymbolizedAddresses() -> [String] {
        let loadAddress = getLoadAddress()
        
        let regex0 = try! NSRegularExpression(pattern: #"\nThread"#)
        let fullStringRange = NSRange(location: 0, length: swappedAppCrashFileContents.utf16.count)
        guard let match0 = regex0.firstMatch(in: swappedAppCrashFileContents, range: fullStringRange) else {
            fatalError()
        }
        
        let regex1 = try! NSRegularExpression(pattern: #"Binary Images:"#)
        guard let match1 = regex1.firstMatch(in: swappedAppCrashFileContents, range: fullStringRange) else {
            fatalError()
        }
        
        // Search after the headers and before the Binary Images
        let range = NSRange(
            location: match0.range.upperBound,
            length: match1.range.lowerBound)
        
        // Mach: 0x6000024250e0
        // But don't match: <LeakySwiftObject 0x6000024250e0>
        let regex = try! NSRegularExpression(pattern: #"(0x[0-9a-fA-F]+) \#(loadAddress) +"#)
        
        let matches = regex.matches(
            in: swappedAppCrashFileContents,
            options: [],
            range: range)
                
        let result = matches.map { match -> String in
            let range = match.range(at: 1)
            
            let start = String.Index.init(utf16Offset: range.lowerBound, in: swappedAppCrashFileContents)
            let end = String.Index.init(utf16Offset: range.upperBound, in: swappedAppCrashFileContents)
            
            return String(swappedAppCrashFileContents[start..<end])
        }
        
        return Array(Set(result))
    }
}

