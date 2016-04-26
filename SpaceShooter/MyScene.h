//
//  MyScene.h
//  SpaceShooter
//
//  Created by Tony Dahbura on 9/9/13.
//  Copyright (c) 2013 fullmoonmanor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "ViewController.h"

@interface MyScene : SKScene {
    CGPoint _touchLocation;
    CFTimeInterval _touchTime;
    CGFloat _highScore;
    SKSpriteNode *live1;
    SKSpriteNode *live2;
    SKSpriteNode *live3;
    SKSpriteNode *live4;
    NSArray *lives;
}
-(void) shoot;

@end
