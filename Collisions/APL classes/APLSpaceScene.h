/*
     File: APLSpaceScene.h
 Abstract: 
 This is the scene that implements the physics demo. It is responsible for handling keyboard inputs and driving the simulation in response to user input and physics interactions.
 
  Version: 1.1
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import <SpriteKit/SpriteKit.h>

// These constants are used to map keyboard events into player events.
typedef enum {
    kPlayerForward = 0,
    kPlayerLeft = 1,
    kPlayerRight = 2,
    kPlayerBack = 3,
    kPlayerAction = 4,
    kNumPlayerActions
} PlayerActions;

// These constans are used to define the physics interactions between physics bodies in the scene.
static const uint32_t missileCategory  =  0x1 << 0;
static const uint32_t shipCategory     =  0x1 << 1;
static const uint32_t asteroidCategory =  0x1 << 2;
static const uint32_t planetCategory   =  0x1 << 3;
static const uint32_t edgeCategory     =  0x1 << 4;

//============================
@interface APLSpaceScene : SKScene <SKPhysicsContactDelegate>
{
    BOOL     actions[kNumPlayerActions];
}

- (SKEmitterNode*)  newExplosionNode: (CFTimeInterval) explosionDuration;
- (SKNode*)         newMissileNode;

#pragma mark - Actions
//--------------------------
- (void)leftAction:(id)sender;
- (void)forwardAction:(id)sender;
- (void)backAction:(id)sender;
- (void)rightAction:(id)sender;
@end


