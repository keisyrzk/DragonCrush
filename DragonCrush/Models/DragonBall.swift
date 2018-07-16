//
//  DragonBall.swift
//  DBCrush
//
//  Created by Esteban on 10.07.2018.
//  Copyright © 2018 Selfcode. All rights reserved.
//

import SpriteKit

enum DragonBallType: Int {
    case unknown = 0, star1, star2, star3, star4, star5, star6, star7
    
    var spriteName: String {
        let spriteNames = [
            "star1",
            "star2",
            "star3",
            "star4",
            "star5",
            "star6",
            "star7"]
        
        return spriteNames[rawValue - 1]
    }
    
    static func random() -> DragonBallType {
        return DragonBallType(rawValue: Int(arc4random_uniform(7)) + 1)!
    }
}

class DragonBall: CustomStringConvertible, Hashable {
    
    var column: Int
    var row: Int
    let dragonBallType: DragonBallType
    var sprite: SKSpriteNode?
    var description: String {
        return "type:\(dragonBallType) square:(\(column),\(row))"
    }
    
    var hashValue: Int {
        return row * 10 + column
    }
    
    static func ==(lhs: DragonBall, rhs: DragonBall) -> Bool {
        return lhs.column == rhs.column && lhs.row == rhs.row
    }
    
    init(column: Int, row: Int, dragonBallType: DragonBallType) {
        self.column = column
        self.row = row
        self.dragonBallType = dragonBallType
    }
}
