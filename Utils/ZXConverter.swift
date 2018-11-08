//
//  ZXConverter.swift
//  GIF
//
//  Created by zhangxi on 7/1/16.
//  Copyright © 2016 zhangxi.me. All rights reserved.
//

import Cocoa
import Foundation
import SwiftyJSON

enum Quality {
    case veryLow
    case low
    case normal
    case high
    case veryHigh
    
    func lossy() -> String{
        switch self {
        case .veryLow:
            return ""
        case .low:
            return "80"
        case .normal:
            return "30"
        case .high:
            return "10"
        case .veryHigh:
            return ""
        }
    }
    
    func needCompress() -> Bool
    {
        return ((self != .veryLow ) && (self != .veryHigh))
    }
    
}

class GIF: NSObject
{
    var range : (ss:String,t:String)? = nil
    var quality : Quality = .normal
    var fps:Int = 12
    
    
    
    var palettePath : String!
    var gifFileName : String!
    var gifPath : String!
    var comporesGifPath : String!
    var fileName : String!
    var path : String!{
        didSet{
            self.fileName         = (path as NSString).lastPathComponent
            self.gifFileName      = String(format: "%@.gif",UUID().uuidString)
            self.gifPath          = String(format: "%@/%@",folderPath,gifFileName)
            self.comporesGifPath  = String(format: "%@/c_%@",folderPath,gifFileName)
            self.palettePath      = String(format: "%@/p_%@",folderPath,gifFileName)
        }
    }
    var thumb : [String]!
    var duration:TimeInterval!
    
    
    var size:CGSize!{
        didSet{
            wantSize = size
        }
    }
    var wantSize:CGSize?
    
    
    override var description: String
        {
        get{
            return "=====================\npath:\(String(describing: path))\nfileName:\(String(describing: fileName))\ngifFileName:\(String(describing: gifFileName))\nduration:\(String(describing: duration))\nvideoSize:\(String(describing: size))\nwantSize:\(String(describing: wantSize))\nframes:\(String(describing: thumb?.count))\n\n====================="
        }
    }
    func  valid() -> (valid:Bool,error:String) {

        if path == nil
        {
            return  (valid:false,error:"Can't get the file.")
        }
        
        if thumb == nil
        {
            return  (valid:false,error:"Can't create thumbnails.")
        }
        if duration == nil
        {
            return  (valid:false,error:"Can't get duration info.")
        }
        if wantSize == nil
        {
            return  (valid:false,error:"Can't get video width.")
        }

        if size == nil
        {
            return  (valid:false,error:"Can't get video height.")
        }
        return (valid:true,error:"Sucess")
    }
    func clean()
    {
        let fm  = FileManager.default
        do{
            try fm.removeItem(atPath: gifPath)
            try fm.removeItem(atPath: comporesGifPath)
            try fm.removeItem(atPath: palettePath)
        }catch{}
    }
}

/*
 http://blog.csdn.net/stone_wzf/article/details/45570021


 
 -i $1 -vf "fps=15,scale=320:-1:flags=lanczos,palettegen=stats_mode=diff" -y $palette2
 -i $1 -i $palette2 -lavfi "fps=15,scale=320:-1:flags=lanczos [x]; [x][1:v] paletteuse" -gifflags +transdiff -y 3$2
 
 //scale=320:-1:flags=lanczos
 
 
 low quality:
 ./ffmpeg -i $1 -lavfi "fps=15" -gifflags +transdiff -y 5$2
 
 */
class ZXConverter: NSObject {
    
    let ffmpeg   = Bundle.main.path(forResource: "ffmpeg", ofType: "")!
    let ffprobe  = Bundle.main.path(forResource: "ffprobe", ofType: "")!
    let gifsicle = Bundle.main.path(forResource: "gifsicle", ofType: "")!
    let fm       = FileManager.default
  
    var convertQueue: DispatchQueue? = DispatchQueue(label: "me.zhnagxi.convert", attributes: [])
    
    override init() {
        super.init()
        //resetQueue()
    }
    var stopTask:Bool = false
    func stop()
    {
        stopTask = true
        //resetQueue()
        
//        for task in tasks
//        {
//            print(task)
//            task.terminate()
//        }
//        tasks.removeAll()
    }
    var tasks = [Process]()
    
    func resetQueue()
    {
        if convertQueue != nil
        {
            convertQueue!.suspend()
            convertQueue = nil
            convertQueue = DispatchQueue(label: "me.zhnagxi.convert", attributes: [])
        }
        
    }
    func convert(_ gif:GIF,complete:@escaping (_ success:Bool,_ path:String?)->Void)
    {
        
        stopTask = false
        
        convertQueue!.async(execute: {[unowned self] () -> Void in
            
            print(gif.description)
            gif.clean()
            
            var result = ""
            let size = gif.wantSize ?? gif.size
            
            if gif.quality == .veryLow
            {
                 var arguments = [String]()
                arguments += ["-i",gif.path,"-lavfi"]
                if size != nil
                {
                    arguments.append(String(format: "fps=%d,scale=%d:%d:flags=lanczos",Int(gif.fps),Int(size!.width),Int(size!.height)))
                }else
                {
                    arguments.append(String(format: "fps=%d",Int(gif.fps)))
                }
                
                if gif.range != nil
                {
                    arguments  = ["-ss",gif.range!.ss] + arguments //+ ["to",gif.range!.to]
                    arguments  = arguments + ["-t",gif.range!.t]
                }else
                {
                }
                
                arguments += ["-gifflags","+transdiff","-y",gif.gifPath]

                //if self.stopTask { return }
                result = result + self.shell(self.ffmpeg,arguments:arguments)
                //if self.stopTask { return }
            }else
            {
                var vf    = ""
                var lavfi = ""
                
                if size != nil
                {
                    vf = String(format: "fps=%d,scale=%d:%d:flags=lanczos,palettegen=stats_mode=diff",Int(gif.fps),Int(size!.width),Int(size!.height))
                    lavfi = String(format: "fps=%d,scale=%d:%d:flags=lanczos  [x]; [x][1:v] paletteuse=dither=floyd_steinberg",Int(gif.fps),Int(size!.width),Int(size!.height))
                }else{
                    vf = String(format: "fps=%d,palettegen=stats_mode=diff",Int(gif.fps))
                    lavfi = String(format: "fps=%d [x]; [x][1:v] paletteuse=dither=floyd_steinberg",Int(gif.fps))
                }

                //if self.stopTask { return }
                if gif.range == nil
                {
                    result = result + self.shell(self.ffmpeg,arguments:["-i",gif.path,"-vf",vf,"-y",gif.palettePath])
                    if self.stopTask { return }
                    result = result + self.shell(self.ffmpeg,arguments:["-i",gif.path,"-i",gif.palettePath,"-lavfi",lavfi,"-gifflags","+transdiff","-y",gif.gifPath])
                }else
                {
                    result = result + self.shell(self.ffmpeg,arguments:["-ss",gif.range!.ss,"-t",gif.range!.t,"-i",gif.path,"-vf",vf,"-y",gif.palettePath])
                    //if self.stopTask { return }
                    result = result + self.shell(self.ffmpeg,arguments:["-ss",gif.range!.ss,"-t",gif.range!.t,"-i",gif.path,"-i",gif.palettePath,"-lavfi",lavfi,"-gifflags","+transdiff","-y",gif.gifPath])
                }
                //if self.stopTask { return }
            }
            
            print(result)
            
            if gif.quality.needCompress()
            {
                self.compress(gif)
            }
            //if self.stopTask { return }

            DispatchQueue.main.async {
            

                let path = gif.quality.needCompress() ? gif.comporesGifPath : gif.gifPath
                
                if self.fm.fileExists(atPath: path!)
                {
                    //if self.stopTask { return }
                    complete(true,path)
                }else
                {
                    //if self.stopTask { return }
                    complete(false,nil)
                }
                
            }//end main
        
        })//end background
    }



    
    
    func compress(_ gif:GIF)
    {
        print("start compress")
        let q = String(format:"--lossy=%@",gif.quality.lossy())
        let result = shell(gifsicle,arguments:["-O3",q,"-o",gif.comporesGifPath,gif.gifPath])
        print(result)
    }
    
    func loadGIF(_ path:String,complete:@escaping (_ gif:GIF,_ err:String)->Void)
    {
        stopTask = false
        /*
         http://stackoverflow.com/questions/7708373/get-ffmpeg-information-in-friendly-way
         */
        
        let gif = GIF()
        
        let fm = FileManager.default
        
        if let dir = try? fm.attributesOfItem(atPath: path)
        {
            let size = (dir[FileAttributeKey.size] as! NSNumber).floatValue/(1024*1024)
            print(size)
            if size > 100
            {
                complete(gif, "GIF Works Pro can only convert file less than 100MB.")
                return
            }
        }
        

        convertQueue!.async(execute: { () -> Void in
            //"-show_streams"
            //"-show_format"
            //let arguments = ["-v","quiet","-print_format","json","-select_streams","v:0","-show_format","-show_entries","stream=height,width,r_frame_rate",path]
                        let arguments = ["-v","quiet","-print_format","json","-select_streams","v:0","-show_format","-show_streams",path]
            let result = self.shell(self.ffprobe,arguments:arguments)
            let data = try? JSONSerialization.jsonObject(with: result.data(using: String.Encoding.utf8)!, options:.allowFragments)
            
            if data != nil
            {
                let json = JSON(data!)
                
                print(json)
                
                gif.path = path
                gif.size = CGSize(width: CGFloat(json["streams"][0]["width"].floatValue), height: CGFloat(json["streams"][0]["height"].floatValue))
                gif.duration = json["format"]["duration"].doubleValue
                
                //400 225
                //print(gif)
                
                var scale = ""
                if gif.size.width/400 <  gif.size.height/225
                {
                    scale = "scale=-1:225"
                }else
                {
                    scale = "scale=400:-1"
                }
                
                
                let _ = try? fm.removeItem(atPath: thumbPath)
                let _ = try? fm.createDirectory(atPath: thumbPath, withIntermediateDirectories: true, attributes: nil)
                
                
                var r = 36/gif.duration
                r = min(r,6)
                r = max(r,1)
                let arguments =  ["-i",path,"-r",String(format:"%.0d",Int(r)),"-vf",scale,thumbPath + "/t%5d.jpg"]
                _ = self.shell(self.ffmpeg,arguments:arguments)
                
                var files = [String]()
                do{
                    if let a = try? fm.contentsOfDirectory(atPath: thumbPath)
                    {
                        for item in a
                        {
                            files.append(String(format:"%@/%@",thumbPath,item))
                        }
                    }
                }
                gif.thumb = files
                
                DispatchQueue.main.async {
                    complete(gif, "")
                }
                
            }else
            {
                DispatchQueue.main.async {
                    complete(gif, "get video file error.")
                }
            }
        })

    }
    
    
    
    
    func thumb(_ path:String,complete:@escaping (_ dir:[String]?)->Void)
    {
        //./ffmpeg -i 1.mp3 -vf scale=100:-1 example.%d.jpg
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: { () -> Void in
            
            let fm = FileManager.default
            do{
                try fm.removeItem(atPath: thumbPath)
                try fm.createDirectory(atPath: thumbPath, withIntermediateDirectories: true, attributes: nil)
            }catch{}
            
            
            
            let arguments =  ["-i",path,"-r","6","-vf","scale=200:-1",thumbPath + "/t%5d.jpg"]
            let _ = self.shell(self.ffmpeg,arguments:arguments)
            //print(result)
            
            var files = [String]()
            do{
                if let a = try? fm.contentsOfDirectory(atPath: thumbPath)
                {
                    for item in a
                {
                    files.append(String(format:"%@/%@",thumbPath,item))
                }
                }
            }
            


            if self.stopTask
            {
                return
            }
            DispatchQueue.main.async {
                complete(files)
            }
            
        })

    }
    
    
    func shell(_ launchPath: String, arguments: [String]? = nil) -> String
    {

        if stopTask
        {
            return ""
        }
        print("shell:")
        print(launchPath)
        print(arguments!)
        print("========================")
        
        let task = Process()
        tasks.append(task)
        
        task.launchPath = launchPath
        if arguments == nil
        {
            task.arguments = [String]()
        }else
        {
            task.arguments = arguments
        }
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError  = pipe
        task.launch()
        
        let data   = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8) ?? ""
        
        
        
        return output
    }
    
    
}



/*
 
 
 dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), { () -> Void in
 

 dispatch_async(dispatch_get_main_queue()) {

 }
 
 })
 
 */



