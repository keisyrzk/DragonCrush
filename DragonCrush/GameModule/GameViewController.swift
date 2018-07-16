//
//  GameViewController.swift
//  DragonCrush
//
//  Created by Esteban on 12.07.2018.
//  Copyright © 2018 Selfcode. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    @IBOutlet weak var targetValueLabel: UILabel!
    @IBOutlet weak var movesValueLabel: UILabel!
    @IBOutlet weak var scoreValueLabel: UILabel!
    @IBOutlet weak var levelEndBoard: UIImageView!
    
    
    var scene: GameScene!
    var level: Level!
    var score = 0
    var tapGestureRecognizer: UITapGestureRecognizer!
    var currentLevel = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startNewLevel()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func beginGame(shouldAnimateBoard: Bool = false) {
        level.resetComboMultiplier()
        
        if shouldAnimateBoard {
            scene.animateBeginGame()
        }
        
        scene.removeAllDragonBallsSprites()
        let newDragonBalls = level.shuffle()
        scene.addSprites(for: newDragonBalls)
    }
    
    func handleSwipe(_ swap: Swap) {
        view.isUserInteractionEnabled = false
        
        if level.isPossibleSwap(swap) {
            level.performSwap(swap)
            scene.animate(swap, completion: handleMatches)
        } else {
            scene.animateInvalidSwap(swap) {
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
    func handleMatches() {
        let (chains, shareDragonBalls) = level.removeMatches()
        
        if chains.count == 0 {
            beginNextTurn()
            return
        }

        scene.animateMatchedDragonBalls(for: chains) {
            
            self.collectPoints(for: chains, shareDragonBalls: shareDragonBalls)
            
            let columns = self.level.fillHoles()
            self.scene.animateFallingDragonBalls(in: columns) {
                let columns = self.level.topUpDragonBalls()
                self.scene.animateNewDragonBalls(in: columns) {
                    self.handleMatches()
                }
            }
        }
    }
    
    private func collectPoints(for chains: Set<Chain>, shareDragonBalls: [DragonBall]) {
        
            // matched chains
        for chain in chains {
            self.score += chain.score
            
            // bonus random
            if chain.length == Level.startRandom {
                collectBonusPoints(removeStyle: .Random, sourceChain: nil)
            }
            
            // bonus row
            if chain.length == Level.startRow && chain.chainType == .horizontal {
                collectBonusPoints(removeStyle: .Row, sourceChain: chain)
            }
            
            // bonus column
            if chain.length == Level.startColumn && chain.chainType == .vertical {
                collectBonusPoints(removeStyle: .Column, sourceChain: chain)
            }
            
            //bonus inRange
            if chain.length == Level.startInRange && chain.chainType == .vertical && shareDragonBalls.count > 0 {
                collectBonusPoints(removeStyle: .InRange, sourceChain: chain, shareDragonBalls: shareDragonBalls)
            }
        }
        self.scoreValueLabel.text = "\(self.score)"
    }
    
    private func collectBonusPoints(removeStyle: Level.RemoveStyle, sourceChain: Chain?, shareDragonBalls: [DragonBall] = []) {
    
        let bonusChains = self.level.removeDragonBalls(removeStyle: removeStyle, sourceChain: sourceChain, shareDragonBalls: shareDragonBalls)
        for bonusChain in bonusChains {
            self.score += bonusChain.score
        }
        scene.animateMatchedDragonBalls(for: bonusChains) {}
    }
    
    func beginNextTurn() {
        level.resetComboMultiplier()
        level.detectPossibleSwaps()
        view.isUserInteractionEnabled = true
        decrementMoves()

        if level.possibleSwaps.count == 0 {
            beginGame()
        }
    }
    
    func startNewLevel() {
        
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
            // create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        
            // setup the level.
        level = Level(level: "Level_\(currentLevel)")
        scene.level = level
        targetValueLabel.text = "\(level.target)"
        movesValueLabel.text = "\(level.moves)"
        scoreValueLabel.text = "0"
        score = 0
        
            // handle the swipes
        scene.addTiles()
        scene.swipeHandler = handleSwipe
        
            // Present the scene.
        skView.presentScene(scene)
        
            // Start the game.
        beginGame(shouldAnimateBoard: true)
    }
    
    func showGamesEnd() {
        levelEndBoard.isHidden = false
        scene.isUserInteractionEnabled = false
        
        scene.animateGameOver {
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideGamesEnd))
            self.view.addGestureRecognizer(self.tapGestureRecognizer)
        }
    }
    
    @objc func hideGamesEnd() {
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        levelEndBoard.isHidden = true
        scene.isUserInteractionEnabled = true
        
        startNewLevel()
    }
    
    func decrementMoves() {
        level.moves -= 1
        movesValueLabel.text = "\(level.moves)"
        
        if score >= level.target {
            levelEndBoard.image = UIImage(named: "levelWon")
            currentLevel += 1
            showGamesEnd()
        }
        else if level.moves == 0 {
            levelEndBoard.image = UIImage(named: "levelLost")
            showGamesEnd()
        }
    }
}
