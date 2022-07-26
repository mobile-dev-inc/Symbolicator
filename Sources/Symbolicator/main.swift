import Foundation
import ArgumentParser

struct Symbolicator: ParsableCommand {
    @Argument(help: "Dsym file")
    var dsymArgument: String

    @Argument(help: "Input file")
    var inputFileArgument: String
    
    mutating func run() throws {
        print("Mobile.dev!")
        
        let inputData: Data
        if inputFileArgument == "-" {
            var buffer = Data()
            while (FileHandle.standardInput.availableData.count > 0) {
                buffer.append(FileHandle.standardInput.availableData)
            }
            
            inputData = buffer
        } else {
            let url = URL(fileURLWithPath: inputFileArgument)
            inputData = try Data(contentsOf: url)
        }

        guard FileManager().fileExists(atPath: dsymArgument) else {
            throw ValidationError("")
        }
        
        print(inputData)
    }
}

Symbolicator.main()
