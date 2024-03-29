// Copyright (c) 2014 The WebM project authors. All Rights Reserved.
//
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file in the root of the source
// tree. An additional intellectual property rights grant can be found
// in the file PATENTS.  All contributing project authors may
// be found in the AUTHORS file in the root of the source tree.
#ifndef VPX_IOS_VPXEXAMPLE_VPX_PLAYER_H_
#define VPX_IOS_VPXEXAMPLE_VPX_PLAYER_H_

#if defined __cplusplus

#include <CoreVideo/CoreVideo.h>

#include <memory>
#include <string>

#import "./GlkVideoViewController.h"
#include "./video_buffer_pool.h"
#include "./vpx_example_common.h"
#include "./vpx_frame_parser.h"

#import "GlkVideoViewController.h"

struct vpx_codec_ctx;
struct vpx_image;

namespace VpxExample {

class VpxPlayer {
 public:
  VpxPlayer();
  ~VpxPlayer();

  void Init(GlkVideoViewController *target_view);
  bool LoadFile(const char *file_path);
  bool Play();
  void ReleaseVideoBuffer(const VideoBufferPool::VideoBuffer *buffer);

  NSString *playback_result() const { return playback_result_; }

  VpxFormat vpx_format() const { return format_; }

 private:
  bool InitParser();
  bool InitBufferPool();
  bool InitVpxDecoder();
  bool DeliverVideoBuffer(const vpx_image *image,
                          const VideoBufferPool::VideoBuffer *buffer,
                          int64_t timestamp);
  bool DecodeAllVideoFrames();

  GlkVideoViewController *target_view_;
  NSString *playback_result_;
  std::unique_ptr<VpxFrameParserInterface> parser_;
  std::string file_path_;
  uint32_t frames_decoded_;
  VpxFormat format_;
  vpx_codec_ctx *vpx_codec_ctx_;
  VideoBufferPool buffer_pool_;
  NSLock *buffer_lock_;
};

}  // namespace VpxExample

#endif  // VPX_IOS_VPXEXAMPLE_VPX_PLAYER_H_


#endif
