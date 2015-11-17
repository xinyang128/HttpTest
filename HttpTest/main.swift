//
//  main.swift
//  HttpTest
//
//  Created by wanglong on 15/11/16.
//  Copyright © 2015年 wanglong. All rights reserved.
//

import Foundation

//保持主线程存活在异步线程执行完毕
var mainThreadOver = false
print("Hello, World!")
//---------------------user start--------------------

//穿透调度测试
//StunTest.requestStunServer("http://175.6.0.10:8868",lopNum: 100)

//tcp测试
TcpClientTest.test()
mainThreadOver = true
//---------------------user end--------------------
while true{
    if mainThreadOver{
        break
    }
    sleep(1)
    
}
