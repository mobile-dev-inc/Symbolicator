//
//  File.swift
//  
//
//  Created by Berik Visschers on 2022-07-25.
//

import Foundation

class TestResounces {
    
    static let shared = TestResounces()
    
    let memoryLeakUrl = Bundle.module.url(forResource: "memory_leak", withExtension: "txt")!
    let dsymUrl = Bundle.module.url(forResource: "MemoryLeakingApp.app", withExtension: "dSYM")!
}
