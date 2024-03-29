//
//  TcpClient.swift
//  HttpTest
//
//  Created by wanglong on 15/11/17.
//  Copyright © 2015年 wanglong. All rights reserved.
//

import Foundation

@asmname("socket_connect") func c_socket_connect(host:UnsafePointer<UInt8>,port:Int32,timeout:Int32) -> Int32
@asmname("socket_close") func c_socket_close(fd:Int32) -> Int32
@asmname("socket_send") func c_socket_send(fd:Int32,data:UnsafePointer<UInt8>,len:Int32) -> Int32
@asmname("socket_read") func c_socket_read(fd:Int32,buff:UnsafePointer<UInt8>,len:Int32) -> Int32


class TcpClient {

    var fd:Int32?

    /**
     连接特定的服务器
     
     - parameter addr: 服务器地址
     - parameter port: 服务器端口
     - parameter t:    连接超时时间
     
     - returns: 连接结果和message
     */
    func connect(addr:String,port:Int,timeout t:Int)->(Bool,String){

        let socketFD:Int32=c_socket_connect(addr, port:Int32(port),timeout: Int32(t))
        
        if socketFD>0{
            self.fd=socketFD
            return (true,"connect success")
        }else{
            switch socketFD{
            case -1:
                return (false,"gethostbyname fail")
            case -2:
                return (false,"connection closed")
            case -3:
                return (false,"connect timeout")
            case -4:
                return (false,"server not available")
            default:
                return (false,"unknow err.")
            }
        }
    } //func end
    /**
    关闭连接
    
    - returns: 是否成功
    */
    func close()->(Bool,String){
        if let fd:Int32=self.fd{
            c_socket_close(fd)
            self.fd=nil
            return (true,"close success")
        }else{
            return (false,"socket not open")
        }
    }//func end
    
    /**
    send数据
    
    - parameter buff: char数组
    
    - returns: true?flase,和message
    */
    func send(buff:[UInt8])->(Bool,String){
        if let fd:Int32=self.fd{
            let sendSize:Int32=c_socket_send(fd, data: buff, len: Int32(buff.count))
            if Int(sendSize)==buff.count{
                return (true,"send success")
            }else{
                return (false,"send error")
            }
        }else{
            return (false,"socket not open")
        }
    }
    /**
     send数据
     
     - parameter str: String格式
     
     - returns: true?flase,和message
     */
    func send(str:String)->(Bool,String){
        if let fd:Int32=self.fd{
            let sendSize:Int32=c_socket_send(fd, data: str, len: Int32(strlen(str)))
            if sendSize==Int32(strlen(str)){
                return (true,"send success")
            }else{
                return (false,"send error")
            }
        }else{
            return (false,"socket not open")
        }
    }
    /**
     send数据
     
     - parameter data: NSdata格式
     
     - returns: true?flase,和message
     */
    func send(data:NSData)->(Bool,String){
        if let fd:Int32=self.fd{
            var buff:[UInt8] = [UInt8](count:data.length,repeatedValue:0x0)
            data.getBytes(&buff, length: data.length)
            let sendSize:Int32=c_socket_send(fd, data: buff, len: Int32(data.length))
            if sendSize==Int32(data.length){
                return (true,"send success")
            }else{
                return (false,"send error")
            }
        }else{
            return (false,"socket not open")
        }
    }
    /**
     从socket缓冲区读取len长度的数据
     
     - parameter len: 读取长度
     
     - returns: 返回实际读取char数组
     */
    func read(len:Int)->NSData?{
        if let fd:Int32 = self.fd{
            var buff:[UInt8] = [UInt8](count:len,repeatedValue:0x0)
            let readLen:Int32=c_socket_read(fd, buff: &buff, len: Int32(len))
            if (readLen > 0){
                
                return NSData(bytes: buff, length: Int(readLen))
                
            }else if(readLen == 0){
                
//                print("接收已完成,ret=\(readLen)")
            }else if(readLen < 0 ){
                print("数据接收异常:错误(\(readLen))")
            }
            
        }
        return nil
    }
}//class end











