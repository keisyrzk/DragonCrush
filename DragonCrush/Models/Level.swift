//
//  Level.swift
//  DragonCrush
//
//  Created by Esteban on 12.07.2018.
//  Copyright © 2018 Selfcode. All rights reserved.
//

import Foundation

class Level {
    
    // level dimensions
    static let numColumns = 9
    static let numRows = 9
    
    // level combo start value
    static let startRandom = 4
    static let startRow = 5
    static let startColumn = 5
    static let startInRange = 5

    static let randomToDestroy = 2
    
    //start points value
    static let pointsValue = 30
    
    private var tiles = Array2D<Tile>(columns: numColumns, rows: numRows)
    var dragonBalls = Array2D<DragonBall>(columns: numColumns, rows: numRows)
    var possibleSwaps: Set<Swap> = []
    
    var target: Int = 0
    var moves: Int = 0
    private var comboMultiplier = 0
    
    enum RemoveStyle {
        case Row
        case Column
        case Random
        case InRange
    }
    
    init(level fileName: String) {
        
        guard let levelData = LevelData.loadFrom(file: fileName) else {return}

        target = levelData.targetScore
        moves = levelData.moves
        
        for (row, rowArray) in levelData.tiles.enumerated() {
            
            //reverse the order because the tiles are nu,bered form 0 from the bottom of the scene
            let tileRow = Level.numRows - row - 1
            for (column, value) in rowArray.enumerated() {      //go through the matrix and if value is 1 than put a tile there
                if value == 1 {
                    tiles[column, tileRow] = Tile()
                }
            }
        }
    }
    
    func shuffle() -> Set<DragonBall> {
        var set: Set<DragonBall>
        repeat {
            set = createInitialBoard()
            detectPossibleSwaps()
        } while possibleSwaps.count == 0
        
        return set
    }
    
    func createInitialBoard() -> Set<DragonBall> {
        var set: Set<DragonBall> = []
        
        for row in 0..<Level.numRows {
            for column in 0..<Level.numColumns {
                
                // put a dragonBall only there where we have the levels tiles
                if tiles[column, row] != nil {
                    
                    //this definition picks the dragonBall type randomly and makes sure that it never creates a chain of three or more - such chain will be destroyed and gives piints
                    var dragonBallType: DragonBallType
                    repeat {
                        dragonBallType = DragonBallType.random()
                    } while (column >= 2 &&
                        dragonBalls[column - 1, row]?.dragonBallType == dragonBallType &&
                        dragonBalls[column - 2, row]?.dragonBallType == dragonBallType)
                        || (row >= 2 &&
                            dragonBalls[column, row - 1]?.dragonBallType == dragonBallType &&
                            dragonBalls[column, row - 2]?.dragonBallType == dragonBallType)
                    
                    let dragonBall = DragonBall(column: column, row: row, dragonBallType: dragonBallType)
                    dragonBalls[column, row] = dragonBall
                    set.insert(dragonBall)
                }
            }
        }
        return set
    }
    
    func isTile(column: Int, row: Int) -> Tile? {
        
        precondition(column >= 0 && column < Level.numColumns)
        precondition(row >= 0 && row < Level.numRows)
        return tiles[column, row]
    }
    
    func getDragonBall(at column: Int, row: Int) -> DragonBall? {
        precondition(column >= 0 && column < Level.numColumns)
        precondition(row >= 0 && row < Level.numRows)
        return dragonBalls[column, row]
    }
    
    func performSwap(_ swap: Swap) {
        let columnA = swap.fromDragonBall.column
        let rowA = swap.fromDragonBall.row
        let columnB = swap.toDragonBall.column
        let rowB = swap.toDragonBall.row
        
        dragonBalls[columnA, rowA] = swap.toDragonBall
        swap.toDragonBall.column = columnA
        swap.toDragonBall.row = rowA
        
        dragonBalls[columnB, rowB] = swap.fromDragonBall
        swap.fromDragonBall.column = columnB
        swap.fromDragonBall.row = rowB
    }
    
    private func hasChain(atColumn column: Int, row: Int) -> Bool {
        let dragonBallType = dragonBalls[column, row]!.dragonBallType
        
        // Horizontal chain check
        var horizontalLength = 1
        
        // Left
        var i = column - 1
        while i >= 0 && dragonBalls[i, row]?.dragonBallType == dragonBallType {
            i -= 1
            horizontalLength += 1
        }
        
        // Right
        i = column + 1
        while i < Level.numColumns && dragonBalls[i, row]?.dragonBallType == dragonBallType {
            i += 1
            horizontalLength += 1
        }
        if horizontalLength >= 3 { return true }
        
        // Vertical chain check
        var verticalLength = 1
        
        // Down
        i = row - 1
        while i >= 0 && dragonBalls[column, i]?.dragonBallType == dragonBallType {
            i -= 1
            verticalLength += 1
        }
        
        // Up
        i = row + 1
        while i < Level.numRows && dragonBalls[column, i]?.dragonBallType == dragonBallType {
            i += 1
            verticalLength += 1
        }
        return verticalLength >= 3
    }
    
    func detectPossibleSwaps() {
        var set: Set<Swap> = []
        
        for row in 0..<Level.numRows {
            for column in 0..<Level.numColumns {
                if let dragonBall = dragonBalls[column, row] {
                    
                    // Have a dragonBall in this spot? If there is no tile, there is no dragonBall.
                    if column < Level.numColumns - 1,
                        let other = dragonBalls[column + 1, row] {
                        // Swap them
                        dragonBalls[column, row] = other
                        dragonBalls[column + 1, row] = dragonBall
                        
                        // Is this dragonBall now part of a chain?
                        if hasChain(atColumn: column + 1, row: row) ||
                            hasChain(atColumn: column, row: row) {
                            set.insert(Swap(from: dragonBall, to: other))
                        }
                        
                        // Swap them back
                        dragonBalls[column, row] = dragonBall
                        dragonBalls[column + 1, row] = other
                    }
                    
                    if row < Level.numRows - 1,
                        let other = dragonBalls[column, row + 1] {
                        dragonBalls[column, row] = other
                        dragonBalls[column, row + 1] = dragonBall
                        
                        // Is this dragonBall now part of a chain?
                        if hasChain(atColumn: column, row: row + 1) ||
                            hasChain(atColumn: column, row: row) {
                            set.insert(Swap(from: dragonBall, to: other))
                        }
                        
                        // Swap them back
                        dragonBalls[column, row] = dragonBall
                        dragonBalls[column, row + 1] = other
                    }
                }
            }
        }
        possibleSwaps = set
    }
    
    func isPossibleSwap(_ swap: Swap) -> Bool {
        return possibleSwaps.contains(swap)
    }
    
    private func detectHorizontalMatches() -> Set<Chain> {
        
        var set: Set<Chain> = []
        
        for row in 0..<Level.numRows {
            var column = 0
            while column < Level.numColumns-2 {
                
                if let dragonBall = dragonBalls[column, row] {
                    let matchType = dragonBall.dragonBallType
                    
                    if dragonBalls[column + 1, row]?.dragonBallType == matchType &&
                        dragonBalls[column + 2, row]?.dragonBallType == matchType {
                        
                        let chain = Chain(chainType: .horizontal)
                        repeat {
                            chain.add(dragonBall: dragonBalls[column, row]!)
                            column += 1
                        } while column < Level.numColumns && dragonBalls[column, row]?.dragonBallType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                column += 1
            }
        }
        return set
    }
    
    private func detectVerticalMatches() -> Set<Chain> {
        var set: Set<Chain> = []
        
        for column in 0..<Level.numColumns {
            var row = 0
            while row < Level.numRows-2 {
                if let dragonBall = dragonBalls[column, row] {
                    let matchType = dragonBall.dragonBallType
                    
                    if dragonBalls[column, row + 1]?.dragonBallType == matchType &&
                        dragonBalls[column, row + 2]?.dragonBallType == matchType {
                        let chain = Chain(chainType: .vertical)
                        repeat {
                            chain.add(dragonBall: dragonBalls[column, row]!)
                            row += 1
                        } while row < Level.numRows && dragonBalls[column, row]?.dragonBallType == matchType
                        
                        set.insert(chain)
                        continue
                    }
                }
                row += 1
            }
        }
        return set
    }
    
    func removeMatches() -> (chains: Set<Chain>, shareDragonBalls: [DragonBall]) {

        return findPointsChains()
    }
    
    private func findPointsChains() -> (chains: Set<Chain>, shareDragonBalls: [DragonBall]) {

        var horizontalChains = detectHorizontalMatches()
        var verticalChains = detectVerticalMatches()
        
        var groupChains: Set<Chain> = []
        var shareDragonBalls: [DragonBall] = []
        
        horizontalChains.forEach { (chain) in
            chain.dragonBalls.forEach({ (dragonBall) in
                let result = verticalChains.filter{ $0.dragonBalls.contains{ $0 == dragonBall } == true}
                
                if result.count > 0 {
                    groupChains.insert(chain)
                    
                    result.forEach({ (resultChain) in
                        groupChains.insert(resultChain)
                        shareDragonBalls.append(dragonBall)
                    })
                }
            })
        }
        
        //remove chains classified as group (with at least one the same dragonBall - such dragonBall has the same column and row)
        var resultGroupChainSet: Set<Chain> = []
        let resultChain = Chain(chainType: .horizontal)
        
        groupChains.forEach { (chain) in
            resultChain.dragonBalls.append(contentsOf: chain.dragonBalls)
            verticalChains.remove(chain)
            horizontalChains.remove(chain)
        }
        if resultChain.dragonBalls.count > 0 {
            resultGroupChainSet.insert(resultChain)
        }
        
        calculateScores(for: horizontalChains)
        calculateScores(for: verticalChains)
        calculateScores(for: resultGroupChainSet)

        removeDragonBalls(in: horizontalChains)
        removeDragonBalls(in: verticalChains)
        removeDragonBalls(in: resultGroupChainSet)
        
        return (horizontalChains.union(verticalChains).union(resultGroupChainSet), shareDragonBalls)
    }
    
    private func removeDragonBalls(in chains: Set<Chain>) {
        for chain in chains {
            for dragonBall in chain.dragonBalls {
                dragonBalls[dragonBall.column, dragonBall.row] = nil
            }
        }
    }
    
    func removeDragonBalls(removeStyle: RemoveStyle, sourceChain: Chain? = nil, shareDragonBalls: [DragonBall]) -> Set<Chain> {
        
        switch removeStyle {
            
        case .Random:
            var removed: Set<Chain> = []
            repeat {
                let rRow = Int(arc4random_uniform(UInt32(Level.numRows - 1))) + 1
                let rColumn = Int(arc4random_uniform(UInt32(Level.numColumns - 1))) + 1
                
                if let dragonBall = dragonBalls[rColumn, rRow] {
                    dragonBalls[rColumn, rRow] = nil
                    let removedChain = Chain(chainType: .vertical)
                    removedChain.add(dragonBall: dragonBall)
                    removedChain.score = Level.pointsValue
                    removed.insert(removedChain)
                }
            }
            while removed.count < Level.randomToDestroy
            
            return removed
            
        case .Row:
            var removed: Set<Chain> = []
            guard let source = sourceChain else {return []}
            let row = source.firstDragonBall().row
            
            for column in 0 ..< Level.numColumns {
                
                if isTile(column: column, row: row) != nil && !source.dragonBalls.contains{ $0.column == column } {
                    if let dragonBall = dragonBalls[column, row] {
                        dragonBalls[column, row] = nil
                        let removedChain = Chain(chainType: .vertical)
                        removedChain.add(dragonBall: dragonBall)
                        removedChain.score = Level.pointsValue
                        removed.insert(removedChain)
                    }
                }
            }
            
            return removed

        case .Column:
            var removed: Set<Chain> = []
            guard let source = sourceChain else {return []}
            let column = source.firstDragonBall().column
            
            for row in 0 ..< Level.numRows {
                
                if isTile(column: column, row: row) != nil && !source.dragonBalls.contains{ $0.row == row } {
                    if let dragonBall = dragonBalls[column, row] {
                        dragonBalls[column, row] = nil
                        let removedChain = Chain(chainType: .vertical)
                        removedChain.add(dragonBall: dragonBall)
                        removedChain.score = Level.pointsValue
                        removed.insert(removedChain)
                    }
                }
            }
            
            return removed
            
        case .InRange:
            var removed: Set<Chain> = []
            
            shareDragonBalls.forEach { (shared) in
                for row in shared.row - 3 ..< shared.row + 3 {
                    for column in shared.column - 3 ..< shared.column + 3 {
                        if isTile(column: column, row: row) != nil {
                            if let dragonBall = dragonBalls[column, row] {
                                let removedChain = Chain(chainType: .vertical)
                                removedChain.add(dragonBall: dragonBall)
                                removedChain.score = Level.pointsValue
                                removed.insert(removedChain)
                            }
                        }
                    }
                }
            }
            
            return removed
        }
    }
    
    func fillHoles() -> [[DragonBall]] {
        var columns: [[DragonBall]] = []
        
        for column in 0..<Level.numColumns {
            var array: [DragonBall] = []
            for row in 0..<Level.numRows {
                
                if tiles[column, row] != nil && dragonBalls[column, row] == nil {
                    
                    for lookup in (row + 1)..<Level.numRows {
                        if let dragonBall = dragonBalls[column, lookup] {
                            
                            dragonBalls[column, lookup] = nil
                            dragonBalls[column, row] = dragonBall
                            dragonBall.row = row
                            
                            array.append(dragonBall)
                            
                            break
                        }
                    }
                }
            }
            
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    func topUpDragonBalls() -> [[DragonBall]] {
        var columns: [[DragonBall]] = []
        var dragonBallType: DragonBallType = .unknown
        
        for column in 0..<Level.numColumns {
            var array: [DragonBall] = []
            
            var row = Level.numRows - 1
            while row >= 0 && dragonBalls[column, row] == nil {
                
                if tiles[column, row] != nil {
                    
                    var newDragonBallType: DragonBallType
                    repeat {
                        newDragonBallType = DragonBallType.random()
                    } while newDragonBallType == dragonBallType
                    dragonBallType = newDragonBallType
                    
                    let dragonBall = DragonBall(column: column, row: row, dragonBallType: dragonBallType)
                    dragonBalls[column, row] = dragonBall
                    array.append(dragonBall)
                }
                
                row -= 1
            }
            
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    private func calculateScores(for chains: Set<Chain>) {
        for chain in chains {
            chain.score = Level.pointsValue * chain.length * comboMultiplier
            comboMultiplier += 1
        }
    }
    
    func resetComboMultiplier() {
        comboMultiplier = 1
    }
}
