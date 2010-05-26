//
//  TweenScene.m
//  Demo
//
//  Created by Daniel Sperl on 23.08.09.
//  Copyright 2009 Incognitek. All rights reserved.
//

#import "AnimationScene.h"

@interface AnimationScene ()

- (void)setupScene;
- (void)resetSaturn;
- (void)colorizeSaturn:(BOOL)colorize;

@end

@implementation AnimationScene

- (id)init
{
    if (self = [super init])
    {
        // define some sample transitions for the animation demo. There are more available!
        mTransitions = [[NSMutableArray alloc] initWithObjects:
                        SP_TRANSITION_LINEAR, SP_TRANSITION_EASE_OUT, 
                        SP_TRANSITION_EASE_IN_OUT, SP_TRANSITION_EASE_OUT_BACK,
                        SP_TRANSITION_EASE_OUT_BOUNCE, SP_TRANSITION_EASE_OUT_ELASTIC, nil];
        [self setupScene];        
    }
    return self;
}

- (void)setupScene
{    
    SPTextureAtlas *atlas = [SPTextureAtlas atlasWithContentsOfFile:@"atlas.xml"];   
    
    // we create a button that is used to start the tween.
    mStartButton = [[SPButton alloc] initWithUpState:[atlas textureByName:@"button_wide"] 
                                           text:@"Start animation"];
    [mStartButton addEventListener:@selector(onStartButtonPressed:) atObject:self
                           forType:SP_EVENT_TYPE_TRIGGERED];
    mStartButton.x = 80;
    mStartButton.y = 20;
    [self addChild:mStartButton];
    
    // this button will show you how to call a method in the future
    mDelayButton = [[SPButton alloc] initWithUpState:[atlas textureByName:@"button_wide"]
                                                         text:@"Make delayed call"];
    [mDelayButton addEventListener:@selector(onDelayButtonPressed:) atObject:self
                           forType:SP_EVENT_TYPE_TRIGGERED];
    mDelayButton.x = mStartButton.x;
    mDelayButton.y = mStartButton.y + 40;    
    [self addChild:mDelayButton];
    
    // the saturn image will be tweened.
    mSaturn = [[SPImage alloc] initWithTexture:[atlas textureByName:@"saturn"]];
    [self resetSaturn];
    [self addChild:mSaturn];
    
    mTransitionLabel = [[SPTextField alloc] initWithText:@""];
    mTransitionLabel.color = 0xffffff;
    mTransitionLabel.x = 0;
    mTransitionLabel.y = mDelayButton.y + 40;
    mTransitionLabel.width = 320;
    mTransitionLabel.height = 30;
    mTransitionLabel.alpha = 0.0f; // invisible, will be shown later
    [self addChild:mTransitionLabel];      
}

- (void)resetSaturn
{
    mSaturn.x = 20;
    mSaturn.y = 140;
    mSaturn.scaleX = mSaturn.scaleY = 1.0f;
    mSaturn.rotation = 0.0f;
}

- (void)onStartButtonPressed:(SPEvent *)event
{
    mStartButton.enabled = NO;
    [self resetSaturn];
    
    // get next transition style from array and enqueue it at the end
    NSString *transition = [mTransitions objectAtIndex:0];
    [mTransitions removeObjectAtIndex:0];
    [mTransitions addObject:transition];
    
    // to animate any numeric property of an arbitrary object (not just display objects!), you
    // can create a 'Tween'. One tween object animates one target for a certain time, with
    // a certain transition function.    
    SPTween *tween = [SPTween tweenWithTarget:mSaturn time:5.0f transition:transition];

    // you can animate any property as long as it's numeric (float, double, int). 
    // it is animated from it's current value to a target value.    
    [tween animateProperty:@"x" targetValue:300];
    [tween animateProperty:@"y" targetValue:320];
    [tween animateProperty:@"scaleX" targetValue:0.5];
    [tween animateProperty:@"scaleY" targetValue:0.5];
    [tween animateProperty:@"rotation" targetValue:PI_HALF];
    [tween addEventListener:@selector(onTweenComplete:) atObject:self 
                    forType:SP_EVENT_TYPE_TWEEN_COMPLETED retainObject:YES];

    // the tween alone is useless -- once in every frame, it has to be advanced, so that the 
    // animation occurs. This is done by the 'Juggler'. It receives the tween and will use it to 
    // animate the object. 
    // There is a default juggler at the stage, but you can create your own jugglers, as well.
    // That way, you can group animations into logical parts.    
    [self.stage.juggler addObject:tween];
    
    // show which tweening function is used
    mTransitionLabel.text = transition;
    mTransitionLabel.alpha = 1.0f;
    SPTween *hideTween = [SPTween tweenWithTarget:mTransitionLabel time:4.0f 
                                       transition:SP_TRANSITION_EASE_IN];
    [hideTween animateProperty:@"alpha" targetValue:0.0f];
    [self.stage.juggler addObject:hideTween];
}

- (void)onTweenComplete:(SPEvent*)event
{    
    mStartButton.enabled = YES;
    [(SPTween*)event.target removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TWEEN_COMPLETED];
}

- (void)onDelayButtonPressed:(SPEvent *)event
{
    mDelayButton.enabled = NO;
    
    // Using the juggler, you can delay a method call.
    //
    // This is especially useful when used with your own juggler. Assume your game has one class
    // that handles the playing field. This class has its own juggler, and advances it in every 
    // frame. (By calling [myJuggler advanceTime:]).    
    // All animations and delayed calls (!) within the playing field are added to this 
    // juggler. Now, when the game is paused, all you have to do is *not* to advance this juggler.
    // Everything will be paused: animations as well as the delayed calls.
    //
    // the method [SPJuggler delayInvocationAtTarget:byTime:] returns a proxy object. Call
    // the method you would like to call on this proxy object instead of the real method target.
    // In this sample, [self colorizeSaturn:] will be called after the specified delay.
    
    [[self.stage.juggler delayInvocationAtTarget:self byTime:1.0f] colorizeSaturn:YES];
    [[self.stage.juggler delayInvocationAtTarget:self byTime:2.0f] colorizeSaturn:NO];    
}

- (void)colorizeSaturn:(BOOL)colorize
{
    if (colorize) mSaturn.color = 0x00ff00; // 0xrrggbb
    else 
    {    
        mSaturn.color = 0xffffff; // white, the standard color of a quad
        mDelayButton.enabled = YES;
    }
}

- (void)dealloc
{
    [mStartButton removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    [mDelayButton removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    [mStartButton release];
    [mDelayButton release];    
    [mSaturn release];
    [mTransitionLabel release];  
    [mTransitions release];
    [super dealloc];
}

@end
