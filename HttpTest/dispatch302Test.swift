//
//  dispatch302Test.swift
//  HttpTest
//
//  Created by wanglong on 15/11/20.
//  Copyright © 2015年 wanglong. All rights reserved.
//

import Foundation

//
class DispatchTest {

    var result = Dictionary<String,Int>()
    let lock = NSLock()
    /**
     请求302调度服务
     
     - parameter url: 请求地址
     
     - returns: 返回跳转后的Location地址
     */
    func request(url : String) ->String? {
        //生成请求实例
        let client = TcpClient()
        let http = Request(method: .GET, url: url)
        //连接服务器
        var (ok,error) = client.connect(http.host, port: http.port, timeout: 5)
        if !ok{
            print("连接服务器失败:\(error)")
            client.close()
            return nil
        }
        //连接成功,发送请求数据
        (ok,error) = client.send(http.toString())
        if !ok{
            print("向服务器发送数据失败:\(error)")
            client.close()
            return nil
        }
        //发送成功,阻塞等待返回数据,小文件
        let buffLen = 1024
        let ret = client.read(buffLen)
        if(ret != nil){
            //解析返回数据,必须为UTF8
            let resp = Respone(respone:ret!)
            client.close()
            return resp.headers["Location"]
        }else{
            print("client.read失败,ret=\(ret)")
        }
        
        client.close()
        return nil
    }//request end
    /**
    传入返回的location,以字典形式汇总
    
    - parameter location: 单个请求获取的location
    */
    func sumLocationResult(location : String){
        //将Location中的IP提取出来放入字典中汇总
        let locUrl = NSURL(string: location)
        if let ip = locUrl?.host{
            self.lock.lock()
            if (result[ip] == nil){
                result[ip] = 1
            }else{
                result[ip]! += 1
            }
            self.lock.unlock()
        }else{
            print("非法URL:\(location)")
        }

    }
    
    /**
     每个请求一个线程,并发请求调度服务
     */
    static func lop(){
        let start = NSDate().timeIntervalSince1970
        let lopnum = 5000

        var num = 0
        //创建实例
        let dispatch = DispatchTest()
        let lock = NSLock()

        for _ in 1...lopnum{
            //如果没有资料就等待,tcp连接数限制1024


            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {

                //请求调度
                let location = dispatch.request("http://172.17.10.230:5100/live/hash/rtmp://dlrtmp.cdn.zhanqi.tv/zqlive/62147_q1e9?srcip=202.96.143.134")
                if let loc = location{
                    dispatch.sumLocationResult(loc)
                }else{
                    print("dispatch.request返回nil")
                }
                
                //加锁计线程数
                lock.lock()
                if (++num == lopnum) {
                    print(dispatch.result)
                    let t = NSDate().timeIntervalSince1970 - start
                    print("耗时:\(t)")
                    mainThreadOver = true
                }
                lock.unlock()
            })
            
        } //for end
    }//lop end
}//class end