//
//  GameScene.swift
//  GetSwifty
//
//  Created by David Wang on 2020-11-12.
//  Copyright © 2020 GetSwifty. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    //to switch between scenes we need a superclass and a subclass
    
   
    //Entities
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    //Nodes
    var player: SKNode?
    var joystick: SKNode?
    var joystickKnob: SKNode?
    var cameraNode: SKCameraNode?
    
    //Boolean
    var joystickAction = false
    var rewardIsNotTouched = true
    var isHit = false
    
    //Measure
    var knowRadius: CGFloat = 50.0
    
    //Score
    let scoreLabel = SKLabelNode()
    var score = 0

    
    //heart
    var heartsArray = [SKSpriteNode]()
    let heartContainer = SKSpriteNode()
    
    
    // Sprite Engine
    var previousTimeInterval: TimeInterval = 0
    var playerIsFacingRight = false
    let playerSpeed = 6.0
    
    //Player state
    var playerStateMachine: GKStateMachine!
    
    //didMove
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        player = childNode(withName: "player")
        joystick = childNode(withName: "joystick")
        joystickKnob = joystick?.childNode(withName: "knob")
        cameraNode = childNode(withName: "cameraNode") as? SKCameraNode
        
        playerStateMachine = GKStateMachine(states:
            [JumpingState(playerNode: player!),
            WalkingState(playerNode: player!),
            IdleState(playerNode: player!),
            LandingState(playerNode: player!),
            StunnedState(playerNode: player!),
            ])
        
        playerStateMachine.enter(IdleState.self)
        
        //Heart
        heartContainer.position = CGPoint(x: -300, y: 140)
        heartContainer.zPosition = 5
        cameraNode?.addChild(heartContainer)
        fillHearts(count: 3)
        
        //Timer
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) {(timer) in
            self.spawnHead()
        }
        
        scoreLabel.position = CGPoint(x: (cameraNode?.position.x)! + 310, y: 140)
        scoreLabel.fontColor = #colorLiteral(red: 0.4500938654, green: 0.9813225865, blue: 0.4743030667, alpha: 1)
        
        scoreLabel.fontSize = 24
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.text = String(score)
        cameraNode?.addChild(scoreLabel)
        
        let entity = GKEntity()
        entity.addComponent(GKSKNodeComponent(node: player!))
        entity.addComponent(GKSKNodeComponent(node: joystick!))
        entity.addComponent(GKSKNodeComponent(node: joystick!))
        entities.append(entity)
    }

}

// MARK: Touches
extension GameScene {
    // Touch Began
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let joystickKnob = joystickKnob {
                let location = touch.location(in: joystick!)
                joystickAction = joystickKnob.frame.contains(location)
            }
            let location = touch.location(in: self)
            if !(joystick?.contains(location))! {
                playerStateMachine.enter(JumpingState.self)
            }
        }
    }
    
    // Touch Moved
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let joystick = joystick else { return }
        guard let joystickKnob = joystickKnob else { return }
        
        if !joystickAction { return }
        
        //Distance
        for touch in touches {
            let position = touch.location(in: joystick)
            
            let length = sqrt(pow(position.y, 2) + pow(position.x, 2))
            let angle = atan2(position.y, position.x)
            
            if knowRadius > length {
                joystickKnob.position = position
            } else {
                joystickKnob.position = CGPoint(x: cos(angle) * knowRadius, y: sin(angle) * knowRadius)
            }
        }
    }
    
    // Touch End
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let xJoystickCoordinate = touch.location(in: joystick!).x
            let xLimit: CGFloat = 200.0
            if xJoystickCoordinate > -xLimit && xJoystickCoordinate < xLimit {
                resetKnobPosition()
            }
        }
    }
}

// MARK: Action
extension GameScene {
    
    func resetKnobPosition() {
        let initialPoint = CGPoint(x: 0, y: 0)
        let moveBack = SKAction.move(to: initialPoint, duration: 0.1)
        moveBack.timingMode = .linear
        joystickKnob?.run(moveBack)
        joystickAction = false
    }
    
    func rewardTouch() {
        score+=1
        scoreLabel.text = String(score)
        
    }
    
    func fillHearts(count: Int){
        for index in 1...count{
            let heart  = SKSpriteNode(imageNamed: "heart")
            let xPosition = heart.size.width * CGFloat(index - 1)
            heart.position = CGPoint(x: xPosition, y: 0)
            heartsArray.append(heart)
            heartContainer.addChild(heart)
            
        }
    }
    
    func loseHeart(){
        if isHit == true {
            let lastElementIndex = heartsArray.count - 1
            if heartsArray.indices.contains(lastElementIndex - 1){
                let lastHeart = heartsArray[lastElementIndex]
                lastHeart.removeFromParent()
                heartsArray.remove(at: lastElementIndex)
                //making sure you can't lose another heart within 2 secs of getting hit
                Timer.scheduledTimer(withTimeInterval: 2, repeats: false){(timer) in
                    self.isHit = false
                }
            }
            else{
                dying()
                showDieScene()
            }
            invincible()
        }
    }
    
    func invincible(){
        //during this they cant be injured
        player?.physicsBody?.categoryBitMask = 0
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false){(timer) in
            self.player?.physicsBody?.categoryBitMask = 2
        }
    }
    
    func dying() {
        let dieAction = SKAction.move(to: CGPoint(x: -300, y: 0), duration: 0.1)
        player?.run(dieAction)
        self.removeAllActions()
        fillHearts(count: 3)
        score = 0
    }
    
    func showDieScene(){
        let gameOverScene = GameScene(fileNamed: "GameOver")
        self.view?.presentScene(gameOverScene)
    }
}

//MARK: Game Loop
extension GameScene {
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - previousTimeInterval
        previousTimeInterval = currentTime
        
        rewardIsNotTouched = true
        
        //Camera
        cameraNode?.position.x = player!.position.x
        joystick?.position.y = (cameraNode?.position.y)! - 100
        joystick?.position.x = (cameraNode?.position.x)! - 300
        
        // Player movement
        guard let joystickKnob = joystickKnob else { return }
        let xPosition = Double(joystickKnob.position.x)
        let positivePosition = xPosition < 0 ? -xPosition: xPosition
        
        if floor(positivePosition) != 0 {
            playerStateMachine.enter(WalkingState.self)
        } else {
            playerStateMachine.enter(IdleState.self)
        }
        
        let displacement = CGVector(dx: deltaTime * xPosition * playerSpeed, dy: 0)
        let move = SKAction.move(by: displacement, duration: 0)
        //player?.run(move)
        let faceAction: SKAction!
        let movingRight = xPosition > 0
        let movingLeft = xPosition < 0
        if movingLeft && playerIsFacingRight {
            playerIsFacingRight = false
            let faceMovement = SKAction.scaleX(to: 0.5, duration: 0.0)
            faceAction = SKAction.sequence([move, faceMovement])
        }
        else if movingRight && !playerIsFacingRight {
            playerIsFacingRight = true
            let faceMovement = SKAction.scaleX(to: -0.5, duration: 0.0)
            faceAction = SKAction.sequence([move, faceMovement])
        } else {
            faceAction = move
        }
        player?.run(faceAction)
    }
}

// MARK: Collision
extension GameScene: SKPhysicsContactDelegate {
    
    struct Collision {
        
        enum Masks: Int {
            case killing, player, reward, ground
            var bitmask: UInt32 { return 1 << self.rawValue }
        }
        
        let masks: (first: UInt32, second: UInt32)
        
        func matches (_ first: Masks, _ second: Masks) -> Bool {
            return (first.bitmask == masks.first && second.bitmask == masks.second) || (first.bitmask == masks.second && second.bitmask == masks.first)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        let collision = Collision(masks: (first: contact.bodyA.categoryBitMask, second: contact.bodyB.categoryBitMask))
        
        //Included hearts
        if collision.matches(.player, .killing) {
            loseHeart()
            isHit = true
            
            playerStateMachine.enter(StunnedState.self)
        }
        
        if collision.matches(.player, .ground){
            playerStateMachine.enter(LandingState.self)
        }
        
        //for coin
        if collision.matches(.player, .reward){
            
            if contact.bodyA.node?.name == "coin" {
                contact.bodyA.node?.physicsBody?.categoryBitMask = 0
               
            }
            else if contact.bodyB.node?.name == "coin" {
                contact.bodyB.node?.physicsBody?.categoryBitMask = 0
                
                ///for removing body
                contact.bodyB.node?.removeFromParent()
            }
            
            if rewardIsNotTouched {
                rewardTouch()
                rewardIsNotTouched=false
            }
        }
        
        //for collision with the cromulon
        if collision.matches(.ground, .killing){
            if contact.bodyA.node?.name == "Cromulon", let cromulon = contact.bodyA.node {
                createCrack(at: cromulon.position)
                cromulon.removeFromParent()
            }
            if contact.bodyB.node?.name == "Cromulon", let cromulon = contact.bodyB.node {
                createCrack(at: cromulon.position)
                cromulon.removeFromParent()
            }
        }
    }
    
}

//Mark: meter
extension GameScene {
    
    func spawnHead() {
        let node = SKSpriteNode(imageNamed: "cromulon")
        node.name = "Cromulon"
        let randomXPosition = Int(arc4random_uniform(UInt32(self.size.width)))
        node.setScale(0.3)
        node.position = CGPoint(x: randomXPosition, y: 270)
        
        node.anchorPoint = CGPoint(x: 0.5, y: 1)
        
        
        let physicsBody = SKPhysicsBody(circleOfRadius: 30)
        node.physicsBody = physicsBody
        
        physicsBody.categoryBitMask = Collision.Masks.killing.bitmask
        
        physicsBody.collisionBitMask = Collision.Masks.player.bitmask | Collision.Masks.ground.bitmask
        physicsBody.contactTestBitMask = Collision.Masks.player.bitmask | Collision.Masks.ground.bitmask
        physicsBody.fieldBitMask = Collision.Masks.player.bitmask | Collision.Masks.ground.bitmask
        
        
        physicsBody.affectedByGravity = true
        physicsBody.allowsRotation = false
        physicsBody.restitution = 0.2
        physicsBody.friction = 10
        
        addChild(node)
        
    }
    
    func createCrack(at position: CGPoint){
        
        let node = SKSpriteNode(imageNamed: "crack")
        
        node.position.x = position.x
        node.position.y = position.y-70
        node.zPosition = 4
        
        addChild(node)
        
        let action = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.wait(forDuration: 3),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent(),
        ])
        
        node.run(action)
    }
}


