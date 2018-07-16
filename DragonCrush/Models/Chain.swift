//
//  Chain.swift
//  DBCrush
//
//  Created by Esteban on 11.07.2018.
//  Copyright © 2018 Selfcode. All rights reserved.
//

import Foundation

class Chain: Hashable, CustomStringConvertible {
    
    var dragonBalls: [DragonBall] = []
    var score = 0
    
    enum ChainType: CustomStringConvertible {
        case horizontal
        case vertical
        
        var description: String {
            switch self {
            case .horizontal: return "Horizontal"
            case .vertical: return "Vertical"
            }
        }
    }
    
    var chainType: ChainType
    
    init(chainType: ChainType) {
        self.chainType = chainType
    }
    
    func add(dragonBall: DragonBall) {
        dragonBalls.append(dragonBall)
    }
    
    func firstDragonBall() -> DragonBall {
        return dragonBalls[0]
    }
    
    func lastDragonBall() -> DragonBall {
        return dragonBalls[dragonBalls.count - 1]
    }
    
    var length: Int {
        return dragonBalls.count
    }
    
    var description: String {
        return "type:\(chainType) dragonBalls:\(dragonBalls)"
    }
    
    var hashValue: Int {
        return dragonBalls.reduce (0) { $0.hashValue ^ $1.hashValue }
    }
    
    static func ==(lhs: Chain, rhs: Chain) -> Bool {
        return lhs.dragonBalls == rhs.dragonBalls
    }
}
