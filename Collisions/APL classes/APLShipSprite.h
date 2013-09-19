/*
     File: APLShipSprite.h
 Abstract: 
 This class adds game logic for a ship sprite.
 
  Version: 1.1
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import <SpriteKit/SpriteKit.h>

@interface APLShipSprite : SKSpriteNode
@property (readonly) NSInteger health;

// always use this to create ships.
+ (id)createShip;
+ (id)createTargetShip;

- (void)applyDamage: (NSInteger) amount;

// methods used to control the ship.
- (void)activateMainEngine;
- (void)deactivateMainEngine;
- (void)reverseThrust;
- (void)rotateShipLeft;
- (void)rotateShipRight;
- (void)attemptMissileLaunch:(NSTimeInterval)currentTime;
@end
