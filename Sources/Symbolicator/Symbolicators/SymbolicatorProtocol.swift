import Foundation

protocol SymbolicatorProtocol {

    var contents: Data { get }
    var jsonContents: Data { get throws }

    init?(_ contents: Data)

    mutating func setAppName(_ appName: String)

    func stackFramesToSymbolize() throws -> [StackFrame]
    mutating func addSymbolsToStackFrames(_ stackFrames: [(StackFrame, String)])

}
