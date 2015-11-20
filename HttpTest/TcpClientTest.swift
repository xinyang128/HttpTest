//
//  TcpClientTest.swift
//  HttpTest
//
//  Created by wanglong on 15/11/17.
//  Copyright © 2015年 wanglong. All rights reserved.
//

import Foundation


class TcpClientTest {
    func lop(){
        let lopnum = 1000
        var num = 0
        let lock = NSLock()
        for _ in 0...lopnum{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                //新的线程
                self.test()
                lock.lock()
                if (num++ == lopnum) {
                    mainThreadOver = true
                    print("OK")
                }
                lock.unlock()
                dispatch_async(dispatch_get_main_queue(), {
                    
                    //这里返回主线程，写需要主线程执行的代码
                    print("这里返回主线程，写需要主线程执行的代码")
                    
                })
                
            })

        }
    }
    func test() -> Void{
        //是否需要将body保存为文件
        let saveToFile = false
        //生成请求实例
        let client = TcpClient()
        let http = Request(method: .GET, url: "http://172.17.10.230:5100/live/hash/rtmp://dlrtmp.cdn.zhanqi.tv/zqlive/62147_q1e8?srcip=202.96.143.134")
        
//        http.body = "123"
        //生成随机40位hash
        var hashRand:String=""
        for _ in 1...5{
            let rand:String = String(format: "%08x",arc4random_uniform(4294967295))
            hashRand += rand
        }
        //添加http头
        http.headers["source"] = "cztv"
        http.headers["hash"] = hashRand

        
        //连接服务器
        var (ok,error) = client.connect(http.host, port: http.port, timeout: 5)
        if !ok{
            print(error)
            return
        }
            //连接成功
            
        (ok,error) = client.send(http.toString())
        if !ok{
            print(error)
            return
        }
        //发送成功,阻塞等待返回数据,小文件
        /*
        let buffLen = 1024
        let ret = client.read(buffLen)
        if(ret != nil){
            //此处如果respone包含httpbody部分可能编码会报错的,应该先使用NSdata处理
            let resp = Respone(respone:ret!)
            print(resp.headers)
        }else{
            print("client.read失败,ret=\(ret)")
        }*/
        
        //*
        var outFile : NSFileHandle?
        if saveToFile{
            //保存文件,大文件
            let filePath = "/Users/wanglong/Downloads/11.ts"

            //创建文件
            let fileManager = NSFileManager.defaultManager()
            if !fileManager.createFileAtPath(filePath, contents: nil, attributes: nil){
                print("文件创建失败:\(filePath)")
            }
            //打开文件
            outFile = NSFileHandle(forWritingAtPath: filePath )
            if (outFile == nil){
                print("文件打开失败:\(filePath)")
            }

        }
        //每次接收数据大小
        let buffLen = 1460
        var responeLen = 0
        //保存http头数据
        var httpHeadString = ""
        var resp:Respone?
                //是否还在http头
        var isHead = true
        while true{
            var ret = client.read(buffLen)
//            if( retData != nil){
            if var retData = ret{
                //接收正常
                responeLen += retData.length
                //去掉http头
                if isHead{
                    let flagRange = retData.rangeOfData("\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)! , options: NSDataSearchOptions.Backwards, range: NSRange(location: 0, length: retData.length))
                    if(flagRange.length == 0){
                        httpHeadString += String(NSString(data: retData, encoding: NSUTF8StringEncoding))
                        
                        continue
                    }
                    //找到了
                    isHead = false
                    let flagEnd = flagRange.location + flagRange.length
                    //最后的一部分http头部
                    let httpLastHead = retData.subdataWithRange(NSRange(location: 0, length: flagEnd))
                    httpHeadString += String(NSString(data: httpLastHead, encoding: NSUTF8StringEncoding))
                    resp = Respone(respone:httpHeadString.dataUsingEncoding(NSUTF8StringEncoding)!)
                    
                    
                    //body的第一部分
                    retData = retData.subdataWithRange(NSRange(location: flagEnd, length: retData.length - flagEnd))

                }
                //seek到最后位置
//                    outFile!.seekToEndOfFile()
                
                //把body写入文件
                if saveToFile {
                    outFile!.writeData(retData)
                }else{
                    resp!.body.appendData(retData)

                }
                
            }else{
                //接收完成或接收异常
                break
            }
        }
        //关闭文件
        if saveToFile{ outFile?.closeFile()}
        //结束
        print(resp?.headers["Location"])
        /*
        //计算md5
        let md5 = resp!.body.md5()
        if (md5 == "ee13e17f7c3cac479b98619bc5c709b3"){
//            print("ok")
        }else{
            print(md5)
        }
        */
//        print("数据接收完成,大小:\(responeLen)")
//        */
        
        client.close()
    }//testend
    deinit{
        print(1)
    }
    
    func parseJson(data:String){
        //把返回数据按照json解析
        
        let bodyJson = Respone.parseJson(data)
        if bodyJson != nil{
        //解析json成功
        print(bodyJson)
            
        }
    }
}//classend

extension NSData{
    func md5() ->String!{
        
        //计算body的md5
        let dataLen = CUnsignedInt(self.length)
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        CC_MD5(self.bytes, dataLen, result)
        var hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.destroy()
        return hash as String
    }
}//extensionend

