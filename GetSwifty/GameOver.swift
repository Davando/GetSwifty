//
//  GameOver.swift
//  GetSwifty
//
//  Created by Sarah Zaman on 11/12/20.
//  Copyright © 2020 GetSwifty. All rights reserved.
//

import SpriteKit

class GameOverScene : SKScene {
    
    
    override func sceneDidLoad() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false){(timer) in
            
            let level1 = GameScene(fileNamed: "Level1")
            self.view?.presentScene(level1)
            self.removeAllActions()
            
        }
    }
    
}
