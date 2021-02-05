//
//  GameScene.swift
//  DiveIntoSpriteKit
//
//  Created by Paul Hudson on 16/10/2017.
//  Copyright © 2017 Paul Hudson. All rights reserved.
//

import SpriteKit


@objcMembers
class GameScene: SKScene {
    
    
    /// To keep track of what level the player is on and their score in each game session
    var level = 1
    let scoreLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    /// To track how long the game has been active
    var startTime = 0.0
    var timeLabel = SKLabelNode(fontNamed: "Optima-ExtraBlack")
    var isGameRunning = true

    
    /// To keep track of how many times success or failures on current level
    var fail = 0
    var success = 0
    var totalNumberOfTrials = 0
    
//MARK: Get a constants K folder going for string references
    let K = Constants()
    
    override func didMove(to view: SKView) {
        
        // To take care of the background
        let background = SKSpriteNode(imageNamed: "background_1")
        background.name = "background"
        background.zPosition = -1
        background.size = self.size
        addChild(background)
        
        // And to add the score label to the screen
        scoreLabel.position = CGPoint(x: -480, y: 330)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.zPosition = 1
        scoreLabel.fontColor = SKColor(red: 233/255, green: 157/255, blue: 20/255, alpha: 1)
        /// Add it to the background node itself and not the scene, so as not to interfere with grid creation
        background.addChild(scoreLabel)
        score = 0 ///initial value
        
        // And to add the timer label to the screen
        timeLabel.position = CGPoint(x: 480, y: 330)
        timeLabel.horizontalAlignmentMode = .right
        timeLabel.zPosition = 1
        timeLabel.fontColor = SKColor(red: 233/255, green: 157/255, blue: 20/255, alpha: 1)
        background.addChild(timeLabel)
        
        // And the same for the audio file
        let music = SKAudioNode(fileNamed: "cool-vibes")
        background.addChild(music)
        
        // Call create grid to populate the screen with objects
        createGrid()
        createLevel()
    }
    
    //MARK: - Create Object Grid
    func createGrid() {
        let xOffset = -440
        let yOffset = -280
        
        for row in 0 ..< 8 {
            for col in 0 ..< 12 {
                let item = SKSpriteNode(imageNamed: "target_red1")
                item.position = CGPoint(x: xOffset + (col * 80), y: yOffset + (row * 80))
                addChild(item)
            }
        }
    }
    
    //MARK: - Create Level Function
    func createLevel() {
        // Cap out how many items can be shown on the screen so the game doesn't crash
        var itemsToShow = 5 + (level * 4)
        itemsToShow = min(itemsToShow, 96)
        
        print(itemsToShow)
        
        // To keep track of which items get shown
        var showObjects = [String]()
        var placingObject = 0
        var numUsed = 0
        
        // find all nodes that belong to our scene that are not called "background"
        let items = children.filter { $0.name != "background" }
        
        // To shuffle the nodes so they are in random order
        let shuffled = items.shuffled() as! [SKSpriteNode]
        
        // And loop over them
        for item in shuffled {
            // and hide them
            item.alpha = 0
        }
        // To create and shuffle an array of objects in order to pair them off for odd one out
        var objects = [""]
        for i in 1...9 {
            let current = "spaceShips_00\(i)"
            objects.append(current)
        }
        var shuffledObjects = objects.shuffled()
        
        // To remove one to be the correct answer (ie odd one out)
        let correct = shuffledObjects.removeLast()
        
        // To create the array that will be shown objects
        for _ in 1 ..< itemsToShow {
            // To mark that this object has been used
            numUsed += 1
            
            // Place it
            showObjects.append(shuffledObjects[placingObject])
            
            // If this object has been used twice go to the next one
            if numUsed == 4 {
                numUsed = 0
                placingObject += 1
            }
            
            // If all objects have been placed, restart
            if placingObject == shuffledObjects.count {
                placingObject = 0
            }
        }
        
        // Next to assign the objects to grid locations and label them "wrong"
        for (index, object) in showObjects.enumerated() {
            // pull out the matching item
            let item = shuffled[index]
            
            // assign the correct texture
            item.texture = SKTexture(imageNamed: object)
            
            // show it
            item.alpha = 1
            
            // mark it as wrong
            item.name = "wrong"
        }
        
        // To add the correct object
        shuffled.last?.texture = SKTexture(imageNamed: correct)
        shuffled.last?.alpha = 1
        shuffled.last?.name = "correct"
        
        // Re-enable touches on each level generation
        isUserInteractionEnabled = true
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Make sure the game is active
        guard isGameRunning else { return }
        // Make sure you register only the first touch on the screen (ipads can do two at once)
        guard let touch = touches.first else { return }
        
        // Capture the location and nodes at touch
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        
        // Now to figure out what was touched, and seperate it from the background
        guard let tapped = tappedNodes.first else { return }
        if tapped.name == "correct" {
            correctAnswer(node: tapped)
        } else if tapped.name == "wrong" {
            wrongAnswer(node: tapped)        }
    }
    
    //MARK: - Correct Answer Activity
    
    func correctAnswer(node: SKNode) {
        
        // Update score
        score += 1
        // And play the correct sound
        run(SKAction.playSoundFileNamed("bonus", waitForCompletion: false))
        
        // Now to fade out the objects that were incorrect
        let fade = SKAction.fadeOut(withDuration: 0.5)
        
        for child in children {
            guard child.name == "wrong" else { continue }
            child.run(fade)
            }
        
        // After the wrong answers fade away, we increment the level and repopulate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Now to require several successful trials in order to level up
            self.success += 1
            print("success incremented, sucess = \(self.success)")
            if self.success > (self.level * 3) {
                self.level += 1
                print(" level = \(self.level) : succes reset \(self.success)")
                self.success = 0
            }
            self.totalNumberOfTrials += 1
            self.createLevel()
        }
        
        // We can even make the correct answer get emphasized by scaling it up and down
        let scaleUp = SKAction.scale(to: 2, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1, duration: 0.5)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        node.run(sequence)
        
        // Have to disable tap so they can't get right and wrong, or build score up
        isUserInteractionEnabled = false
    }
    
    //MARK: - Wrong answer activity
    
    func wrongAnswer(node: SKNode) {
        // Update score
        if score <= 1 {
            score = 1
        } else {
        score -= 1
        }
        // And play the wrong sound
        run(SKAction.playSoundFileNamed("wrong-3", waitForCompletion: false))
        // You can add a cross over the wrong answer if that's useful
        let wrong = SKSpriteNode(imageNamed: "wrong")
        wrong.position = node.position
        wrong.zPosition = 5
        addChild(wrong)
        
        // Now to increment failed attemps on level, cap five attempts per level before decrement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            wrong.removeFromParent()
            self.fail += 1
            print("fail incremented, fail = \(self.fail)")

            // And reset success since there was a failed attempt
            self.success = 0
            
            if self.fail > 2 {
                self.level -= 1
                self.fail = 0
                print("level deprecated, level = \(self.level) : fail reset, fail = \(self.fail)")
            }
            if self.level == 0 {
                self.level = 1
                print("level reset, level = \(self.level)")
            }
            self.totalNumberOfTrials += 1        }
            self.createLevel()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }

    override func update(_ currentTime: TimeInterval) {
        
        // If the game is active
        if isGameRunning {
            // And start time equals 0, then the game has just begun
            if startTime == 0 {
                startTime = currentTime
            }
            let timePassed = currentTime - startTime
            let remainingTime = Int(ceil(60 - timePassed))
            
            /// And to update the time label with how much time is left in their 3 minutes
            timeLabel.text = "TIME: \(remainingTime)"
            timeLabel.alpha = 1
            
            // Then if remainingTime reach 0
            if remainingTime <= 0 {
                isGameRunning = false
                let gameOver = SKSpriteNode(imageNamed: "gameOver1")
                gameOver.zPosition = 10
                addChild(gameOver)
                
                // Invoke Grand Central Dispatch to rerender out game scene
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    /// Create a new game scene from GameScene.sks
                    if let scene = GameScene(fileNamed: "GameScene") {
                        scene.scaleMode = .aspectFill
                        self.view?.presentScene(scene)
                    }
                }
            }
            
        } else {
            timeLabel.alpha = 0
        }
    }
    
    
}

