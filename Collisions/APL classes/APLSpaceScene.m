/*
     File: APLSpaceScene.m
 Abstract: 
 This is the scene that implements the physics demo. It is responsible for handling keyboard inputs and driving the simulation in response to user input and physics interactions.
 
  Version: 1.1
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "APLSpaceScene.h"
#import "APLShipSprite.h"

//=========================
@interface APLSpaceScene ()
@property BOOL contentCreated;
@property APLShipSprite *controlledShip;
@end

// Useful randomizer functions.
static inline CGFloat myRandf() {
    return rand() / (CGFloat) RAND_MAX;
}

static inline CGFloat myRand(CGFloat low, CGFloat high) {
    return myRandf() * (high - low) + low;
}

/* Simulation constants used to tweak  game play. */

// sizes for the various kinds of objects
static const CGFloat shotSize = 4;
static const CGFloat asteroidSize = 18;
static const CGFloat planetSize = 128;

static const CFTimeInterval missileExplosionDuration = 0.1;
static const CGFloat collisonDamageThreshold = 3.0;
static const NSInteger missileDamage = 1;

//=========================
@implementation APLSpaceScene

#pragma mark - Initialization
//-------------------------
-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
    
    }
    return self;
}

//-------------------------
- (void)didMoveToView:(SKView *)view {
    if (!self.contentCreated) {
        [self createSceneContents];
        self.contentCreated = YES;
    }
}

//-------------------------
- (void)createSceneContents {
    self.backgroundColor = [SKColor blackColor];
    self.scaleMode = SKSceneScaleModeAspectFit;
    
    // Give the scene an edge and configure other physics info on the scene.
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsBody.categoryBitMask = edgeCategory;
    self.physicsBody.collisionBitMask = 0;
    self.physicsBody.contactTestBitMask = 0;
    self.physicsWorld.gravity = CGVectorMake(0,0);
    self.physicsWorld.contactDelegate = self;
    
    /* 
     In this sample, the positions of everything is hard coded. In an actual game, you might implement this in an archive that is loaded from a file.
     */
    self.controlledShip = [APLShipSprite createShip];
	CGFloat frameHeight = self.frame.size.height;
    self.controlledShip.position = CGPointMake (100,frameHeight - 100.);
    [self addChild:self.controlledShip];
    
    // this ship isn't connected to any controls so it doesn't move, except when it collides with something.
    SKNode *targetShip = [APLShipSprite createTargetShip];
    targetShip.position = CGPointMake(200,frameHeight - 200.);
    [self addChild:targetShip];
    
    SKNode *rock = [self newAsteroidNode];
    rock.position = CGPointMake(100,200);
    [self addChild:rock];
    
    SKNode *planet = [self newPlanetNode];
    planet.position = CGPointMake(500,100);
    [self addChild:planet];
}

//-------------------------
- (SKNode*) newMissileNode {
    /*
     Creates and returns a new missile game object.
     This method loads a preconfigured emitter from an archive, and then configures it with a physics body.
     */
    SKEmitterNode *missile =  [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"missile" ofType:@"sks"]];
    
    // The missile particles should be spawned in the scene, not on the missile object.
    missile.targetNode = self;
    
    missile.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:shotSize];
    missile.physicsBody.categoryBitMask = missileCategory;
    missile.physicsBody.contactTestBitMask = shipCategory | asteroidCategory | planetCategory | edgeCategory;
    missile.physicsBody.collisionBitMask = 0;
    
    return missile;
}

//-------------------------
- (SKNode*) newAsteroidNode {
    /* Creates and returns a new asteroid game object.
     
     For this sample, we just use a shape node for the asteroid.
     */
    SKShapeNode *asteroid = [[SKShapeNode alloc] init];
    CGMutablePathRef myPath = CGPathCreateMutable();
    CGPathAddArc(myPath, NULL, 0,0, asteroidSize, 0, M_PI*2, YES);
    asteroid.path = myPath;
    CGPathRelease(myPath);
    asteroid.strokeColor = [SKColor clearColor];
    asteroid.fillColor = [SKColor brownColor];
    
    asteroid.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:asteroidSize];
    asteroid.physicsBody.categoryBitMask = asteroidCategory;
    asteroid.physicsBody.collisionBitMask = shipCategory | asteroidCategory | edgeCategory;
    asteroid.physicsBody.contactTestBitMask = planetCategory;
    
    return asteroid;
}

//-------------------------
- (SKNode*) newPlanetNode {
    /* Creates and returns a new planet game object.
     
     For this sample, we just use a shape node for the planet.
     */
    
    SKShapeNode *planet = [[SKShapeNode alloc] init];
    CGMutablePathRef myPath = CGPathCreateMutable();
    CGPathAddArc(myPath, NULL, 0,0, planetSize, 0, M_PI*2, YES);
    planet.path = myPath;
    CGPathRelease(myPath);
    planet.strokeColor = [SKColor clearColor];
    planet.fillColor = [SKColor greenColor];
    
    planet.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:planetSize];
    planet.physicsBody.categoryBitMask = planetCategory;
    planet.physicsBody.collisionBitMask = planetCategory | edgeCategory;
    planet.physicsBody.contactTestBitMask = 0;
    
    return planet;
}

//-------------------------
- (SKEmitterNode*) newExplosionNode: (CFTimeInterval) explosionDuration {
    SKEmitterNode *emitter =  [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"explosion" ofType:@"sks"]];
    
    // Explosions always place their particles into the scene.
    emitter.targetNode = self;
    
    // Stop spawning particles after enough have been spawned.
    emitter.numParticlesToEmit = explosionDuration * emitter.particleBirthRate;
    
    // Calculate a time value that allows all the spawned particles to die. After this, the emitter node can be removed.

    CFTimeInterval totalTime = explosionDuration + emitter.particleLifetime+emitter.particleLifetimeRange/2;
    [emitter runAction:[SKAction sequence:@[[SKAction waitForDuration:totalTime],
                                            [SKAction removeFromParent]]]];
    return emitter;
}

#pragma mark - Physics Handling and Game Logic
//-------------------------
- (void)detonateMissile:(SKNode *)missile {
    SKEmitterNode *explosion = [self newExplosionNode: missileExplosionDuration];
    explosion.position = missile.position;
    [self addChild:explosion];
    [missile removeFromParent];
}

//-------------------------
- (void) attackTarget: (SKPhysicsBody*) target withMissile: (SKNode*) missile {
    // Only ships take damage from missiles.
    if ((target.categoryBitMask & shipCategory) != 0) {
        APLShipSprite *targetShip = (APLShipSprite*) target.node;
        [targetShip applyDamage:missileDamage];
    }
    [self detonateMissile:missile];
}

//-------------------------
- (void)didBeginContact:(SKPhysicsContact *)contact {
    // Handle contacts between two physics bodies.
    
    // Contacts are often a double dispatch problem; the effect you want is based
    // on the type of both bodies in the contact. This sample  solves
    // this in a brute force way, by checking the types of each. A more complicated
    // example might use methods on objects to perform the type checking.
    
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;

    // The contacts can appear in either order, and so normally you'd need to check
    // each against the other. In this example, the category types are well ordered, so
    // the code swaps the two bodies if they are out of order. This allows the code
    // to only test collisions once.
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    // Missiles attack whatever they hit, then explode.
    
    if ((firstBody.categoryBitMask & missileCategory) != 0) {
        [self attackTarget: secondBody withMissile:firstBody.node];
    }
    
    // Ships collide and take damage. The collision damage is based on the strength of the collision.
    if ((firstBody.categoryBitMask & shipCategory) != 0) {
        // The edge exists just to keep all gameplay on one screen, so ships should not take damage when they hit the
        // edge.
        
        if ((contact.collisionImpulse > collisonDamageThreshold) && ((secondBody.categoryBitMask & edgeCategory) == 0)) {
            APLShipSprite *targetShip = (APLShipSprite*)firstBody.node;
            [targetShip applyDamage:contact.collisionImpulse / collisonDamageThreshold];
            
            // If two ships collide with each other, both take damage. Planets and asteroids take no damage from ships.
            if (secondBody.categoryBitMask & shipCategory) {
                targetShip = (APLShipSprite*)secondBody.node;
                [targetShip applyDamage:contact.collisionImpulse / collisonDamageThreshold];
            }
        }
    }
    
    // Asteroids that hit planets are destroyed.
    if (((firstBody.categoryBitMask & asteroidCategory) != 0) &&
        ((secondBody.categoryBitMask & planetCategory) != 0)) {
        [firstBody.node removeFromParent];
    }
}


#pragma mark - Run Loop
//-------------------------
- (void)update:(NSTimeInterval)currentTime {
    // This runs once every frame. Other sorts of logic might run from here. For example,
    // if the target ship was controlled by the computer, you might run AI from this routine.
    
    [self updatePlayerShip:currentTime];
}

//-------------------------
- (void)updatePlayerShip:(NSTimeInterval)currentTime {
    if (actions[kPlayerForward]) {
        [self.controlledShip activateMainEngine];
    } else {
        [self.controlledShip deactivateMainEngine];
    }
    if (actions[kPlayerBack]) {
        [self.controlledShip reverseThrust];
    }
    if (actions[kPlayerLeft]) {
        [self.controlledShip rotateShipLeft];
    }
    if (actions[kPlayerRight]) {
        [self.controlledShip rotateShipRight];
    }
    if (actions[kPlayerAction]) {
        [self.controlledShip attemptMissileLaunch:currentTime];
    }
}

//--------------------------
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
     actions[kPlayerAction] = ! actions[kPlayerAction];
}

//-------------------------
- (void)leftAction:(id)sender {
	actions[kPlayerLeft] = ! actions[kPlayerLeft];
}

//-------------------------
- (void)forwardAction:(id)sender {
	actions[kPlayerForward] = ! actions[kPlayerForward] ;
}

//-------------------------
- (void)backAction:(id)sender {
	actions[kPlayerBack] = ! actions[kPlayerBack];
}

//-------------------------
- (void)rightAction:(id)sender {
	actions[kPlayerRight] = ! actions[kPlayerRight];
}

@end
