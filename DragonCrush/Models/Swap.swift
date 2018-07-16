//
//  Swap.swift
//  DBCrush
//
//  Created by Esteban on 11.07.2018.
//  Copyright © 2018 Selfcode. All rights reserved.
//

import Foundation

struct Swap: CustomStringConvertible, Hashable {
    
    let fromDragonBall: DragonBall
    let toDragonBall: DragonBall
    
    var hashValue: Int {
        return fromDragonBall.hashValue ^ toDragonBall.hashValue
    }
    
    static func ==(lhs: Swap, rhs: Swap) -> Bool {
        return (lhs.fromDragonBall == rhs.fromDragonBall && lhs.toDragonBall == rhs.toDragonBall) ||
            (lhs.toDragonBall == rhs.fromDragonBall && lhs.fromDragonBall == rhs.toDragonBall)
    }
    
    init(from: DragonBall, to: DragonBall) {
        self.fromDragonBall = from
        self.toDragonBall = to
    }
    
    var description: String {
        return "swap \(fromDragonBall) with \(toDragonBall)"
    }
}
