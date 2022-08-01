import Foundation

struct CrashReportParser: Symbolicator {
    let crashFile: String
    init(_ crashFile: String) {
        self.crashFile = crashFile
    }
    
    func getLoadAddress() -> String {
        let appName = getAppName()
        
        // 7   ReportCrash                       0x000000010b8d9514 0x10b8b8000 + 136468

        let regex = try! NSRegularExpression(pattern: #"\s*\d+\s+\#(appName)0x\w+\s(\w+)\s+"#)

        let range = NSRange(location: 0, length: crashFile.utf16.count)
        
        guard let match = regex.firstMatch(in: crashFile, range: range) else {
            fatalError()
        }
        
        let matchRange = match.range(at: 1)
        
        let start = String.Index.init(utf16Offset: matchRange.lowerBound, in: crashFile)
        let end = String.Index.init(utf16Offset: matchRange.upperBound, in: crashFile)
        
        return String(crashFile[start..<end])
    }
    

    func getAppName() -> String {
        let regex = try! NSRegularExpression(pattern: #"Process:\s+(\w+)\s"#)

        let range = NSRange(location: 0, length: crashFile.utf16.count)
        
        guard let match = regex.firstMatch(in: crashFile, range: range) else {
            fatalError()
        }
        
        let matchRange = match.range(at: 1)
        
        let start = String.Index.init(utf16Offset: matchRange.lowerBound, in: crashFile)
        let end = String.Index.init(utf16Offset: matchRange.upperBound, in: crashFile)
        
        return String(crashFile[start..<end])
    }

    func getUnsymbolizedAddresses() -> [String] {
        let loadAddress = getLoadAddress()
        
        let regex0 = try! NSRegularExpression(pattern: #"\nThread"#)
        let fullStringRange = NSRange(location: 0, length: crashFile.utf16.count)
        guard let match0 = regex0.firstMatch(in: crashFile, range: fullStringRange) else {
            fatalError()
        }
        
        let regex1 = try! NSRegularExpression(pattern: #"Binary Images:"#)
        guard let match1 = regex1.firstMatch(in: crashFile, range: fullStringRange) else {
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
            in: crashFile,
            options: [],
            range: range)
                
        let result = matches.map { match -> String in
            let range = match.range(at: 1)
            
            let start = String.Index.init(utf16Offset: range.lowerBound, in: crashFile)
            let end = String.Index.init(utf16Offset: range.upperBound, in: crashFile)
            
            return String(crashFile[start..<end])
        }
        
        return Array(Set(result))
    }

}

