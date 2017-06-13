//
//  FOTWindow.m
//
//  Created by Guilherme Rambo on 27/10/13.
//  Copyright (c) 2013 Guilherme Rambo. All rights reserved.
//

#import "FOTWindow.h"

#define kTitleBarHeight 22.0

@implementation FOTWindowTitle

@end

#pragma mark -

@interface FOTWindowFrame ()

@property (strong) FOTWindowTitle *titleBar;
@property (strong) NSTrackingArea *trackingArea;

@end

@implementation FOTWindowFrame

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self) {
        _titleBar = [[FOTWindowTitle alloc] initWithFrame:NSMakeRect(0, NSHeight(self.frame)-kTitleBarHeight, NSWidth(self.frame), kTitleBarHeight)];
        [_titleBar setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin|NSViewMinXMargin];
        [_titleBar setAlphaValue:0];
        [self addSubview:_titleBar];
        
        self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways ) owner:self userInfo:nil];
        
        [self addTrackingArea:self.trackingArea];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredFullscreen:)
                                                     name: NSWindowWillEnterFullScreenNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exitedFullscreen:)
                                                     name: NSWindowDidExitFullScreenNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    
    if(self.trackingArea) {
        [self removeTrackingArea:self.trackingArea];
        
        self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways ) owner:self userInfo:nil];
        
        [self addTrackingArea:self.trackingArea];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    NSLog(@"entered");
    FOTWindow* window = (FOTWindow*)self.window;
    [[window standardWindowButton:NSWindowCloseButton].animator setAlphaValue:1];
    [[window standardWindowButton:NSWindowZoomButton].animator setAlphaValue:1];
    [[window standardWindowButton:NSWindowMiniaturizeButton].animator setAlphaValue:1];
    [[window standardWindowButton:NSWindowDocumentIconButton].animator setAlphaValue:1];
    [[window standardWindowButton:NSWindowFullScreenButton].animator setAlphaValue:1];
    [[window standardWindowButton:NSWindowDocumentIconButton] setAlphaValue:1];
    [_titleBar.animator setAlphaValue:1];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    NSLog(@"exited");
    FOTWindow* window = (FOTWindow*)self.window;
    [[window standardWindowButton:NSWindowCloseButton].animator setAlphaValue:window.titleBarFadeOutAlphaValue];
    [[window standardWindowButton:NSWindowZoomButton].animator setAlphaValue:window.titleBarFadeOutAlphaValue];
    [[window standardWindowButton:NSWindowMiniaturizeButton].animator setAlphaValue:window.titleBarFadeOutAlphaValue];
    [[window standardWindowButton:NSWindowDocumentIconButton].animator setAlphaValue:window.titleBarFadeOutAlphaValue];
    [[window standardWindowButton:NSWindowFullScreenButton].animator setAlphaValue:window.titleBarFadeOutAlphaValue];
    [[window standardWindowButton:NSWindowDocumentIconButton] setAlphaValue:window.titleBarFadeOutAlphaValue];
    [_titleBar.animator setAlphaValue:window.titleBarFadeOutAlphaValue];
}


- (void)enteredFullscreen:(NSNotification *)sender {
    [self removeTrackingArea:self.trackingArea];
    self.trackingArea = nil;
}

- (void)exitedFullscreen:(NSNotification *)sender {
    [self removeTrackingArea:self.trackingArea];
    
    self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways ) owner:self userInfo:nil];
    
    [self addTrackingArea:self.trackingArea];
}


@end

#pragma mark -

@implementation FOTWindow
{
    NSView *_originalThemeFrame;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:NO];
    
    if (self) {
        _titleBarFadeInAlphaValue = 1.0;
        _titleBarFadeOutAlphaValue = 0.0;
        
        _originalThemeFrame = [self.contentView superview];
        _originalThemeFrame.wantsLayer = YES;
        
        _fullContentView = [[FOTWindowFrame alloc] initWithFrame:self.frame];
        _fullContentView.wantsLayer = YES;
        
        [_originalThemeFrame addSubview:_fullContentView positioned:NSWindowBelow relativeTo:_originalThemeFrame.subviews[0]];
        
        [[self standardWindowButton:NSWindowCloseButton] setAlphaValue:1];
        [[self standardWindowButton:NSWindowZoomButton] setAlphaValue:1];
        [[self standardWindowButton:NSWindowMiniaturizeButton] setAlphaValue:1];
        
        [_fullContentView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [_fullContentView setFrame:_originalThemeFrame.frame];
    }
    
    return self;
}

- (void)awakeFromNib
{
//    [[self standardWindowButton:NSWindowFullScreenButton] setAlphaValue:_titleBarFadeOutAlphaValue];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowClosed:)
                                                 name: NSWindowWillCloseNotification
                                               object:nil];
}



- (void)windowClosed:(NSNotification *)sender {
    //            let window:FOTWindow = sender.object as! FOTWindow
    //
    //            if(self.dockMenu.index(of: window.menuItem) >= 0) {
    //                self.dockMenu.removeItem(window.menuItem)
    //            }
    
    //    [_titleBar.animator setAlphaValue:1];
}

- (void)becomeKeyWindow
{
    [super becomeKeyWindow];
    [_fullContentView.titleBar setNeedsDisplay:YES];
}

- (void)resignKeyWindow
{
    [super resignKeyWindow];
    [_fullContentView.titleBar setNeedsDisplay:YES];
}

- (void)becomeMainWindow
{
    [super becomeMainWindow];
    [_fullContentView.titleBar setNeedsDisplay:YES];
}

- (void)resignMainWindow
{
    [super resignMainWindow];
    [_fullContentView.titleBar setNeedsDisplay:YES];
}

- (void)setTitle:(NSString *)aString
{
    [super setTitle:aString];
    
    [self.fullContentView setNeedsDisplay:YES];
    [_fullContentView.titleBar setNeedsDisplay:YES];
}

- (void)setRepresentedURL:(NSURL *)url
{
    [super setRepresentedURL:url];
    
    //Match the document icon button to the alpha value of the close button (and the other buttons, essentially)
    [[self standardWindowButton:NSWindowDocumentIconButton] setAlphaValue:[self standardWindowButton:NSWindowCloseButton].alphaValue];
    
    [_fullContentView.titleBar setNeedsDisplay:YES];
}

- (void)addSubviewBelowTitleBar:(NSView *)subview
{
    [_fullContentView addSubview:subview positioned:NSWindowBelow relativeTo:_fullContentView.titleBar];
}

@end