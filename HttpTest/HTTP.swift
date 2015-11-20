//
//  HTTP.swift
//  HttpTest
//
//  Created by wanglong on 15/11/17.
//  Copyright © 2015年 wanglong. All rights reserved.
//

import Foundation

enum Method{
    case GET,POST,HEAD,DELETE
}

/// http请求类
class Request {
    let method:Method
    let protoVersion:String
    var url:NSURL
    var host:String
    var port:Int
    var headers = Dictionary<String,String>()
    var body:String?
    //初始化请求
    init(method:Method,url:String){
        self.method = method
        self.protoVersion = "HTTP/1.1"
        var nsurl = NSURL(string: url)
        if nsurl==nil{
            nsurl = NSURL(string: "http://www.yunfancdn.com/1")
        }
        self.url = nsurl!
        //如果没有端口,则默认设置80
        if(self.url.port==nil){
            self.port = 80
        }else{
            self.port = Int(self.url.port!)
        }
        self.host = self.url.host!
        //设置默认http头
        headers["User-Agent"]="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/601.2.7 (KHTML, like Gecko) Version/9.0.1 afari/601.2.7"
        headers["Connection"] = "Close"//"keep-alive"
        headers["Accept"] = "text/html"
        headers["Host"] = self.url.host
    }
    
    func httpHeadString()->String{
        
        var httpString = "\(String(self.method)) "
        httpString += (self.url.path != "") ? self.url.path! : "/"
        httpString += (self.url.query != nil) ? "?\(self.url.query!) " : " "
        httpString += "\(self.protoVersion)\r\n"

        for (key,vaule) in headers{
            httpString += "\(key): \(vaule)\r\n"
        }
        httpString += "\r\n"
        
        return httpString
    }
    
    /**
     拼接String类型的请求数据
     
     - returns: 返回一串String
     */
    func toString()->String{
        var httpString = self.httpHeadString()
        
        //http头部结束,加上body
        if let body = self.body{
            httpString += body
        }
        return httpString
    }//toString end
    func toUInt8Array()->[UInt8]{
        let httpHeadString = self.httpHeadString()
        let buffLen:Int
        //如果有body,计算buff长度算上body.如果没有body,只计算http头部
        if let body = self.body{
            buffLen = httpHeadString.utf8.count + body.utf8.count
        }else{
            buffLen = httpHeadString.utf8.count
        }
        //生成buff数组
        var buff = [UInt8](count: buffLen, repeatedValue: 0x0)
        var i = 0
        //遍历http头字符
        for ch in httpHeadString.utf8{
            buff[i++] = ch.advancedBy(0)
        }
        //遍历body字符
        if let body = self.body{
            for ch in body.utf8{
                buff[i++] = ch.advancedBy(0)
            }
        }
        return buff
    }
    
}

//http 返回类
class Respone{
    
    var headers = Dictionary<String,String>()
//    var body:String?
    let code:Int
    let description:String?
    var body:NSMutableData = NSMutableData()
    /**
     将respone的内容解析后对应到Respone类的成员
     
     - parameter respone: 待解析的数据
     
     - returns: 无
     */
    init(respone :NSData){
        //回复数据转String
        let respString = String(NSString(data: respone, encoding: NSUTF8StringEncoding)!)
        //截取http头部分
        let endFlagRange = respString.rangeOfString("\r\n\r\n")
        if (endFlagRange == nil){
            print("http数据没有\r\n\r\n结尾")
        }
        //提取出http头
        let httpHeadString = respString.substringToIndex(endFlagRange!.startIndex)
        //提取出首行
        let firstFlag = httpHeadString.rangeOfString("\r\n")
        let firstRowString = httpHeadString.substringToIndex(firstFlag!.startIndex)
        //提取其他行
        let headersRowString = httpHeadString.substringFromIndex(firstFlag!.endIndex)
        //首行按空格分隔为数组
        let firstRowArray = firstRowString.componentsSeparatedByString(" ")
        //http状态码和描述
        if let code = Int(firstRowArray[1]){
            self.code = code
        }else{
            print("http code invaild:\(firstRowString)")
            self.code = 100
        }
        self.description = firstRowArray[2]
        
        //使用"\r\n"分隔字符串,保存数组
        let rows = headersRowString.componentsSeparatedByString("\r\n")
        for row in rows{

            //使用":"分隔字符串,保存字典
            let keyRange = row.rangeOfString(":")
            if(keyRange == nil){
                print("http数据headers没有':':\(row) ----")
            }
            var key = row.substringToIndex(keyRange!.startIndex)
            var vaule = row.substringFromIndex(keyRange!.endIndex)
            //去掉左右空格
            key = key.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            vaule = vaule.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            
            self.headers[key] = vaule
        }
        //提取出body
        let httpBody = respString.substringFromIndex(endFlagRange!.endIndex)
        if !httpBody.isEmpty{
            //有body
            self.body.appendData(httpBody.dataUsingEncoding(NSUTF8StringEncoding)!)

        }
        
    }//init end
    
    /**
    将输入数据解析为json,格式不为json时,报错
    
    - parameter data: 数据
    
    - returns: 对应的字典
    */
    static func parseJson(data:String) ->AnyObject?{

        let data = data.dataUsingEncoding(NSUTF8StringEncoding)!
        do{
            //将http头解析为josn
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)
            return json//(json as! Dictionary<String, String>)
        }catch let error as NSError{
            print("parseJson fail : \(error)")
        }
        return nil
    }//parseJson end
    
    

    
    
}//respone end