//
//  OpenGLView.swift
//  basic-opengl-swift
//
//  Created by Steven Watson on 9/17/16.
//  Copyright © 2016 Steven Watson. All rights reserved.
//

import GLKit
import OpenGL
import GLUT

var GL_ALPHA_OPAQUE = 1.0
var NS_ALPHA_OPAQUE = 1.0
var FIRST_FRAME = 0

class OpenGLView: NSOpenGLView
{
    var displayLink: CVDisplayLink? = nil;
    
    let backgrRed:CGFloat = NSColor.green.redComponent
    let backgrGreen:CGFloat = NSColor.green.greenComponent
    let backgrBlue:CGFloat = NSColor.green.blueComponent
    
    var gifRep:NSBitmapImageRep!
    var maxFrameCount:Int = 29
    
    var currFrameCount:Int = 0
    
    var screenRect:NSRect! {
        return (self.window?.frame)!
    }
    
    var animationImages:[Data] = []
    var frameStore:FrameStore!
    
    var image:NSImage! = nil
    
    var timer:Timer! = nil
    var animates:Bool = false
    var imageScaling:NSImageScaling = .scaleNone
    var isPaused:Bool = false

    override open func prepareOpenGL()
    {
        if (self.animationImages.count == 0) {
            return
        }
        
//        self.screenRect = (self.window?.frame)!
        
        let attributes:[NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFADoubleBuffer),
            UInt32(NSOpenGLPFANoRecovery),
            UInt32(NSOpenGLPFAColorSize),
            UInt32(NSOpenGLPFADepthSize),
            
            UInt32(NSOpenGLPFAAccelerated)]
        
        self.pixelFormat = NSOpenGLPixelFormat(attributes: attributes)
        
        /* Set up DisplayLink. */
        func displayLinkOutputCallback( displayLink: CVDisplayLink,
                                            _ inNow: UnsafePointer<CVTimeStamp>,
                                     _ inOutputTime: UnsafePointer<CVTimeStamp>,
                                          _ flagsIn: CVOptionFlags,
                                         _ flagsOut: UnsafeMutablePointer<CVOptionFlags>,
                               _ displayLinkContext: UnsafeMutableRawPointer? )
        -> CVReturn
        {
            /* Get an unsafe instance of self from displayLinkContext. */
            let unsafeSelf = Unmanaged<OpenGLView>.fromOpaque( displayLinkContext! ).takeUnretainedValue()
            
            unsafeSelf.draw(unsafeSelf.frame)
            return kCVReturnSuccess
        }
        
//        var swapInterval:GLint = 1
//        self.openGLContext?.setValues(&swapInterval, for: NSOpenGLCPSwapInterval)
        
        if (gifRep.hasAlpha) {
            var aValue:GLint = 0;
            self.openGLContext?.setValues(&aValue, for: NSOpenGLContext.Parameter.surfaceOpacity)
        }

        CVDisplayLinkCreateWithActiveCGDisplays( &displayLink )
        CVDisplayLinkSetOutputCallback( displayLink!, displayLinkOutputCallback, Unmanaged.passUnretained(self).toOpaque() )
//        CVDisplayLinkStart( displayLink! )
        
        /* BUG: When exiting a fullscreen view windowClosing() will be called. */
        NotificationCenter.default.addObserver( self, selector: #selector( OpenGLView.windowClosing ),
                                                name: NSWindow.willCloseNotification,
                                                        object: self.window )
    }
    
    
    func pictureRatioFromWidth(iWidth:Float, iHeight:Float) -> Float {
        return iWidth/iHeight
    }
    
    func calcHeightFromRatio(iWidth:Float, iRatio:Float) -> Float {
        return iWidth/iRatio
    }
    
    func calcWidthFromRatio(iHeight:Float, iRatio:Float) -> Float {
        return iRatio*iHeight
    }
    
    override func draw(_ dirtyRect: NSRect)
    {
        if (self.animationImages.count == 0) {
            return
        }
        
        var target:NSRect = self.screenRect
    
        target.size.height = screenRect.size.height;
        target.size.width = screenRect.size.width;
        target.origin.y = 0; //(screenRect.size.height - image.size.height)/2;
        target.origin.x = 0; //(screenRect.size.width - image.size.width)/2;
        
        glViewport(0,0,
                   GLsizei(target.size.width),
                   GLsizei(target.size.height));
        
        self.openGLContext!.makeCurrentContext()
        
        // Start phase
        glPushMatrix()
        
        // defines the pixel resolution of the screen (can be smaller than real screen, but than you will see pixels)
        glOrtho(0, GLdouble(screenRect.size.width), GLdouble(screenRect.size.height), 0, -1, 1)
        
        glEnable(GLenum(GL_TEXTURE_2D))

        //get one free texture name
        var frameTextureName: GLuint = 0
        
        glGenTextures(1, &frameTextureName)
        
        //bind a Texture object to the name
        glBindTexture(GLenum(GL_TEXTURE_2D), frameTextureName)
        
        // load current bitmap as texture into the GPU
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLfloat(GLenum(GL_LINEAR_MIPMAP_LINEAR)))
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLfloat(GLenum(GL_LINEAR)))
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GLenum(GL_CLAMP_TO_EDGE)))
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GLenum(GL_CLAMP_TO_EDGE)))
        glTexEnvi(GLenum(GL_TEXTURE_ENV), GLenum(GL_TEXTURE_ENV_MODE), GL_REPLACE);
        
        // we load bitmap data from memory and save CPU time (created during startAnimation)
        let pixels:NSData = animationImages[currFrameCount] as NSData //.uncompressed(using: .lz4)! as NSData
        
        glTexImage2D(GLenum(GL_TEXTURE_2D),
                     0,
                     GL_RGBA,
                     GLsizei(gifRep.pixelsWide),
            GLsizei(gifRep.pixelsHigh),
            0,
            GLenum(GL_RGBA),
            GLenum(GL_UNSIGNED_BYTE),
            pixels.bytes
        );

        
        glGenerateMipmap(GLenum(GL_TEXTURE_2D))
        
        // define the target position of texture (related to screen defined by glOrtho) witch makes the texture visible
        let x:CGFloat = target.origin.x;
        let y:CGFloat = target.origin.y;
        
        let iheight:CGFloat = target.size.height;
        let iwidth:CGFloat = target.size.width;
        
        glBegin( GLenum(GL_QUADS) );
        glTexCoord2f( 0.0, 0.0 ); glVertex2f(GLfloat(x), GLfloat(y)); //Bottom left
        glTexCoord2f( 1.0, 0.0 ); glVertex2f(GLfloat(x + iwidth), GLfloat(y)); //Bottom right
        glTexCoord2f( 1.0, 1.0 ); glVertex2f(GLfloat(x + iwidth), GLfloat(y + iheight)); //Top right
        glTexCoord2f( 0.0, 1.0 ); glVertex2f(GLfloat(x), GLfloat(y + iheight)); //Top left
        glEnd();
        
        glDisable(GLenum(GL_BLEND));
        glDisable(GLenum(GL_TEXTURE_2D));
        

        //End phase
        glPopMatrix();
        
        //free texture object by name
        glDeleteTextures(1, &frameTextureName);
        
        glFlush()
        
        CGLFlushDrawable( self.openGLContext!.cglContextObj! )
        CGLUnlockContext( self.openGLContext!.cglContextObj! )
        
        if (currFrameCount < maxFrameCount-1) {
            if (!self.inLiveResize && !self.isPaused) {
                currFrameCount += 1
            }
        }
        else {
            currFrameCount = FIRST_FRAME;
        }
    }
    
    
    @objc func windowClosing()
    {
        CVDisplayLinkStop( displayLink! );
    }
    
    func loadGIF(gifFileName:URL) -> Bool {
        return self.loadGIF(data: try! Data(contentsOf: gifFileName))
    }
    
    
    func loadGIF(data: Data) -> Bool {
        self.image = NSImage(data: data as Data)
        
        self.gifRep = (image.representations[FIRST_FRAME] as! NSBitmapImageRep)
        let frameCount = gifRep.value(forProperty: NSBitmapImageRep.PropertyKey.frameCount) == nil ? 1 : gifRep.value(forProperty: NSBitmapImageRep.PropertyKey.frameCount)
        if let maxFrameCount = frameCount {
            self.maxFrameCount = maxFrameCount as! Int
            self.currFrameCount = FIRST_FRAME
            
            for frame in 0 ..< self.maxFrameCount {
                gifRep.setProperty(NSBitmapImageRep.PropertyKey.currentFrame, withValue: frame)
                
                let data = gifRep.bitmapData
                let size = gifRep.bytesPerPlane
                // copy the bitmap data into an NSData object, that can be save transferred to animateOneFrame
                let imgData:Data = NSData(bytes: data, length: size) as Data
                animationImages.append(imgData)//.compressed(using: Compression.lz4)!)
            }
            
            let source:CGImageSource = CGImageSourceCreateWithData(data as CFData, nil)!
            let duration:Double = max(CGImageFrameDuration(with: source, atIndex: 0),
                                      CGImageFrameDuration(with: source, atIndex: 1))
            
            self.timer = Timer(timeInterval: TimeInterval(duration), target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
            self.timer.fire()
            
//            self.screenRect = (self.window?.frame)!
            
            RunLoop.main.add(self.timer, forMode: RunLoopMode.defaultRunLoopMode)
            return true
        }
        
        return false
    }
    
    @objc func timerFired() {
        self.setNeedsDisplay(self.frame)
    }
    
    
    override var mouseDownCanMoveWindow:Bool {
        return true
    }
    
    func rewind() {
        if (0 < currFrameCount) {
            currFrameCount -= 1
        }
        else {
            currFrameCount = FIRST_FRAME;
        }
    }
    
    func forward() {
        if (currFrameCount < maxFrameCount-1) {
            currFrameCount += 1
        }
        else {
            currFrameCount = FIRST_FRAME;
        }
    }
    
    func speedUp() {
        self.timer.invalidate()
        self.timer = Timer(timeInterval: TimeInterval(self.timer.timeInterval*0.7), target: self,
                           selector: #selector(timerFired), userInfo: nil, repeats: true)
        self.timer.fire()
        RunLoop.main.add(self.timer, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    func slowDown() {
        self.timer.invalidate()
        self.timer = Timer(timeInterval: TimeInterval(self.timer.timeInterval*1.2), target: self,
                           selector: #selector(timerFired), userInfo: nil, repeats: true)
        self.timer.fire()
        RunLoop.main.add(self.timer, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    func currentDelay() -> TimeInterval {
        return self.timer!.timeInterval
    }
}
