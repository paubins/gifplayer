//
//  MetalView.swift
//  MetalCamera
//
//  Created by Greg on 24/07/2019.
//  Copyright © 2019 GS. All rights reserved.
//

import CoreVideo
import MetalKit
import MetalPerformanceShaders
import simd

var FIRST_FRAME = 0

enum DataType {
    case file(URL)
    case buffer(CVPixelBuffer?, Bool)
    case yuvBuffer(CVPixelBuffer?, Bool)
    case image(CGImage)
    case imageWithAlpha(NSImage)
    case imageFile(URL)
}

extension CGPoint {
    func rotate(around center: CGPoint, angle: CGFloat) -> CGPoint {
        let translate = CGAffineTransform(translationX: -center.x, y: -center.y)
        let transform = translate.concatenating(CGAffineTransform(rotationAngle: angle))
        let rotated = applying(transform)
        return rotated.applying(CGAffineTransform(translationX: center.x, y: center.y))
    }
}

struct MetalObject {
    var coords:[CGPoint]
    var coordsTransformed:[CGPoint]? = nil
    var buffer:MTLBuffer? = nil
    var pixelBuffer:CVPixelBuffer? = nil
    var imageTexture:MTLTexture? = nil
    var alphaTexture:MTLTexture? = nil
    var capturedImageTextureY: CVMetalTexture?
    var capturedImageTextureCbCr: CVMetalTexture?
    var shouldRotate:Bool = false
}

final class MetalView: MTKView {
    
    var standardPipeline: MTLRenderPipelineState!
    var alphaPipeline: MTLRenderPipelineState!
    var yuvPipeline: MTLRenderPipelineState!
    
    lazy var scaleFilter:MPSImageLanczosScale = {
        #if os(macOS)
        let destRegion = NSScreen.main!.frame
        let sourceRegion = NSScreen.main!.frame
        #else
        let destRegion = UIScreen.main.bounds
        let sourceRegion = UIScreen.main.nativeBounds
        #endif

        
        let scaleX = Double(destRegion.size.width) / Double(sourceRegion.size.width)
        let scaleY = Double(destRegion.size.height) / Double(sourceRegion.size.height)
        let translateX = Double(-sourceRegion.origin.x) * scaleX
        let translateY = Double(-sourceRegion.origin.y) * scaleY
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to initialize GPU device")
        }
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to initialize GPU device")
        }
        let filter = MPSImageLanczosScale(device: metalDevice)
        var scaleTransform = MPSScaleTransform(scaleX: scaleX, scaleY: scaleY, translateX: translateX, translateY: translateY)
        
        withUnsafePointer(to: &scaleTransform) { (transformPtr: UnsafePointer<MPSScaleTransform>) -> () in
            filter.scaleTransform = transformPtr
            
        }
        return filter
    }()
    
    lazy var videoScaleFilter:MPSImageLanczosScale = {
        #if os(macOS)
        let sourceRegion = NSScreen.main!.frame
        let destRegion = NSScreen.main!.frame
        #else
        let sourceRegion = UIScreen.main.nativeBounds
        let destRegion = UIScreen.main.bounds
        #endif
        
        let scaleX = Double(0.75) //Double(1280) / Double(sourceRegion.size.width)
        let scaleY = Double(1) //Double(sourceRegion.size.height) / Double(720)
        let translateX = Double(-sourceRegion.origin.x) * scaleX
        let translateY = Double(-sourceRegion.origin.y) * scaleY
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to initialize GPU device")
        }
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to initialize GPU device")
        }
        let filter = MPSImageLanczosScale(device: metalDevice)
        var scaleTransform = MPSScaleTransform(scaleX: scaleX, scaleY: scaleY, translateX: translateX, translateY: translateY)
        
        withUnsafePointer(to: &scaleTransform) { (transformPtr: UnsafePointer<MPSScaleTransform>) -> () in
            filter.scaleTransform = transformPtr
            
        }
        
        
        return filter
    }()
    
    lazy var transposePass:MPSImageTranspose? = {
        if let device = device {
            return  MPSImageTranspose(device: device)
        }
        return nil
    }()
    
    lazy var recordingTexture: MTLTexture? = {
        guard let texture = self.createTexture() else { return nil }
        return texture
    }()
    
    lazy var rotatedTexture: MTLTexture? = {
        guard let texture = self.createTexture() else { return nil }
        return texture
    }()
    
    lazy var rotatedTexture1: MTLTexture? = {
        guard let texture = self.createTexture() else { return nil }
        return texture
    }()

    private var textureCache: CVMetalTextureCache?
    private var commandQueue: MTLCommandQueue?
    private var bufferCoords:[MetalObject] = []
    
    private var numVertices: Int = 0
    private var viewportSize: vector_uint2?

    var recordingCallback: ((MTLTexture) -> Void)?
    
    private func createTexture() -> MTLTexture? {
        #if os(macOS)
        let width = Int(NSScreen.main!.frame.size.width)
        let height =  Int(NSScreen.main!.frame.size.height)
        #else
        let width = Int(UIScreen.main.bounds.size.width)
        let height =  Int(UIScreen.main.bounds.size.height)
        #endif

        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
          pixelFormat: MTLPixelFormat.bgra8Unorm,
          width: width,
          height: height,
          mipmapped: false)
        
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        guard let texture: MTLTexture = device?.makeTexture(descriptor: textureDescriptor) else
        {
          fatalError("create texture FAILED.")
          return nil
        }
        
        let region = MTLRegion.init(origin: MTLOrigin.init(x: 0, y: 0, z: 0),
                                    size: MTLSize.init(width: texture.width,
                                                       height: texture.height, depth: 1));
        
        //MARK: >>> JUST FOR TEST
        let count = width * height * 4
        let stride = MemoryLayout<CChar>.stride
        let alignment = MemoryLayout<CChar>.alignment
        let byteCount = stride * count
        
        let p = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: alignment)
        let data = p.initializeMemory(as: CChar.self, repeating: 0, count: count)
        //MARK: <<<
          
        texture.replace(region: region, mipmapLevel: 0, withBytes: data, bytesPerRow: width * 4)
        
        return texture
      }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to initialize GPU device")
        }

        commandQueue = metalDevice.makeCommandQueue()

        var textCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &textCache)
            != kCVReturnSuccess
        {
            fatalError("Unable to allocate texture cache.")
        } else {
            textureCache = textCache
        }

        self.device = metalDevice
        self.framebufferOnly = false
        self.preferredFramesPerSecond = 60
        self.clearColor = MTLClearColor(red: 0, green: 0.5, blue: 1.0, alpha: 1.0)
        self.depthStencilPixelFormat = .depth32Float
        self.colorPixelFormat = .bgra8Unorm
        self.autoResizeDrawable = true
        self.prepareFunctions()
    }

    override func draw(_ rect: CGRect) {
        autoreleasepool {
            if !rect.isEmpty {
                self.render()
            }
        }
    }

    fileprivate func createPipeline(_ metalDevice: MTLDevice, alpha: Bool = false) throws
        -> MTLRenderPipelineState
    {
        // step 4-5: create a vertex shader & fragment shader
        // A vertex shader is simply a tiny program that runs on the GPU, written in a C++-like language called the Metal Shading Language.

        let library = metalDevice.makeDefaultLibrary()
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library!.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library!.makeFunction(name: "samplingShader")
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat

        if alpha {
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
            pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .destinationAlpha
            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .destinationAlpha
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusBlendAlpha
        }

        return try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    
    fileprivate func createPipelineForYUV(_ metalDevice: MTLDevice, alpha: Bool = false) throws
        -> MTLRenderPipelineState
    {
        // step 4-5: create a vertex shader & fragment shader
        // A vertex shader is simply a tiny program that runs on the GPU, written in a C++-like language called the Metal Shading Language.

        let library = metalDevice.makeDefaultLibrary()
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library!.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library!.makeFunction(name: "capturedImageFragmentShader")
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat

        if alpha {
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
            pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .destinationAlpha
            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .destinationAlpha
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusBlendAlpha
        }

        return try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }


    fileprivate func createPipelineWithAlpha(_ metalDevice: MTLDevice) throws
        -> MTLRenderPipelineState
    {
        return try self.createPipeline(metalDevice, alpha: true)
    }

    func prepareFunctions() {
        guard let metalDevice = self.device else { fatalError("Expected a Metal device.") }
        do {
            standardPipeline = try createPipeline(metalDevice)
            alphaPipeline = try createPipelineWithAlpha(metalDevice)
            yuvPipeline = try createPipelineForYUV(metalDevice)

            viewportSize = vector_uint2(x: UInt32(self.bounds.size.width), y: UInt32(self.bounds.size.height))
        } catch {
            print("Unexpected error: \(error).")
        }
    }
    
    func convertToMetalCoordinates(point: CGPoint, viewSize: CGSize) -> simd_float2 {
        let inverseViewSize = CGSize(width: 1.0 / viewSize.width, height: 1.0 / viewSize.height)
        let clipX = Float((2.0 * point.x * inverseViewSize.width) - 1.0)
        let clipY = Float((2.0 * -point.y * inverseViewSize.height) + 1.0)
        return simd_float2(clipX, clipY)
    }
    
    fileprivate func createQuad(
        br: CGPoint, bl: CGPoint, tl: CGPoint,
        br2: CGPoint, tl2: CGPoint, tr: CGPoint,
        viewportSize: CGSize
    )
        -> [AAPLVertex]
    {
        func get_simd(c: (Float, Float)) -> simd_float2 {
            return simd_make_float2(c.0, c.1)
        }

        return [
            // triangle one
            AAPLVertex(
                position: convertToMetalCoordinates(point: br, viewSize: viewportSize),
                textureCoordinate: simd_make_float2(1.0, 1.0)),
            AAPLVertex(
                position: convertToMetalCoordinates(point: bl, viewSize: viewportSize),
                textureCoordinate: simd_make_float2(0.0, 1.0)),
            AAPLVertex(
                position: convertToMetalCoordinates(point: tl, viewSize: viewportSize),
                textureCoordinate: simd_make_float2(0.0, 0.0)),
            // triangle two
            AAPLVertex(
                position: convertToMetalCoordinates(point: br2, viewSize: viewportSize),
                textureCoordinate: simd_make_float2(1.0, 1.0)),
            AAPLVertex(
                position: convertToMetalCoordinates(point: tl2, viewSize: viewportSize),
                textureCoordinate: simd_make_float2(0.0, 0.0)),
            AAPLVertex(
                position: convertToMetalCoordinates(point: tr, viewSize: viewportSize),
                textureCoordinate: simd_make_float2(1.0, 0.0)),

        ]

    }

    private func render() {
        guard let drawable: CAMetalDrawable = self.currentDrawable else {
            fatalError("Failed to create drawable")
        }
        guard let commandBuffer = commandQueue!.makeCommandBuffer() else { return }
        
        for buffer in self.bufferCoords {
            if let pixelBuffer = buffer.pixelBuffer, let buffer2 = buffer.buffer {
                self.encodeTexture(
                    buffer: buffer2,
                    pixelBuffer: pixelBuffer,
                    pipeline: self.standardPipeline,
                    commandBuffer: commandBuffer, useLoad: true)
            } else if let texture = buffer.imageTexture, let buffer = buffer.buffer {
                self.encodeTexture(
                    buffer: buffer,
                    texture: texture,
                    pipeline: self.standardPipeline,
                    commandBuffer: commandBuffer, useLoad: true)
            } else if let alphaTexture = buffer.alphaTexture, let buffer = buffer.buffer {
                self.encodeTexture(
                    buffer: buffer,
                    texture: alphaTexture,
                    pipeline: self.alphaPipeline,
                    commandBuffer: commandBuffer, useLoad: true)
            } else if let capturedY = buffer.capturedImageTextureY, let capturedYU = buffer.capturedImageTextureCbCr, let buffer = buffer.buffer {
                self.encodeTexture(
                    buffer: buffer,
                    texture: CVMetalTextureGetTexture(capturedY)!,
                    texture2: CVMetalTextureGetTexture(capturedYU)!,
                    pipeline: self.yuvPipeline,
                    commandBuffer: commandBuffer, useLoad: true)
            }
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func encodeTexture(
        buffer: MTLBuffer, pixelBuffer: CVImageBuffer? = nil, pipeline: MTLRenderPipelineState,
        commandBuffer: MTLCommandBuffer, useLoad: Bool = false
    ) {
        guard let pixelBuffer = pixelBuffer else {
            return
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault, textureCache!, pixelBuffer, nil, .bgra8Unorm, width, height, 0,
            &cvTextureOut)
        guard let cvTexture = cvTextureOut, let inputTexture = CVMetalTextureGetTexture(cvTexture)
        else {
            fatalError("Failed to create metal textures")
        }
        
        self.encodeTexture(buffer: buffer,
                           texture: inputTexture,
                           pipeline: pipeline,
                           commandBuffer: commandBuffer,
                           useLoad: useLoad)
    }

    private func encodeTexture(
        buffer: MTLBuffer, texture:MTLTexture, texture2:MTLTexture? = nil, pipeline: MTLRenderPipelineState,
        commandBuffer: MTLCommandBuffer, useLoad:Bool = true
    ) {
        
        guard let passDescriptor = self.currentRenderPassDescriptor else { return }
        if useLoad {
            passDescriptor.colorAttachments[0].loadAction = .clear
        } else {
//            passDescriptor.colorAttachments[0].texture = texture
            passDescriptor.colorAttachments[0].loadAction = .clear
        }
        passDescriptor.colorAttachments[0].storeAction = .store
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.1, 0.1, 0.1, 1)

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else {
            return
        }
        #if os(macOS)
        encoder.setViewport(
            MTLViewport(
                originX: 0, originY: 0,
                width: self.frame.width * NSScreen.main!.backingScaleFactor,
                height: self.frame.height * NSScreen.main!.backingScaleFactor,
                znear: -1.0, zfar: 1.0))
        #else
        encoder.setViewport(
            MTLViewport(
                originX: 0, originY: 0,
                width: UIScreen.main.nativeBounds.width,
                height: UIScreen.main.nativeBounds.height,
                znear: -1.0, zfar: 1.0))
        #endif


        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        if let texture2 = texture2 {
            encoder.setFragmentTexture(texture, index: 1)
        }
        encoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.size, index: 1)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVertices)
        encoder.endEncoding()
    }
    
    func replace(with mediaType: DataType) {
        switch mediaType {
        case .file(let _):
            print("oo")
        case .buffer(let buffer, let rotate):
            self.bufferCoords = self.bufferCoords.map({ metalObject in
                var metalObject = metalObject
                metalObject.imageTexture = nil
                metalObject.pixelBuffer = buffer
                metalObject.shouldRotate = rotate
                return metalObject
            })
            setNeedsDisplay(self.frame)
        case .yuvBuffer(let buffer, let rotate):
            self.bufferCoords = self.bufferCoords.map({ metalObject in
                var metalObject = metalObject
                metalObject.imageTexture = nil
                metalObject.pixelBuffer = nil
                metalObject.shouldRotate = rotate
                if let buffer = buffer {
                    let textures = updateCapturedImageTextures(pixelBuffer: buffer)
                    metalObject.capturedImageTextureY = textures.0
                    metalObject.capturedImageTextureCbCr = textures.1
                }
                return metalObject
            })
            setNeedsDisplay(self.frame)
        case .image(let image):
            self.bufferCoords = self.bufferCoords.map({ metalObject in
                var metalObject = metalObject
                metalObject.imageTexture = try! MTKTextureLoader(device: self.device!)
                    .newTexture(cgImage: image, options: nil)
                metalObject.pixelBuffer = nil
                metalObject.shouldRotate = false
                return metalObject
            })
            setNeedsDisplay(self.frame)
//        case .imageWithAlpha(let image):
//            self.bufferCoords = self.bufferCoords.map({ metalObject in
//                var metalObject = metalObject
//                metalObject.alphaTexture = try! MTKTextureLoader(device: self.device!)
//                    .newTexture(cgImage: image.cgImage!, options: nil)
//                metalObject.imageTexture = nil
//                metalObject.pixelBuffer = nil
//                return metalObject
//            })
//            setNeedsDisplay(self.frame)
//        case .imageFile(let _):
//            break
//        
        default:
            break
        }
    }
    
    func create(coords:[CGPoint]) {
        var bufferCoord = MetalObject(coords: coords)
        
        guard let metalDevice = self.device else { fatalError("Expected a Metal device.") }
        do {
            var dataSize = 0
            let buffer = bufferCoord.coords
            let vertexData:[AAPLVertex] = createQuad(br: buffer[0], //CGPoint(x: width - 80, y: height - 450),
                                                     bl: buffer[1], //CGPoint(x: width - 300, y: height - 450),
                                                     tl: buffer[2], //CGPoint(x: width - 300, y: height - 100*4 - 450),
                                                     br2: buffer[3], //CGPoint(x: width - 80, y: height - 450),
                                                     tl2: buffer[4], //CGPoint(x: width - 300, y: height - 100*4 - 450),
                                                     tr: buffer[5], //CGPoint(x: width - 80, y: height - 100*4 - 450),
                                                     viewportSize:  NSSize(width: self.frame.size.width * NSScreen.main!.backingScaleFactor,
                                                                           height: self.frame.size.height * NSScreen.main!.backingScaleFactor
                                                                          ))
            if dataSize == 0 {
                dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
            }
            
            // fixed error here with nil not being an acceptable parameter for 'options'
            // http://stackoverflow.com/questions/29584463/ios-8-3-metal-found-nil-while-unwrapping-an-optional-value
            if let buffer = metalDevice.makeBuffer(
                bytes: vertexData,
                length: dataSize,
                options: .storageModeShared) {
                bufferCoord.buffer = buffer
            }
            
            numVertices = dataSize / MemoryLayout<AAPLVertex>.size
            
            self.bufferCoords += [bufferCoord]
        }
    }
    
    func updateCapturedImageTextures(pixelBuffer: CVPixelBuffer) -> (CVMetalTexture?, CVMetalTexture?) {
        // Create two textures (Y and CbCr) from the provided frame's captured image.
        if (CVPixelBufferGetPlaneCount(pixelBuffer) < 2) {
            return (nil, nil)
        }
        
        return (createYUVTexture(fromPixelBuffer: pixelBuffer, pixelFormat:.r8Unorm, planeIndex:0)!,
            createYUVTexture(fromPixelBuffer: pixelBuffer, pixelFormat:.rg8Unorm, planeIndex:1)!)
    }

    func createYUVTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache!, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
        
        if status != kCVReturnSuccess {
            texture = nil
        }
        
        return texture
    }
   
    override var mouseDownCanMoveWindow:Bool {
        return true
    }
    
}
