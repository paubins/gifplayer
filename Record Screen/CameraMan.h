//
//  ViewController.h
//  MacRecord
//
//  Created by 钟勇 on 2018/7/13.
//  Copyright © 2018年 钟勇. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, State) {
    StateStart,
    StateRecord,
    StatePause,
    StateResume,
    StateStop,
    StateIdle,
    StateFinish
};

@protocol CameraManDelegate;

@interface CameraMan : NSObject

@property (nonatomic, weak) id<CameraManDelegate> delegate;
@property (nonatomic, strong) NSURL *recordedFile;

- (id)init:(CGRect)rect fileURL:(NSURL *)fileURL;

- (void)resume;
- (void)pause;
- (void)record;
- (void)stop;

@end

@protocol CameraManDelegate <NSObject>
- (void)cameraMan:(CameraMan *)man didChangeState:(State)state;
@end
