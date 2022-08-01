import Foundation

enum LeakOccurence {
    case root(LeakRoot)
    case cycle(LeakCycle)
}
