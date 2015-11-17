//
//  TcpClientTest.swift
//  HttpTest
//
//  Created by wanglong on 15/11/17.
//  Copyright © 2015年 wanglong. All rights reserved.
//

import Foundation

class TcpClientTest {
    static func test(){
        let client = TcpClient()
        let (ok,error) = client.connect("175.6.0.10", port: 80, timeout: 5)
        if !ok{
            print(error)
        }else{
            //连接成功
            let (ok,error) = client.send("123abc")
            if !ok{
                print(error)
            }else{
                //发送成功,阻塞等待返回数据
                let ret = client.read(1000)
                if(ret != nil){
                    let s = String(NSString(data: ret!, encoding: NSUTF8StringEncoding))
                    print(s)
                }
            
            }
            
        }
        client.close()
    }//testend
}//classend