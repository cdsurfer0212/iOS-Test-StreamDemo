//
//  ViewController.swift
//  StreamDemo
//
//  Created by Sean Zeng on 6/28/16.
//  Copyright © 2016 Yahoo. All rights reserved.
//

import UIKit

class ViewController: UIViewController, NSStreamDelegate {

    private let id = "cdsurfer"
    private let password = ""
    private var inputStream: NSInputStream?
    private var outputStream: NSOutputStream?
    
    deinit {
        inputStream!.close()
        outputStream!.close()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupStreams()
    }
    
    // MARK: NSStreamDelegate
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        print(eventCode)
        
        if (eventCode == NSStreamEvent.HasBytesAvailable) {
            var buffer = [UInt8](count: 1024, repeatedValue: 0)
            if (aStream == inputStream) {
                let len = inputStream!.read(&buffer, maxLength: buffer.count)
                if (len > 0) {
                    let output = NSString(bytes: &buffer, length: len, encoding: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.Big5.rawValue)))
                    
                    if let output = output {
                        print(output)

                        if (output.containsString("new")) {
                            writeOutputStream("\(id)\r\(password)\r")
                        } else if (output.containsString("您想刪除其他重複登入的連線嗎？")) {
                            writeOutputStream("y\r")
                        } else if (output.containsString("歡迎您再度拜訪")) {
                            writeOutputStream("\r")
                        } else if (output.containsString("休閒聊天區")) {
                            writeOutputStream("t\r\r")
                        } else if (output.containsString("我的朋友")) {
                            writeOutputStream("q")
                        } else if (output.containsString("登入次數")) {
                            do {
                                var regex = try NSRegularExpression(pattern: "《登入次數》\\[1;34m([0-9]*)\\[m 次", options: [])
                                regex = try NSRegularExpression(pattern: "(?<=\\[1;34m).*(?=\u{1B}\\[m)", options: [])
                                let matches = regex.matchesInString(output as String, options: [], range: NSMakeRange(0, output.length))
                                
                                print(matches.map { output.substringWithRange($0.range) }[0])
                                
                            } catch let error as NSError {
                                print("error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Private methods
    private func setupStreams() {
        var readStream: Unmanaged<CFReadStreamRef>?
        var writeStream: Unmanaged<CFWriteStreamRef>?
        
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, "140.112.172.11", 23, &readStream, &writeStream)

        if (readStream != nil) {
            //CFReadStreamSetProperty(inputStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue)
            inputStream = readStream!.takeRetainedValue()
            inputStream!.delegate = self
            inputStream!.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            inputStream!.open()
        }
        
        if (writeStream != nil) {
            //CFWriteStreamSetProperty(outputStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue)
            outputStream = writeStream!.takeRetainedValue()
            outputStream!.delegate = self
            outputStream!.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            outputStream!.open()
        }
    }
    
    private func writeOutputStream(string: String) {
        let data = string.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: false)!
        outputStream!.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
    }
}