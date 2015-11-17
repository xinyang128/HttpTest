//
//  StunTest.swift
//  HttpTest
//
//  Created by wanglong on 15/11/17.
//  Copyright © 2015年 wanglong. All rights reserved.
//

import Foundation
class StunTest {
    
    /**
     请求穿透服务器
     
     - parameter url:    服务器地址
     - parameter lopNum: 循环次数
     */
    static func requestStunServer(url:String,lopNum:UInt) -> Void{
        //检查参数
        if(lopNum<1){
            print("lopNum必须大于0,实际为:\(lopNum)")
            //标记主线程可以退出
            mainThreadOver = true
            return
        }
        //计时开始
        var num:UInt = 0
        let start:Double = NSDate().timeIntervalSince1970
        //保存结果
        var rets = Dictionary<String,Int>()
        
        //创建NSURL对象
        let url:NSURL? = NSURL(string:url)
        //创建session
//        let session = NSURLSession.sharedSession()
        
        //创建请求对象
        var request:NSURLRequest = NSURLRequest(URL: url!)
        
        //添加线程锁
        let lock = NSLock()
        for _ in 1...lopNum{
            
            //生成随机40位hash
            var hashRand:String=""
            for _ in 1...5{
                let rand:String = String(format: "%08x",arc4random_uniform(4294967295))
                hashRand += rand
            }

            //添加http头
            let mutableRequest: NSMutableURLRequest = request.mutableCopy() as! NSMutableURLRequest
            mutableRequest.setValue("cztv", forHTTPHeaderField: "source")
            mutableRequest.setValue(hashRand, forHTTPHeaderField: "hash")
            mutableRequest.setValue("close", forHTTPHeaderField: "Connection")
            request = mutableRequest.copy() as! NSURLRequest
//            print(request.allHTTPHeaderFields!["hash"])
            
            //设置session超时
            let sessionConfig:NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
//            sessionConfig.timeoutIntervalForRequest = 1
            let session = NSURLSession(configuration: sessionConfig)
            

            //session开始请求
            let dataTask = session.dataTaskWithRequest(request,
                completionHandler: {(data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in

                    //加锁
                    lock.lock()
                    if (error != nil){
                        if(error!.code == -1001){
                            if (rets["timeout"] == nil){
                                //第一次初始1
                                rets["timeout"] = 1
                            }else{
                                rets["timeout"]!++
                            }
                        }else{
                            print(error!.code)
                            print(error!.description)
                            
                        }
                        
                    }else{
                        let str = String(NSString(data: data!, encoding: NSUTF8StringEncoding))
//                        print(str)
                        if (rets[str] == nil){
                            //第一次初始1
                            rets[str] = 1
                        }else{
                            rets[str]!++
                        }
                        
                    }

                    //改变计数
                    num++
                    if num==lopNum{
                        //计时结束
                        let end:Double = NSDate().timeIntervalSince1970
                        print(end-start)
                        print(rets)
                        //标记主线程可以退出
                        mainThreadOver = true
                    }
                    //释放锁
                    lock.unlock()
            }) as NSURLSessionTask
            //使用resume方法启动任务
            dataTask.resume()
            
            
        }//for
    }//func
    
}//class









