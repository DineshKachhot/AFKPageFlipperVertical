//
//  AFKPageFlipper.m
//  AFKPageFlipper
//
//  Created by Marco Tabini on 10-10-12.
//  Copyright 2010 AFK Studio Partnership. All rights reserved.
//
//  Modified by Reefaq Mohammed on 16/07/11.
 
//
#import "AFKPageFlipper.h"


#pragma mark -
#pragma mark UIView helpers


@interface UIView(Extended) 

- (UIImage *) imageByRenderingView;

@end


@implementation UIView(Extended)


- (UIImage *) imageByRenderingView {
	CGFloat oldAlpha = self.alpha;
	
	self.alpha = 1;
	UIGraphicsBeginImageContext(self.bounds.size);
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	self.alpha = oldAlpha;
	
	return resultingImage;
}

@end


#pragma mark -
#pragma mark Private interface


//@interface AFKPageFlipper()
//
//@property (nonatomic,assign) UIView *currentView;
//@property (nonatomic,assign) UIView *newView;
//
//@end


@implementation AFKPageFlipper


#pragma mark -
#pragma mark Flip functionality

@synthesize pageDifference,numberOfPages,animating;

- (void) initFlip {
    
    // Create screenshots of view
    
    UIImage *currentImage = [self.currentView imageByRenderingView];
    UIImage *newImage = [self.newView imageByRenderingView];
    
    // Hide existing views
    
    self.currentView.alpha = 0;
    self.newView.alpha = 0;
    
    // Create representational layers
    
    CGRect rect = self.bounds;
    rect.size.height /= 2;
    
    backgroundAnimationLayer = [CALayer layer];
    backgroundAnimationLayer.frame = self.bounds;
    backgroundAnimationLayer.zPosition = -300000;
    
    CALayer *topLayer = [CALayer layer];
    topLayer.frame = rect;
    topLayer.masksToBounds = YES;
    topLayer.contentsGravity = kCAGravityBottom;
    
    [backgroundAnimationLayer addSublayer:topLayer];
    
    rect.origin.y = rect.size.height;
    
    CALayer *bottomLayer = [CALayer layer];
    bottomLayer.frame = rect;
    bottomLayer.masksToBounds = YES;
    bottomLayer.contentsGravity = kCAGravityTop;
    
    [backgroundAnimationLayer addSublayer:bottomLayer];
    
    if (flipDirection == AFKPageFlipperDirectionBottom) {
        topLayer.contents = (id) [newImage CGImage];
        bottomLayer.contents = (id) [currentImage CGImage];
    } else {
        topLayer.contents = (id) [currentImage CGImage];
        bottomLayer.contents = (id) [newImage CGImage];
    }
    
    [self.layer addSublayer:backgroundAnimationLayer];
    
    rect.origin.y = 0;
    
    flipAnimationLayer = [CATransformLayer layer];
    flipAnimationLayer.anchorPoint = CGPointMake(0.5, 1);
    flipAnimationLayer.frame = rect;
    
    [self.layer addSublayer:flipAnimationLayer];
    
    CALayer *backLayer = [CALayer layer];
    backLayer.frame = flipAnimationLayer.bounds;
    backLayer.doubleSided = NO;
    backLayer.masksToBounds = YES;
    
    [flipAnimationLayer addSublayer:backLayer];
    
    CALayer *frontLayer = [CALayer layer];
    frontLayer.frame = flipAnimationLayer.bounds;
    frontLayer.doubleSided = NO;
    frontLayer.masksToBounds = YES;
    
    frontLayer.transform = CATransform3DMakeRotation(M_PI, 1.0, 0.0, 0);
    
    [flipAnimationLayer addSublayer:frontLayer];
    
    if (flipDirection == AFKPageFlipperDirectionBottom) {
        backLayer.contents = (id) [currentImage CGImage];
        backLayer.contentsGravity = kCAGravityBottom;
        
        frontLayer.contents = (id) [newImage CGImage];
        frontLayer.contentsGravity = kCAGravityTop;
        
        CATransform3D transform = CATransform3DMakeRotation(1.1/M_PI, 1.0, 0.0, 0.0);
        transform.m34 = 1.0f / 2500.0f;
        
        flipAnimationLayer.transform = transform;
        
        currentAngle = startFlipAngle = 0;
        endFlipAngle = M_PI;
    } else {
        //down
        backLayer.contents = (id) [newImage CGImage];
        backLayer.contentsGravity = kCAGravityBottom;
        
        frontLayer.contents = (id) [currentImage CGImage];
        frontLayer.contentsGravity = kCAGravityTop;
        
        CATransform3D transform = CATransform3DMakeRotation(M_PI/1.1, 1.0, 0.0, 0.0);
        transform.m34 = 1.0f / 2500.0f;
        
        flipAnimationLayer.transform = transform;
        
        currentAngle = startFlipAngle = M_PI;
        endFlipAngle = 0;
    }
}


- (void) cleanupFlip {
	[backgroundAnimationLayer removeFromSuperlayer];
	[flipAnimationLayer removeFromSuperlayer];
	if (pageDifference > 1) {
		[blankFlipAnimationLayerOnLeft1 removeFromSuperlayer];
		[blankFlipAnimationLayerOnRight1 removeFromSuperlayer];
		blankFlipAnimationLayerOnLeft1 = Nil;
		blankFlipAnimationLayerOnRight1 = Nil;
		
		if (pageDifference > 2) {
			[blankFlipAnimationLayerOnLeft2 removeFromSuperlayer];
			[blankFlipAnimationLayerOnRight2 removeFromSuperlayer];
			blankFlipAnimationLayerOnLeft2 = Nil;
			blankFlipAnimationLayerOnRight2 = Nil;
		}	
	}
	backgroundAnimationLayer = Nil;
	flipAnimationLayer = Nil;
	
	animating = NO;
	
	if (setNewViewOnCompletion) {
		[self.currentView removeFromSuperview];
		self.currentView = self.newView;
		self.newView = Nil;
	} else {
		[self.newView removeFromSuperview];
		self.newView = Nil;
	}
	
	setNewViewOnCompletion = NO;
	[self.currentView setHidden:FALSE];
	self.currentView.alpha = 1;
	[self setDisabled:FALSE];
	
}



- (void) setFlipProgress3:(NSDictionary*)dict{
	
	float progress =[[dict objectForKey:@"PROGRESS"] floatValue];
	BOOL setDelegate = [[dict objectForKey:@"DELEGATE"] boolValue];
	BOOL animate = [[dict objectForKey:@"ANIMATE"] boolValue];
	
	
	float newAngle = startFlipAngle + progress * (endFlipAngle - startFlipAngle);
	float duration = animate ? 0.5 * fabs((newAngle - currentAngle) / (endFlipAngle - startFlipAngle)) : 0;
	
	duration = 0.5;
	
	CATransform3D endTransform = CATransform3DIdentity;
	endTransform.m34 = 1.0f / 2500.0f;
	endTransform = CATransform3DRotate(endTransform, newAngle, 1.0, 0.0, 0.0);
	
	
	[blankFlipAnimationLayerOnLeft2 removeAllAnimations];
	
	[blankFlipAnimationLayerOnRight2 removeAllAnimations];
	
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:duration];
	blankFlipAnimationLayerOnLeft2.transform = endTransform;
	blankFlipAnimationLayerOnRight2.transform = endTransform;
	[UIView commitAnimations];
	
	if (setDelegate) {
		[self performSelector:@selector(cleanupFlip) withObject:Nil afterDelay:duration];
	}
}

- (void) setFlipProgress2:(NSDictionary*)dict{
	
	float progress =[[dict objectForKey:@"PROGRESS"] floatValue];
	BOOL setDelegate = [[dict objectForKey:@"DELEGATE"] boolValue];
	BOOL animate = [[dict objectForKey:@"ANIMATE"] boolValue];
	
	
	float newAngle = startFlipAngle + progress * (endFlipAngle - startFlipAngle);
	float duration = animate ? 0.5 * fabs((newAngle - currentAngle) / (endFlipAngle - startFlipAngle)) : 0;
	
	duration = 0.5;
	
	CATransform3D endTransform = CATransform3DIdentity;
	endTransform.m34 = 1.0f / 2500.0f;
	endTransform = CATransform3DRotate(endTransform, newAngle, 1.0, 0.0, 0.0);
	
	
	[blankFlipAnimationLayerOnLeft1 removeAllAnimations];
	
	[blankFlipAnimationLayerOnRight1 removeAllAnimations];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:duration];
	blankFlipAnimationLayerOnLeft1.transform = endTransform;	
	blankFlipAnimationLayerOnRight1.transform = endTransform;
	[UIView commitAnimations];
	
	
	if (pageDifference > 2) {
		
		NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
		[dictionary setObject:[NSString stringWithFormat:@"%f",progress] forKey:@"PROGRESS"];
		[dictionary setObject:[NSString stringWithFormat:@"%d",setDelegate] forKey:@"DELEGATE"];
		[dictionary setObject:[NSString stringWithFormat:@"%d",animate] forKey:@"ANIMATE"];	
		
		[self performSelector:@selector(setFlipProgress3:) withObject:dictionary afterDelay:0.12];
		
		[dictionary release];
		
	}else {
		if (setDelegate) {
			[self performSelector:@selector(cleanupFlip) withObject:Nil afterDelay:duration];
		}
	}	
	
}

- (void) setFlipProgress:(float) progress setDelegate:(BOOL) setDelegate animate:(BOOL) animate {
	
	float newAngle = startFlipAngle + progress * (endFlipAngle - startFlipAngle);
	float duration = animate ? 0.5 * fabs((newAngle - currentAngle) / (endFlipAngle - startFlipAngle)) : 0;
	
	currentAngle = newAngle;
	
	CATransform3D endTransform = CATransform3DIdentity;
	endTransform.m34 = 1.0f / 2500.0f;
	endTransform = CATransform3DRotate(endTransform, newAngle, 1.0, 0.0, 0.0);
	
	[flipAnimationLayer removeAllAnimations];
	
	// shadows
	CGFloat newShadowOpacity = progress;
	if (endFlipAngle > startFlipAngle) newShadowOpacity = 1.0 - progress;
	// shadows

	if (duration < 0.35) {
		duration = 0.35;
	}
	
	[UIView beginAnimations:@"FLIP1" context:nil];
	[UIView setAnimationDuration:duration];
	flipAnimationLayer.transform =  endTransform;
	
	// shadows
	frontLayerShadow.opacity = 1.0 - newShadowOpacity;
	backLayerShadow.opacity = newShadowOpacity;
	leftLayerShadow.opacity = 0.5 - newShadowOpacity;
	rightLayerShadow.opacity = newShadowOpacity - 0.5;
	// shadows
	[UIView commitAnimations];
	
	if (pageDifference > 1) {
		
		NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
		[dict setObject:[NSString stringWithFormat:@"%f",progress] forKey:@"PROGRESS"];
		[dict setObject:[NSString stringWithFormat:@"%d",setDelegate] forKey:@"DELEGATE"];
		[dict setObject:[NSString stringWithFormat:@"%d",animate] forKey:@"ANIMATE"];	
		
		[self performSelector:@selector(setFlipProgress2:) withObject:dict afterDelay:0.12];
		
		[dict release];
		
	}else {
		if (setDelegate) {
			[self performSelector:@selector(cleanupFlip) withObject:Nil afterDelay:duration];
		}
	}
	
	
}

- (void) flipPage {
	[self setFlipProgress:1.0 setDelegate:YES animate:YES];
}


#pragma mark -
#pragma mark Animation management


- (void)animationDidStop:(NSString *) animationID finished:(NSNumber *) finished context:(void *) context {
	[self cleanupFlip];
}


#pragma mark -
#pragma mark Properties

@synthesize currentView;


- (void) setCurrentView:(UIView *) value {
	if (currentView) {
		[currentView release];
	}
	
	currentView = [value retain];
}


@synthesize newView;


- (void) setNewView:(UIView *) value {
	if (newView) {
		[newView release];
	}
	
	newView = [value retain];
}


@synthesize currentPage;


- (BOOL) doSetCurrentPage:(NSInteger) value {
	if (value == currentPage) {
		return FALSE;
	}
	
	flipDirection = value < currentPage ? AFKPageFlipperDirectionBottom : AFKPageFlipperDirectionTop;
	
	currentPage = value;
	
	self.newView = [self.dataSource viewForPage:value inFlipper:self];
	
	[self addSubview:self.newView];
	
	return TRUE;
}	

- (void) setCurrentPage:(NSInteger) value {
	if (![self doSetCurrentPage:value]) {
		return;
	}
	
	setNewViewOnCompletion = YES;
	animating = NO;
	
	[self.newView setHidden:TRUE];
	self.newView.alpha = 0;
	
	
	[UIView beginAnimations:@"" context:Nil];
	[UIView setAnimationDuration:0.1];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	
	[self.newView setHidden:FALSE];	
	self.newView.alpha = 1;
	
	[UIView commitAnimations];
	
	
} 


- (void) setCurrentPage:(NSInteger) value animated:(BOOL) animated {
	
	
	pageDifference = fabs(value - currentPage);
	
	if (![self doSetCurrentPage:value]) {
		return;
	}
	
	setNewViewOnCompletion = YES;
	animating = YES;
	
	if (animated) {
		[self setDisabled:TRUE];
		[self initFlip];
		//[self setFlipProgress:0.01 setDelegate:NO animate:NO];
		
		if (pageDifference > 1) {
			NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
			[dictionary setObject:[NSString stringWithFormat:@"%f",0.01] forKey:@"PROGRESS"];
			[dictionary setObject:[NSString stringWithFormat:@"%d",NO] forKey:@"DELEGATE"];
			[dictionary setObject:[NSString stringWithFormat:@"%d",NO] forKey:@"ANIMATE"];	
			
			//multi-flip-for 2
			[self setFlipProgress2:dictionary];
			
			if (pageDifference > 2) {
				//multi flip-for more than 2
				[self setFlipProgress3:dictionary];
			}
			
			[dictionary release];
		}
		[self performSelector:@selector(flipPage) withObject:Nil afterDelay:0.000];
	} else {
		[self animationDidStop:Nil finished:[NSNumber numberWithBool:NO] context:Nil];
	}
	
}


@synthesize dataSource;


- (void) setDataSource:(NSObject <AFKPageFlipperDataSource>*) value {
	
	if (dataSource) {
		[dataSource release];
	}
	
	dataSource = [value retain];
	numberOfPages = [dataSource numberOfPagesForPageFlipper:self];
	self.currentPage = 1;
}


@synthesize disabled;


- (void) setDisabled:(BOOL) value {
	disabled = value;
	
	self.userInteractionEnabled = !value;
	
	for (UIGestureRecognizer *recognizer in self.gestureRecognizers) {
		recognizer.enabled = !value;
	}
}

#pragma mark -
#pragma mark Touch management


- (void) panned:(UIPanGestureRecognizer *) recognizer {
	static BOOL hasFailed;
	static BOOL initialized;
	
	static NSInteger oldPage;
	
	float translation = [recognizer translationInView:self].y;
	
	float progress = translation / self.bounds.size.height;
	
	if (flipDirection == AFKPageFlipperDirectionTop) {
		progress = MIN(progress, 0);
	} else {
		progress = MAX(progress, 0);
	}
	
	pageDifference = 1;
	
	switch (recognizer.state) {
		case UIGestureRecognizerStateBegan:
			if (!animating) {
				hasFailed = FALSE;
				initialized = FALSE;
				animating = NO;
				setNewViewOnCompletion = NO;
			}
			break;
			
		case UIGestureRecognizerStateChanged:
			if (hasFailed) {
				return;
			}
			
			if (!initialized) {
				oldPage = self.currentPage;
				
				if (translation > 0) {
					if (self.currentPage > 1) {
						[self doSetCurrentPage:self.currentPage - 1];
					} else {
						hasFailed = TRUE;
						return;
					}
				} else {
					if (self.currentPage < numberOfPages) {
						[self doSetCurrentPage:self.currentPage + 1];
					} else {
						hasFailed = TRUE;
						return;
					}
				}
				
				hasFailed = NO;
				initialized = TRUE;
				animating = YES;
				setNewViewOnCompletion = NO;
				
				[self initFlip];
			}
			
			[self setFlipProgress:fabs(progress) setDelegate:NO animate:YES];
			break;
			
		case UIGestureRecognizerStateFailed:
			[self setDisabled:TRUE];
			[self setFlipProgress:0.0 setDelegate:YES animate:YES];
			currentPage = oldPage;
			break;
			
		case UIGestureRecognizerStateRecognized:
			if (initialized) {
				if (hasFailed) {
					[self setDisabled:TRUE];
					[self setFlipProgress:0.0 setDelegate:YES animate:YES];
					currentPage = oldPage;
					return;
				}
				[self setDisabled:TRUE];
				setNewViewOnCompletion = YES;
				[self setFlipProgress:1.0 setDelegate:YES animate:YES];
			}
			
			break;
	}
}


#pragma mark -
#pragma mark Frame management


- (void) setFrame:(CGRect) value {
	super.frame = value;
	
	numberOfPages = [dataSource numberOfPagesForPageFlipper:self];
	
	if (self.currentPage > numberOfPages) {
		self.currentPage = numberOfPages;
	}
	
}


#pragma mark -
#pragma mark Initialization and memory management


+ (Class) layerClass {
	return [CATransformLayer class];
}


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		UIPanGestureRecognizer *panRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)] autorelease];
		[panRecognizer setMaximumNumberOfTouches:1];
		[self addGestureRecognizer:panRecognizer];
		
		flipIllusionPortrait = [[UIImage imageNamed:@"flip-illusion-oriented.jpg"] retain];
		flipIllusionLandscape = [[UIImage imageNamed:@"flip-illusion.png"] retain];
		
		animating = FALSE;
    }
    return self;
}


- (void)dealloc {
	self.dataSource = Nil;
	self.currentView = Nil;
	self.newView = Nil;
    [super dealloc];
}


@end
