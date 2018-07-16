//
//  Tile.swift
//  DragonCrush
//
//  Created by Esteban on 12.07.2018.
//  Copyright © 2018 Selfcode. All rights reserved.
//

import UIKit

class Tile {
    
        //tile dimensions taken from the tile image size
    static let width: CGFloat = 32
    static let height: CGFloat = 36
    
        // get point for given row and column
    static func getPointFor(column: Int, row: Int) -> CGPoint {
        return CGPoint(x: CGFloat(column) * Tile.width + Tile.width / 2,
                       y: CGFloat(row) * Tile.height + Tile.height / 2)
    }
    
        // get the row and column for a given point (of touch)
    static func convertPoint(_ point: CGPoint) -> (success: Bool, column: Int, row: Int) {
        if point.x >= 0 && point.x < CGFloat(Level.numColumns) * Tile.width && point.y >= 0 && point.y < CGFloat(Level.numRows) * Tile.height {
            return (true, Int(point.x / Tile.width), Int(point.y / Tile.height))
        }
        else {
            return (false, 0, 0)  // invalid location
        }
    }
}
