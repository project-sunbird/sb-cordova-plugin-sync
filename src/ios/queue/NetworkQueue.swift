import Foundation

struct Heap<Element> {
    ///Store an array of elements
    var elements: [Element]
    // Compare the size of two elements
    let priorityFunction: (Element, Element) -> Bool
    
    init(elements: [Element] = [], priorityFunction: @escaping (Element, Element) -> Bool) { // 1 // 2
        self.elements = elements
        self.priorityFunction = priorityFunction // 3
        buildHeap() // 4
    }
    
    mutating func buildHeap() {
        for index in (0 ..< count / 2).reversed() { // 5
            siftDown(index) // 6
        }
    }
    
    var isEmpty : Bool {
        return elements.isEmpty
    }
    
    var count : Int {
        return elements.count
    }
    
    func peek() -> Element? {
        return elements.first
    }
    func isRoot(_ index: Int) -> Bool {
        return (index == 0)
    }
    ///The left child of the current node
    func leftChildIndex(of index: Int) -> Int {
        return (2 * index) + 1
    }
    ///The right child of the current node
    func rightChildIndex(of index: Int) -> Int {
        return (2 * index) + 2
    }
    ///The parent node of the current node
    func parentIndex(of index: Int) -> Int {
        return (index - 1) / 2
    }
    
    //insert
    mutating func equeue(_ element: Element) {
        elements.append(element)
        siftUP(elementAtIndex: elements.count - 1)
    }
    
    //delete
    mutating func dequeue() -> Element? {
        // Empty
        guard !isEmpty else { return nil }
        
        // Exchange the first node and the last node swap location
        swapElement(at: 0, with: count - 1)
        // Delete the original first, now the last one
        elements.removeLast()
        
        guard !isEmpty else { return nil }
        // Down to judge, the new node is not the node with the highest priority
        return nil
    }
}

private extension Heap {
    func isHigherPriority(firstIndex: Int, secondIndex: Int) -> Bool{
        return priorityFunction(elements[firstIndex], elements[secondIndex])
    }
    
    func highestPriorityIndex(of parentIndex: Int, and childIndex: Int) -> Int {
        guard childIndex < count && isHigherPriority(firstIndex: childIndex, secondIndex: parentIndex)
        else { return parentIndex }
        return childIndex
    }
    
    func highestPriorityIndex(for parent: Int) -> Int {
        return highestPriorityIndex(of: highestPriorityIndex(of: parent, and: leftChildIndex(of: parent)), and: rightChildIndex(of: parent))
    }
    
    mutating func swapElement(at firstIndex: Int, with secondIndex: Int) {
        guard firstIndex != secondIndex
        else { return }
        elements.swapAt(firstIndex, secondIndex)
    }
    
    mutating func siftDown(_ elementIndex: Int) {
        // Find the node with the highest priority from the current node and the child nodes
        let highestIndex = highestPriorityIndex(for: elementIndex)
        // If the current node is the node with the highest priority, put it back directly
        if highestIndex == elementIndex { return }
        //If it is not the node with the highest priority, swap the position with the node with the highest priority.
        swapElement(at: elementIndex, with: highestIndex)
        // Recursive downward judgment priority from the new node
        siftDown(highestIndex)
    }
    
    mutating func siftUP(elementAtIndex: Int)  {
        // Get the index of the parent node
        let parentIndex = self.parentIndex(of: elementAtIndex)
        // If the current node is not the root node, compare the priority of the current node and the parent node
        guard !isRoot(elementAtIndex), isHigherPriority(firstIndex: elementAtIndex, secondIndex: parentIndex) else {
            return
        }
        // If the current node has a higher priority than the parent node, redemption location
        swapElement(at: elementAtIndex, with: parentIndex)
        
        // Recursively start from the new parent node to compare upwards
        siftUP(elementAtIndex: parentIndex)
    }
}

protocol NetworkQueue {
    func seed()
    func dequeue(_ isSoft: Bool) -> NetworkQueueModel?
    func peek() -> NetworkQueueModel?
    func getSize() -> Int
    func isEmpty() -> Bool
}

public class NetworkQueueImpl: NetworkQueue {
    
    private var mPriorityNetworkModelQueue: Heap<NetworkQueueModel>
    private var mDbService: DbService
    
    init(_ dbService: DbService){
        self.mDbService = dbService
    }
    
    private func priorityFunction(_ element1: NetworkQueueModel, _ element2: NetworkQueueModel) -> Bool {
        let element1Priority = element1.getPriority()
        let element2Priority = element2.getPriority()
        return element1Priority > element2Priority
    }
    
    public func seed(){
        do {
            let resultArray = try mDbService.seed() as? [NetworkQueueModel]
            if resultArray != nil && resultArray?.count ?? 0 > 0 {
                self.mPriorityNetworkModelQueue = Heap(elements: [], priorityFunction: self.priorityFunction)
            }
            
        } catch let error {
            print("Error from seed method: NetworkQueue \(error)")
        }
    }
    
    func dequeue(_ isSoft: Bool) -> NetworkQueueModel? {
        if self.mPriorityNetworkModelQueue != nil {
            let element = self.mPriorityNetworkModelQueue.peek()
            if !isSoft {
                try? mDbService.delete((element?.getId())!);
            }
            
            self.mPriorityNetworkModelQueue.dequeue()
        }
        
        return nil
    }
    func peek() -> NetworkQueueModel?{
        if self.mPriorityNetworkModelQueue != nil {
            return mPriorityNetworkModelQueue.peek()
        }
        
        return nil
        
    }
    func getSize() -> Int {
        mPriorityNetworkModelQueue.count
    }
    func isEmpty() -> Bool {
        return mPriorityNetworkModelQueue.isEmpty
    }
}
