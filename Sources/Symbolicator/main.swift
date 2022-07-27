import Foundation
import ArgumentParser

struct Symbolicator: ParsableCommand {
    @Argument(help: "Dsym file")
    var dsymArgument: String

    @Argument(help: "Input file")
    var inputFileArgument: String
    
    mutating func run() throws {
        print("Symbolicator, arguments:")
        print("   \(dsymArgument)")
        print("   \(inputFileArgument)")
        
//        guard FileManager().fileExists(atPath: dsymArgument) else {
//            throw ValidationError("Dsym file not found")
//        }
        
        let inputData: Data
        if inputFileArgument == "-" {
            var buffer = Data()
            while (FileHandle.standardInput.availableData.count > 0) {
                buffer.append(FileHandle.standardInput.availableData)
            }
            
            inputData = buffer
        } else {
            let url = URL(fileURLWithPath: inputFileArgument)
            guard FileManager().fileExists(atPath: inputFileArgument) else {
                throw ValidationError("Input file not found at \(inputFileArgument)")
            }
            
            
            inputData = try Data(contentsOf: url)
        }


        parse(inputData)
    }
    
    func parse(_ data: Data) {
        print(MemoryLeakParser(data: data).parse())
    }
}

Symbolicator.main()
