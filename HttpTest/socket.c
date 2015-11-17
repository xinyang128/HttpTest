//
//  socket.c
//  HttpTest
//
//  Created by wanglong on 15/11/17.
//  Copyright © 2015年 wanglong. All rights reserved.
//
#include "HttpTest-Bridging-Header.h"
#include <stdio.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netdb.h>
#include <unistd.h>
#include <fcntl.h>
//#include <errno.h>
//#include <stdlib.h>
//#include <signal.h>
//#include <dirent.h>
//#include <sys/types.h>
//#include <netinet/in.h>
//#include <sys/stat.h>


/**
 *  设置socket是否阻塞
 *
 *  @param socket socket描述符
 *  @param on     0非阻塞,其他阻塞
 */
void socket_set_block(int socket,int on) {
    int flags;
    flags = fcntl(socket,F_GETFL,0);
    if (on==0) {
        fcntl(socket, F_SETFL, flags | O_NONBLOCK);
    }else{
        flags &= ~ O_NONBLOCK;
        fcntl(socket, F_SETFL, flags);
    }
}
int socket_connect(const char *host,int port,int timeout){
    struct sockaddr_in sa;
    struct hostent *ph;
    int sockfd = -1;
    ph = gethostbyname(host);
    if(ph==NULL){
        return -1;
    }
    //设置sockaddr_in值
    bcopy((char *)ph->h_addr, (char *)&sa.sin_addr, ph->h_length);
    sa.sin_family = ph->h_addrtype;
    sa.sin_port = htons(port);
    sockfd = socket(ph->h_addrtype, SOCK_STREAM, 0);
    //设置非阻塞connect连接
    socket_set_block(sockfd,0);
    connect(sockfd, (struct sockaddr *)&sa, sizeof(sa));
    fd_set          fdwrite;
    struct timeval  tvSelect;
    FD_ZERO(&fdwrite);
    FD_SET(sockfd, &fdwrite);
    tvSelect.tv_sec = timeout;
    tvSelect.tv_usec = 0;
    int retval = select(sockfd + 1,NULL, &fdwrite, NULL, &tvSelect);
    if (retval<0) {
        return -2;
    }else if(retval==0){//timeout
        return -3;
    }else{
        int error=0;
        int errlen=sizeof(error);
        getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &error, (socklen_t *)&errlen);
        if(error!=0){
            return -4;//connect fail
        }
        socket_set_block(sockfd, 1);
        int set = 1;
        setsockopt(sockfd, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
        return sockfd;
    }
}
int socket_close(int socketfd){
    return close(socketfd);
}
int socket_read(int socketfd,char *data,int len){
    return (int)read(socketfd,data,len);
}
int socket_send(int socketfd,const char *data,int len){
    int bytesWrite=0;
    while (len-bytesWrite>0) {
        int writelen=(int)write(socketfd, data+bytesWrite, len-bytesWrite);
        if (writelen<0) {
            return writelen;
        }
        bytesWrite+=writelen;
    }
    return bytesWrite;
}

//---------server----
int socket_listen(const char *addr,int port){
    //create socket
    int socketfd=socket(AF_INET, SOCK_STREAM, 0);
    int reuseon   = 1;
    setsockopt( socketfd, SOL_SOCKET, SO_REUSEADDR, &reuseon, sizeof(reuseon) );
    //bind
    struct sockaddr_in serv_addr;
    memset( &serv_addr, '\0', sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = inet_addr(addr);
    serv_addr.sin_port = htons(port);
    int r=bind(socketfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr));
    if(r==0){
        if (listen(socketfd, 128)==0) {
            return socketfd;
        }else{
            return -2;//listen error
        }
    }else{
        return -1;//bind error
    }
}
//return client socket fd
int socket_accept(int onsocketfd,char *remoteip,int* remoteport){
    socklen_t clilen;
    struct sockaddr_in  cli_addr;
    clilen = sizeof(cli_addr);
    int newsockfd = accept(onsocketfd, (struct sockaddr *) &cli_addr, &clilen);
    char *clientip=inet_ntoa(cli_addr.sin_addr);
    memcpy(remoteip, clientip, strlen(clientip));
    *remoteport=cli_addr.sin_port;
    if(newsockfd>0){
        return newsockfd;
    }else{
        return -1;
    }
}