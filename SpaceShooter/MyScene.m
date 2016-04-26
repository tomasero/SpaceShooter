//
//  MyScene.m
//  SpaceShooter
//
//  Created by Tony Dahbura on 9/9/13.
//  Copyright (c) 2013 fullmoonmanor. All rights reserved.
//

@import AVFoundation;
@import CoreMotion;

#import "MyScene.h"
#import "FMMParallaxNode.h"


// Add to top of file
#define kNumAliens   15
#define kNumLasers   4

typedef enum {
    kEndReasonWin,
    kEndReasonLose
} EndReason;

@implementation MyScene
{
    SKNode *node;
    
    SKSpriteNode *_ship;
    FMMParallaxNode *_parallaxNodeBackgrounds;
    FMMParallaxNode *_parallaxSpaceDust;
    
    CMMotionManager *_motionManager;
    
    
    NSMutableArray *_aliens;
    int _nextAlien;
    double _nextAlienSpawn;
    
    NSMutableArray *_shipLasers;
    int _nextShipLaser;
    
    int _lives;
    double _gameOverTime;
    bool _gameOver;
    
    CGFloat _score;
    SKLabelNode *highScoreValue;
    SKLabelNode *scoreValue;
    
    AVAudioPlayer *_backgroundAudioPlayer;

    
}


-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        NSLog(@"SKScene:initWithSize %f x %f",size.width,size.height);
        
        self.backgroundColor = [SKColor blackColor];
        #pragma mark - Game Backgrounds
        NSArray *parallaxBackgroundNames = @[@"bg_galaxy.png", @"bg_planetsunrise.png",
                                             @"bg_spacialanomaly.png", @"bg_spacialanomaly2.png"];
        CGSize planetSizes = CGSizeMake(200.0, 200.0);
        _parallaxNodeBackgrounds = [[FMMParallaxNode alloc] initWithBackgrounds:parallaxBackgroundNames
                                                                           size:planetSizes
                                                           pointsPerSecondSpeed:10.0];
        _parallaxNodeBackgrounds.position = CGPointMake(size.width/2.0, size.height/2.0);
        [_parallaxNodeBackgrounds randomizeNodesPositions];
        [self addChild:_parallaxNodeBackgrounds];
        
        //Bring on the space dust
        NSArray *parallaxBackground2Names = @[@"bg_front_spacedust.png",@"bg_front_spacedust.png"];
        _parallaxSpaceDust = [[FMMParallaxNode alloc] initWithBackgrounds:parallaxBackground2Names
                                                                     size:size
                                                     pointsPerSecondSpeed:25.0];
        _parallaxSpaceDust.position = CGPointMake(0, 0);
        [self addChild:_parallaxSpaceDust];
        [self setupGame: size];
        
    }
    return self;
}




- (void)setupGame:(CGSize)size
{

    //Define our physics body around the screen - used by our ship to not bounce off the screen
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    
#pragma mark - Setup Sprite for the ship
    //Create space sprite, setup position on left edge centered on the screen, and add to Scene
    _ship = [SKSpriteNode spriteNodeWithImageNamed:@"ship"];
    [_ship setScale:0.2];
    _ship.position = CGPointMake(self.frame.size.width * 0.1, CGRectGetMidY(self.frame));
    //move the ship using Sprite Kit's Physics Engine
    //Create a rectangular physics body the same size as the ship.
    _ship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_ship.frame.size];
    
    //Make the shape dynamic; this makes it subject to things such as collisions and other outside forces.
    _ship.physicsBody.dynamic = YES;
    
    //You don't want the ship to drop off the bottom of the screen, so you indicate that it's not affected by gravity.
    _ship.physicsBody.affectedByGravity = NO;
    
    //Give the ship an arbitrary mass so that its movement feels natural.
    _ship.physicsBody.mass = 0.02;
    
    [self addChild:_ship];
    
#pragma mark - Setup the aliens
    _aliens = [[NSMutableArray alloc] initWithCapacity:kNumAliens];
    for (int i = 0; i < kNumAliens; ++i) {
        SKSpriteNode *alien = [SKSpriteNode spriteNodeWithImageNamed:@"alien1"];
        alien.hidden = YES;
        [alien setXScale:0.5];
        [alien setYScale:0.5];
        [_aliens addObject:alien];
        [self addChild:alien];
    }
    
#pragma mark - Setup the lasers
    _shipLasers = [[NSMutableArray alloc] initWithCapacity:kNumLasers];
    for (int i = 0; i < kNumLasers; ++i) {
        SKSpriteNode *shipLaser = [SKSpriteNode spriteNodeWithImageNamed:@"gummy"];
        [shipLaser setScale:0.2];
        //SKSpriteNode *shipLaser = [SKSpriteNode spriteNodeWithTexture:laserTexture];
        shipLaser.hidden = YES;
        [_shipLasers addObject:shipLaser];
        [self addChild:shipLaser];
    }
    
#pragma mark - Setup the Accelerometer to move the ship
    //        _motionManager = [[CMMotionManager alloc] init];
    
#pragma mark - Setup the stars to appear as particles
    //Add particles
    [self addChild:[self loadEmitterNode:@"stars1"]];
    [self addChild:[self loadEmitterNode:@"stars2"]];
    [self addChild:[self loadEmitterNode:@"stars3"]];
    
    //        [self startBackgroundMusic];
    
    SKLabelNode *highScoreLabel;
    highScoreLabel = [[SKLabelNode alloc] initWithFontNamed:@"Futura-CondensedMedium"];
    highScoreLabel.name = @"HighscoreLabel";
    highScoreLabel.text = @"Highscore: ";
    highScoreLabel.scale = .7;
    highScoreLabel.position = CGPointMake(self.frame.size.width - 80, self.frame.size.height - 30);
    highScoreLabel.fontColor = [SKColor whiteColor];
    [self addChild:highScoreLabel];
    
    highScoreValue = [[SKLabelNode alloc] initWithFontNamed:@"Futura-CondensedMedium"];
    highScoreValue.name = @"HighscoreValue";
    highScoreValue.text = [NSString stringWithFormat:@"%.0f", _highScore];
    highScoreValue.scale = .7;
    highScoreValue.position = CGPointMake(self.frame.size.width - 30, self.frame.size.height - 30);
    highScoreValue.fontColor = [SKColor whiteColor];
    [self addChild:highScoreValue];
    
    SKLabelNode *scoreLabel;
    scoreLabel = [[SKLabelNode alloc] initWithFontNamed:@"Futura-CondensedMedium"];
    scoreLabel.name = @"scoreLabel";
    scoreLabel.text = @"Score: ";
    scoreLabel.scale = .7;
    scoreLabel.position = CGPointMake(50, self.frame.size.height - 30);
    scoreLabel.fontColor = [SKColor whiteColor];
    [self addChild:scoreLabel];

    scoreValue = [[SKLabelNode alloc] initWithFontNamed:@"Futura-CondensedMedium"];
    scoreValue.name = @"scoreValue";
    scoreValue.text = [NSString stringWithFormat:@"%.0f", _score];
    scoreValue.scale = .7;
    scoreValue.position = CGPointMake(85, self.frame.size.height - 30);
    scoreValue.fontColor = [SKColor whiteColor];
    [self addChild:scoreValue];
    _lives = 4;
    [self setupLives];
    [self updateLives];
    
    #pragma mark - Start the actual game
    [self startTheGame];
    
}

- (void)tapStartButton:(UIButton*)button
{
    
}


- (SKEmitterNode *)loadEmitterNode:(NSString *)emitterFileName
{
    NSString *emitterPath = [[NSBundle mainBundle] pathForResource:emitterFileName ofType:@"sks"];
    SKEmitterNode *emitterNode = [NSKeyedUnarchiver unarchiveObjectWithFile:emitterPath];
    
    //do some view specific tweaks
    emitterNode.particlePosition = CGPointMake(self.size.width/2.0, self.size.height/2.0);
    emitterNode.particlePositionRange = CGVectorMake(self.size.width+100, self.size.height);
    
    return emitterNode;
    
}


- (void)didMoveToView:(SKView *)view
{
    
    
}


#pragma mark - Start the Game
- (void)startTheGame
{
    _score = 0;
    _lives = 4;
    [self updateLives];
    double curTime = CACurrentMediaTime();
    _gameOverTime = curTime + 30.0;
    _nextAlienSpawn = 0;
    _gameOver = NO;
    
    for (SKSpriteNode *alien in _aliens) {
        alien.hidden = YES;
    }
    
    for (SKSpriteNode *laser in _shipLasers) {
        laser.hidden = YES;
    }
    NSLog(@"%@",_ship.color);
    _ship.color = [UIColor colorWithRed:1 green:1 blue:1 alpha:0];
    _ship.hidden = NO;

    //reset ship position for new game
    _ship.position = CGPointMake(self.frame.size.width * 0.1, CGRectGetMidY(self.frame));
    
    
    //setup to handle accelerometer readings using CoreMotion Framework
//    [self startMonitoringAcceleration];

}

- (void)setupLives
{
    live1 = [SKSpriteNode spriteNodeWithImageNamed:@"ship"];
    live2 = [SKSpriteNode spriteNodeWithImageNamed:@"ship"];
    live3 = [SKSpriteNode spriteNodeWithImageNamed:@"ship"];
    live4 = [SKSpriteNode spriteNodeWithImageNamed:@"ship"];
    lives = [NSArray arrayWithObjects:live1, live2, live3, live4, nil];
    for (int i = 0; i < _lives; i++) {
        SKSpriteNode *live = [lives objectAtIndex:i];
        [live setScale:0.07];
        live.position = CGPointMake(self.frame.size.width/2 - 45 + 30*i, self.frame.size.height - 25);
        [self addChild:live];
    }
}

- (void)updateLives
{
//    [self removeLives];
    int counter = 0;
    for (SKSpriteNode *live in lives) {
        if (counter >= _lives) {
            live.hidden = YES;
        } else {
            live.hidden = NO;
        }
        counter++;
    }
}


//- (void)startMonitoringAcceleration
//{
//    if (_motionManager.accelerometerAvailable) {
//        [_motionManager startAccelerometerUpdates];
//        NSLog(@"accelerometer updates on...");
//    }
//}
//
//- (void)stopMonitoringAcceleration
//{
//    if (_motionManager.accelerometerAvailable && _motionManager.accelerometerActive) {
//        [_motionManager stopAccelerometerUpdates];
//        NSLog(@"accelerometer updates off...");
//    }
//}

//- (void)updateShipPositionFromMotionManager
//{
//    CMAccelerometerData* data = _motionManager.accelerometerData;
//    if (fabs(data.acceleration.x) > 0.2) {
//        //NSLog(@"acceleration value = %f",data.acceleration.x);
//        [_ship.physicsBody applyForce:CGVectorMake(0.0, 40.0 * data.acceleration.x)];
//    }
//    
//}

- (void)updateShipPosition: (CGFloat) swipeLength
{
    NSLog(@"Swipe: %f",swipeLength);
    [_ship.physicsBody applyForce:CGVectorMake(0.0, swipeLength*2)];
}

- (void)startBackgroundMusic
{
    NSError *err;
    NSURL *file = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SpaceGame.caf" ofType:nil]];
    _backgroundAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:file error:&err];
    if (err) {
        NSLog(@"error in audio play %@",[err userInfo]);
        return;
    }
    [_backgroundAudioPlayer prepareToPlay];
    
    // this will play the music infinitely
    _backgroundAudioPlayer.numberOfLoops = -1;
    [_backgroundAudioPlayer setVolume:1.0];
    [_backgroundAudioPlayer play];
}


- (void)shoot {
    if (_gameOver) {
        return;
    }
    
    SKSpriteNode *shipLaser = [_shipLasers objectAtIndex:_nextShipLaser];
    _nextShipLaser++;
    if (_nextShipLaser >= _shipLasers.count) {
        _nextShipLaser = 0;
    }
    
    shipLaser.position = CGPointMake(_ship.position.x+shipLaser.size.width + 20,_ship.position.y+0);
    shipLaser.hidden = NO;
    [shipLaser removeAllActions];
    
    
    CGPoint location = CGPointMake(self.frame.size.width, _ship.position.y);
//    SKAction *laserFireSoundAction = [SKAction playSoundFileNamed:@"laser_ship.caf" waitForCompletion:NO];
    SKAction *laserMoveAction = [SKAction moveTo:location duration:0.5];
    SKAction *laserDoneAction = [SKAction runBlock:(dispatch_block_t)^() {
        //NSLog(@"Animation Completed");
        shipLaser.hidden = YES;
    }];
    
//    SKAction *moveLaserActionWithDone = [SKAction sequence:@[laserFireSoundAction, laserMoveAction,laserDoneAction]];
    SKAction *moveLaserActionWithDone = [SKAction sequence:@[laserMoveAction,laserDoneAction]];
    
    [shipLaser runAction:moveLaserActionWithDone withKey:@"laserFired"];
}

#pragma mark - Handle touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    //check if they touched our Restart Label
    for (UITouch *touch in touches) {
        SKNode *n = [self nodeAtPoint:[touch locationInNode:self]];
        NSLog(@"%@,", n.name);
        if (n != self && [n.name isEqual: @"restartLabel"]) {
            [[self childNodeWithName:@"restartLabel"] removeFromParent];
            [[self childNodeWithName:@"winLoseLabel"] removeFromParent];
            [self startTheGame];
            return;
        }
    }

    //do not process anymore touches since we are game over
    if (_gameOver) {
        return;
    }
    if (touches != nil) {
        UITouch *touch = [touches.allObjects objectAtIndex:0];
        _touchLocation = [touch locationInView:self.view];
        _touchTime = CACurrentMediaTime();
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CFTimeInterval SwipeTimeThreshold = 0.05;
    CGFloat TouchDistanceThreshold = 2;
    if (touches == nil) {
        return;
    }
    float swipeDuration = CACurrentMediaTime() - _touchTime;
    if ( swipeDuration >= SwipeTimeThreshold) {
        UITouch *touch = [touches.allObjects objectAtIndex:0];
        CGPoint touchLocation = [touch locationInView:self.view];
        CGFloat swipeLength = _touchLocation.y - touchLocation.y;
        if (fabs(swipeLength) > TouchDistanceThreshold) {
            [self updateShipPosition: swipeLength];
        } else {
            NSLog(@"Swipe distance < thresh");
        }
    } else {
        NSLog(@"Swipe duration < thresh");
    }
}


// Add new method, above update loop
- (float)randomValueBetween:(float)low andValue:(float)high {
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}


-(void)update:(NSTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    //Update background (parallax) position
    [_parallaxSpaceDust update:currentTime];
    
    [_parallaxNodeBackgrounds update:currentTime];    //other additional game background
    
    //Update ship's position
//    [self updateShipPositionFromMotionManager];
//    [self updateShipPosition];

    //Spawn aliens
    double curTime = CACurrentMediaTime();
    if (curTime > _nextAlienSpawn) {
        //NSLog(@"spawning new alien");
        float randSecs = [self randomValueBetween:0.20 andValue:1.0];
        _nextAlienSpawn = randSecs + curTime;
        
        float randY = [self randomValueBetween:0.0 andValue:self.frame.size.height];
        float randDuration = [self randomValueBetween:2.0 andValue:10.0];
        
        SKSpriteNode *alien = [_aliens objectAtIndex:_nextAlien];
        _nextAlien++;
        
        if (_nextAlien >= _aliens.count) {
            _nextAlien = 0;
        }
        
        [alien removeAllActions];
        alien.position = CGPointMake(self.frame.size.width+alien.size.width/2, randY);
        alien.hidden = NO;
        
        CGPoint location = CGPointMake(-self.frame.size.width-alien.size.width, randY);
        
        SKAction *moveAction = [SKAction moveTo:location duration:randDuration];
        SKAction *doneAction = [SKAction runBlock:(dispatch_block_t)^() {
            //NSLog(@"Animation Completed");
            alien.hidden = YES;
        }];
        
        SKAction *moveAlienActionWithDone = [SKAction sequence:@[moveAction,doneAction ]];
        
        [alien runAction:moveAlienActionWithDone withKey:@"alienMoving"];
    }
    
    //You may be wondering why the aliens are exploding and still hitting us while in the game over screen!
    //Need to set our update loop to take into account the game is over, as well as keep the background moving!
    //The following if check prevents this from happening
    if (!_gameOver) {
        //check for laser collision with alien
        for (SKSpriteNode *alien in _aliens) {
            if (alien.hidden) {
                continue;
            }
            for (SKSpriteNode *shipLaser in _shipLasers) {
                if (shipLaser.hidden) {
                    continue;
                }
                
                if ([shipLaser intersectsNode:alien]) {
                    
//                    SKAction *alienExplosionSound = [SKAction playSoundFileNamed:@"explosion_small.caf" waitForCompletion:NO];
//                    [alien runAction:alienExplosionSound];
                    
                    shipLaser.hidden = YES;
                    alien.hidden = YES;
                    _score += 1;
                    [self updateScore];
                    
                    //NSLog(@"you just destroyed an alien");
                    continue;
                }
            }
            if ([_ship intersectsNode:alien]) {
                _lives--;
                alien.hidden = YES;
                SKAction *blink = [SKAction sequence:@[[SKAction fadeOutWithDuration:0.1],
                                                       [SKAction fadeInWithDuration:0.1]]];
                SKAction *blinkForTime = [SKAction repeatAction:blink count:4];
//                SKAction *shipExplosionSound = [SKAction playSoundFileNamed:@"explosion_large.caf" waitForCompletion:NO];
//                [_ship runAction:[SKAction sequence:@[shipExplosionSound,blinkForTime]]];
//                SKAction *colorize = [SKAction colorizeWithColor: [SKColor whiteColor] colorBlendFactor: 1 duration: .3];
                _ship.colorBlendFactor = 0.9;
                NSLog(@"%d",_lives);
                switch (_lives) {
                    case 3:
                        _ship.color = [UIColor greenColor];
                        break;
                    case 2:
                        _ship.color = [UIColor orangeColor];
                        break;
                    case 1:
                        _ship.color = [UIColor redColor];
                        break;
                    default:
                        _ship.colorBlendFactor = 0;
                        break;
                }


                [_ship runAction:[SKAction sequence:@[blinkForTime]]];
                [self updateLives];
                NSLog(@"your ship has been hit!");
            }
        }
        
        // handle whether we are game over
        if (_lives <= 0) {
            NSLog(@"you lose...");
            [self endTheScene:kEndReasonLose];
        }
//        } else if (curTime >= _gameOverTime) {
//            NSLog(@"you won...");
//            [self endTheScene:kEndReasonWin];
//        }
    }
    
}

- (void)updateScore {
    scoreValue.text = [NSString stringWithFormat:@"%.0f", _score];
}

- (void)updateHighScore {
    highScoreValue.text = [NSString stringWithFormat:@"%.0f", _highScore];
}

- (void)endTheScene:(EndReason)endReason {
    if (_gameOver) {
        return;
    }
    
    [self removeAllActions];
//    [self stopMonitoringAcceleration];
    _ship.hidden = YES;
    _gameOver = YES;
    
    NSString *message;
    if (endReason == kEndReasonWin) {
        message = @"You win!";
    } else if (endReason == kEndReasonLose) {

        if (_score > _highScore) {
            _highScore = _score;
            [self updateHighScore];
            message = @"New highscore!";
        } else {
            message = @"Game over!";
        }
        [self updateScore];
    }
    
    SKLabelNode *label;
    label = [[SKLabelNode alloc] initWithFontNamed:@"Futura-CondensedMedium"];
    label.name = @"winLoseLabel";
    label.text = message;
    label.scale = 0.1;
    label.position = CGPointMake(self.frame.size.width/2, self.frame.size.height * 0.6);
    label.fontColor = [SKColor yellowColor];
    [self addChild:label];
    
    SKLabelNode *restartLabel;
    restartLabel = [[SKLabelNode alloc] initWithFontNamed:@"Futura-CondensedMedium"];
    restartLabel.name = @"restartLabel";
    restartLabel.text = @"Play Again?";
    restartLabel.scale = 0.5;
    restartLabel.position = CGPointMake(self.frame.size.width/2, self.frame.size.height * 0.4);
    restartLabel.fontColor = [SKColor yellowColor];
    restartLabel.zPosition = 1;
    [self addChild:restartLabel];
    
    SKAction *labelScaleAction = [SKAction scaleTo:1.0 duration:0.5];
    
    [restartLabel runAction:labelScaleAction];
    [label runAction:labelScaleAction];
    
}

@end