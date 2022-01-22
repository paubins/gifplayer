// Copyright (c) 2014 The WebM project authors. All Rights Reserved.
//
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file in the root of the source
// tree. An additional intellectual property rights grant can be found
// in the file PATENTS.  All contributing project authors may
// be found in the AUTHORS file in the root of the source tree.
#import "GlkVideoViewController.h"

#include <cassert>
#include <cmath>
#include <queue>

#import <dispatch/dispatch.h>

#import "./vpx_player.h"

namespace {

typedef void(^MyCompletionBlock)(CVPixelBufferRef);

const NSInteger kRendererFramesPerSecond = 60;

// Uniform index.
enum {
  UNIFORM_Y,
  UNIFORM_UV,
  NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
  ATTRIB_VERTEX,
  ATTRIB_TEXCOORD,
  NUM_ATTRIBUTES
};
}  // namespace

struct ViewRectangle {
  ViewRectangle() : view_x(0), view_y(0), view_width(0), view_height(0) {}
  // Origin coordinates.
  float view_x;
  float view_y;

  // View extents from origin coordinates.
  float view_width;
  float view_height;
};

struct VideoFrame {
  VideoFrame() : buffer(NULL), timestamp_ms(0) {}
  VideoFrame(const VpxExample::VideoBufferPool::VideoBuffer *buffer_ptr,
             int64_t timestamp) : buffer(buffer_ptr), timestamp_ms(timestamp) {}
  const VpxExample::VideoBufferPool::VideoBuffer *buffer;

  // Timestamp of |buffer| data in milliseconds.
  int64_t timestamp_ms;
};

// Returns the time since system start up, in milliseconds.
NSTimeInterval SystemUptimeMilliseconds() {
  return [[NSProcessInfo processInfo] systemUptime] *
      VpxExample::kMillisecondsPerSecond;
}

bool IsTimeToShowFrame(int64_t timestamp, NSTimeInterval start_time) {
  return (SystemUptimeMilliseconds() - start_time) >= timestamp;
}

@interface GlkVideoViewController() {
  dispatch_queue_t _playerQueue;
  CVPixelBufferRef *_pixelBuffer;
  NSLock *_lock;
  NSInteger _count;
  std::queue<VideoFrame> _videoFrames;
  VpxExample::VpxPlayer _vpxPlayer;

  CGFloat _screenWidth;
  CGFloat _screenHeight;
  size_t _textureWidth;
  size_t _textureHeight;
  ViewRectangle _viewRectangle;

  GLuint _program;

  NSTimeInterval _videoStartTime;
    
  MyCompletionBlock _completion;
}

@property NSTimeInterval videoStartTime;
@property VpxExample::VpxFormat vpxFormat;

@end  // @interface GlkVideoViewController

@implementation GlkVideoViewController
@synthesize fileToPlay = _fileToPlay;
@synthesize vpxtestViewController = _vpxtestViewController;
@synthesize vpxFormat = _vpxFormat;
@synthesize videoStartTime = _videoStartTime;


- (void)loadFile:(MyCompletionBlock)completion {
    _count = 0;

    _lock = [[NSLock alloc] init];
    _playerQueue = dispatch_queue_create("com.google.VPXTest.playerqueue", NULL);
    _vpxPlayer.Init(self);
    
    _completion = completion;

    if (!_vpxPlayer.LoadFile([_fileToPlay UTF8String])) {
      NSLog(@"File load failed for %@", _fileToPlay);
      return;
    }

    _vpxFormat = _vpxPlayer.vpx_format();
}

- (NSInteger)rendererFrameRate {
  return kRendererFramesPerSecond;
}

// Receives buffers from player and stores them in |_videoBuffers|.
- (void)receiveVideoBuffer:(const void*)videoBuffer
withTimestampInMilliseconds:(int64_t)timestamp {
    
  [_lock lock];
  typedef VpxExample::VideoBufferPool::VideoBuffer VideoBuffer;
  const VideoBuffer *video_buffer =
      reinterpret_cast<const VideoBuffer *>(videoBuffer);
  VideoFrame frame(video_buffer, timestamp);
    _completion(frame.buffer->buffer);
  _videoFrames.push(frame);
  NSLog(@"pushed buffer.");
  [_lock unlock];
}

- (CVPixelBufferRef)getNextBuffer {
    // Check for a frame in the queue.
    VideoFrame frame;

    if ([_lock tryLock] == YES) {
      if (_videoFrames.empty()) {
        NSLog(@"buffer queue empty.");
      } else {
        if (IsTimeToShowFrame(_videoFrames.front().timestamp_ms,
                              self.videoStartTime)) {
          frame = _videoFrames.front();
          _videoFrames.pop();
          NSLog(@"popped buffer with timestamp (in seconds) %.3f.",
                frame.timestamp_ms / 1000.0);
        }
      }
      [_lock unlock];
    }

    return frame.buffer->buffer;
}

- (void)playFile {
  self.videoStartTime = SystemUptimeMilliseconds();

  if (!_vpxPlayer.Play()) {
    NSLog(@"VpxPlayer::Play failed.");
//    [self playbackFailed:@"Unexpected failure during play start in VpxPlayer."];
    return;
  }
//
//  // Wait for all frames to be consumed.
//  [_lock lock];
//  bool empty = _videoFrames.empty();
//  [_lock unlock];
//
//  while (!empty) {
//    [NSThread sleepForTimeInterval:.1];  // 100 milliseconds.
//    [_lock lock];
//    empty = _videoFrames.empty();
//    [_lock unlock];
//  }
}

@end  // @implementation GlkVideoViewController
