//
//  GameScene.swift
//  DragonCrush
//
//  Created by Esteban on 12.07.2018.
//  Copyright © 2018 Selfcode. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var level: Level!
    
    // layers
    let gameLayer = SKNode()
    let tilesLayer = SKNode()
    let dragonBallsLayer = SKNode()
    
    let maskLayer = SKNode()
    let cropLayer = SKCropNode()    // cropLayer only draws its children where the mask contains pixels. This lets you draw the cookies only where there is a tile, but never on the background
    
    private var swipeFromColumn: Int?
    private var swipeFromRow: Int?
    var swipeHandler: ((Swap) -> Void)?
    
    
    override init(size: CGSize) {
        super.init(size: size)
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)   //set the anchor to the center
        
        let background = SKSpriteNode(imageNamed: "planet1")
        // background.size = size
        addChild(background)
        
        addChild(gameLayer)
        gameLayer.isHidden = true
        
        let layerPosition = CGPoint(x: -Tile.width * CGFloat(Level.numColumns) / 2,
                                    y: -Tile.height * CGFloat(Level.numRows) / 2)
        dragonBallsLayer.position = layerPosition
        
        tilesLayer.position = layerPosition
        maskLayer.position = layerPosition
        cropLayer.maskNode = maskLayer
        gameLayer.addChild(tilesLayer)
        gameLayer.addChild(cropLayer)
        cropLayer.addChild(dragonBallsLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func removeAllDragonBallsSprites() {
        dragonBallsLayer.removeAllChildren()
    }
    
    //// ADD NODES ////
    func addTiles() {
        
            //add a mask
        for row in 0 ..< Level.numRows {
            for column in 0 ..< Level.numColumns {
                
                    // check if at this position a tile should be placed or not
                if level.isTile(column: column, row: row) != nil {
                    
                    let tileNode = SKSpriteNode(imageNamed: "MaskTile")     //get tile amsk texture
                    tileNode.size = CGSize(width: Tile.width, height: Tile.height)    //set the size
                    tileNode.position = Tile.getPointFor(column: column, row: row)  //set the position for this tile
                    maskLayer.addChild(tileNode)
                }
            }
        }
        
            //add the tiles textures
        for row in 0 ... Level.numRows {
            for column in 0 ... Level.numColumns {
                
                    //check what kind of tile position it is (inside/outside corner, simple etc.)
                let topLeft = (column > 0) && (row < Level.numRows) && level.isTile(column: column - 1, row: row) != nil
                let bottomLeft = (column > 0) && (row > 0) && level.isTile(column: column - 1, row: row - 1) != nil
                let topRight = (column < Level.numColumns) && (row < Level.numRows) && level.isTile(column: column, row: row) != nil
                let bottomRight = (column < Level.numColumns) && (row > 0) && level.isTile(column: column, row: row - 1) != nil

                var value = topLeft.hashValue
                value = value | topRight.hashValue << 1
                value = value | bottomLeft.hashValue << 2
                value = value | bottomRight.hashValue << 3
                
                    // Values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn.
                if value != 0 && value != 6 && value != 9 {
                    let name = String(format: "Tile_%ld", value)
                    let tileNode = SKSpriteNode(imageNamed: name)
                    tileNode.size = CGSize(width: Tile.width, height: Tile.height)
                    var point = Tile.getPointFor(column: column, row: row)
                    point.x -= Tile.width / 2
                    point.y -= Tile.height / 2
                    tileNode.position = point
                    tilesLayer.addChild(tileNode)
                }
            }
        }
    }
    
    func addSprites(for dragonBalls: Set<DragonBall>) {
        for dragonBall in dragonBalls {
            let sprite = SKSpriteNode(imageNamed: dragonBall.dragonBallType.spriteName)
            sprite.size = CGSize(width: Tile.width, height: Tile.height)
            sprite.position = Tile.getPointFor(column: dragonBall.column, row: dragonBall.row)
            dragonBallsLayer.addChild(sprite)
            dragonBall.sprite = sprite
            
            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            
            sprite.run(
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.25, withRange: 0.5),
                    SKAction.group([
                        SKAction.fadeIn(withDuration: 0.25),
                        SKAction.scale(to: 1.0, duration: 0.25)
                        ])
                    ]))
        }
    }
    
    //// HANDLE TOUCH EVENTS ////
        // check if the touch is on a DragonBall
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: dragonBallsLayer)
        
        let (success, column, row) =  Tile.convertPoint(location)
        if success {
            if let _ = level.getDragonBall(at: column, row: row) {
                swipeFromColumn = column
                swipeFromRow = row
            }
        }
    }
    
        // detect the touch move direction
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard swipeFromColumn != nil else { return }    //the swipe began outside the valid area or the game has already swapped the dragonBalls and we need to ignore the rest of the motion
        guard let touch = touches.first else { return }
        let location = touch.location(in: dragonBallsLayer)
        
        let (success, column, row) = Tile.convertPoint(location)
        
        if success {
            
            var horizontalDelta = 0 //difference left/right
            var verticalDelta = 0   //difference up/down
            
            if column < swipeFromColumn! {          // swipe left
                horizontalDelta = -1
            } else if column > swipeFromColumn! {   // swipe right
                horizontalDelta = 1
            } else if row < swipeFromRow! {         // swipe down
                verticalDelta = -1
            } else if row > swipeFromRow! {         // swipe up
                verticalDelta = 1
            }
            
            if horizontalDelta != 0 || verticalDelta != 0 {
                trySwap(horizontalDelta: horizontalDelta, verticalDelta: verticalDelta)
                swipeFromColumn = nil
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        swipeFromColumn = nil
        swipeFromRow = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    //// SWAP ////
    private func trySwap(horizontalDelta: Int, verticalDelta: Int) {
        
        let toColumn = swipeFromColumn! + horizontalDelta
        let toRow = swipeFromRow! + verticalDelta
        
        guard toColumn >= 0 && toColumn < Level.numColumns else { return }
        guard toRow >= 0 && toRow < Level.numRows else { return }
        
        if let toDragonBall = level.getDragonBall(at: toColumn, row: toRow), let fromDragonBall = level.getDragonBall(at: swipeFromColumn!, row: swipeFromRow!) {
            if let handler = swipeHandler {
                let swap = Swap(from: fromDragonBall, to: toDragonBall)
                handler(swap)
            }
        }
    }
    
    //// ANIMATIONS ////
    func animate(_ swap: Swap, completion: @escaping () -> Void) {
        let spriteA = swap.fromDragonBall.sprite!
        let spriteB = swap.toDragonBall.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: TimeInterval = 0.2
        
        let moveA = SKAction.move(to: spriteB.position, duration: duration)
        moveA.timingMode = .easeOut
        spriteA.run(moveA, completion: completion)
        
        let moveB = SKAction.move(to: spriteA.position, duration: duration)
        moveB.timingMode = .easeOut
        spriteB.run(moveB)
    }
    
    func animateInvalidSwap(_ swap: Swap, completion: @escaping () -> Void) {
        let spriteA = swap.fromDragonBall.sprite!
        let spriteB = swap.toDragonBall.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: TimeInterval = 0.2
        
        let moveA = SKAction.move(to: spriteB.position, duration: duration)
        moveA.timingMode = .easeOut
        
        let moveB = SKAction.move(to: spriteA.position, duration: duration)
        moveB.timingMode = .easeOut
        
        spriteA.run(SKAction.sequence([moveA, moveB]), completion: completion)
        spriteB.run(SKAction.sequence([moveB, moveA]))
    }
    
    func animateMatchedDragonBalls(for chains: Set<Chain>, completion: @escaping () -> Void) {
        for chain in chains {
            animateScore(for: chain)
            for dragonBall in chain.dragonBalls {
                if let sprite = dragonBall.sprite {
                    if sprite.action(forKey: "removing") == nil {
                        let scaleAction = SKAction.scale(to: 0.1, duration: 0.2)
                        scaleAction.timingMode = .easeOut
                        sprite.run(SKAction.sequence([scaleAction, SKAction.removeFromParent()]),
                                   withKey: "removing")
                    }
                }
            }
        }
        run(SKAction.wait(forDuration: 0.2), completion: completion)
    }
    
    func animateFallingDragonBalls(in columns: [[DragonBall]], completion: @escaping () -> Void) {
        
        var longestDuration: TimeInterval = 0
        for array in columns {
            for (index, dragonBall) in array.enumerated() {
                let newPosition = Tile.getPointFor(column: dragonBall.column, row: dragonBall.row)
                let delay = 0.05 + 0.15 * TimeInterval(index)
                let sprite = dragonBall.sprite!   // sprite always exists at this point
                let duration = TimeInterval(((sprite.position.y - newPosition.y) / Tile.height) * 0.1)
                
                longestDuration = max(longestDuration, duration + delay)
                
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.group([moveAction])]))
            }
        }
        
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    func animateNewDragonBalls(in columns: [[DragonBall]], completion: @escaping () -> Void) {
        
        var longestDuration: TimeInterval = 0
        
        for array in columns {
            
            let startRow = array[0].row + 1
            
            for (index, dragonBall) in array.enumerated() {
                
                let sprite = SKSpriteNode(imageNamed: dragonBall.dragonBallType.spriteName)
                sprite.size = CGSize(width: Tile.width, height: Tile.height)
                sprite.position = Tile.getPointFor(column: dragonBall.column, row: startRow)
                dragonBallsLayer.addChild(sprite)
                dragonBall.sprite = sprite
                
                let delay = 0.1 + 0.2 * TimeInterval(array.count - index - 1)
                
                let duration = TimeInterval(startRow - dragonBall.row) * 0.1
                longestDuration = max(longestDuration, duration + delay)
                
                let newPosition = Tile.getPointFor(column: dragonBall.column, row: dragonBall.row)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.alpha = 0
                sprite.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.group([
                            SKAction.fadeIn(withDuration: 0.05),
                            moveAction])
                        ]))
            }
        }
        
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
    
    func animateScore(for chain: Chain) {
        
            // Figure out what the midpoint of the chain is.
        let firstSprite = chain.firstDragonBall().sprite!
        let lastSprite = chain.lastDragonBall().sprite!
        let centerPosition = CGPoint(
            x: (firstSprite.position.x + lastSprite.position.x)/2,
            y: (firstSprite.position.y + lastSprite.position.y)/2 - 8)
        
            // Add a label for the score that slowly floats up.
        let scoreLabel = SKLabelNode(fontNamed: "GillSans-BoldItalic")
        scoreLabel.fontSize = 20
        scoreLabel.text = String(format: "%ld", chain.score)
        scoreLabel.position = centerPosition
        scoreLabel.zPosition = 300
        dragonBallsLayer.addChild(scoreLabel)
        
        let moveAction = SKAction.move(by: CGVector(dx: 0, dy: 3), duration: 0.7)
        moveAction.timingMode = .easeOut
        scoreLabel.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
    }
    
    func animateGameOver(_ completion: @escaping () -> Void) {
        let action = SKAction.move(by: CGVector(dx: 0, dy: -size.height), duration: 0.3)
        action.timingMode = .easeIn
        gameLayer.run(action, completion: completion)
    }
    
    func animateBeginGame() {
        gameLayer.alpha = 0
        gameLayer.isHidden = false
        let action = SKAction.fadeIn(withDuration: 0.3)
        gameLayer.run(action)
    }
}
