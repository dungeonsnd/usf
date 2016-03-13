//
//  USFNetworkTool.m
//  LibeventT
//
//  Created by jeffery on 16/3/13.
//  Copyright © 2016年 jeffery. All rights reserved.
//
//
//bufferevent_socket_connect_hostname和 evdns_getaddrinfo 这两种方式貌似在 iOS 真机上似乎都有BUG，而在模拟器上是没问题的。
//用这个 Low-level DNS interfaces 才行。
//


#import "USFNetworkTool.h"

#include <stdio.h>
#include <string>
#include <sys/socket.h>

#include "event2/dns.h"
#include "event2/bufferevent.h"
#include "event2/buffer.h"
#include "event2/util.h"
#include "event2/event.h"

@implementation USFNetworkTool

enum usfnwtConnectionStatus{
    usfnwt_NotConnected =1,
    usfnwt_Connecting =2,
    usfnwt_Connected =3
};

typedef struct _tagUsfnwtGlobalData{
    
    struct event_base *base;
    struct evdns_base *dnsBase;
    
    std::string host;
    std::string ip;
    int port;
    struct bufferevent *bev;
    int connStatus;
    
}usfnwtGlobalData;


void usfnwtSocketConnect(struct bufferevent *bev, usfnwtGlobalData &globaData)
{
    globaData.bev =bev;
    globaData.connStatus =usfnwt_Connecting;
}
void usfnwtSocketConnected(usfnwtGlobalData &globaData)
{
    globaData.connStatus =usfnwt_Connected;
}
void usfnwtSocketClosed(struct bufferevent *bev, usfnwtGlobalData &globaData)
{
    NSLog(@"Closing");
    bufferevent_free(bev);
    globaData.bev =NULL;
    globaData.connStatus =usfnwt_NotConnected;
}



void usfnwtReadCb(struct bufferevent *bev, void *arg)
{
    struct evbuffer *input = bufferevent_get_input(bev);
    size_t inputLen =evbuffer_get_length(input);
    NSLog(@"usfnwtReadCb, inputLen=%d", (int)(inputLen));
    
    char buf[1024];
    bufferevent_read(bev, buf, 9);
}

void usfnwtWriteCb(struct bufferevent *bev, void *arg)
{
    NSLog(@"usfnwtWriteCb");
}

#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
void usfnwtEventCb(struct bufferevent *bev, short events, void *arg)
{
    usfnwtGlobalData *globaData = (usfnwtGlobalData *)(arg);
    
    int errorcode =EVUTIL_SOCKET_ERROR();
    
    if (events & BEV_EVENT_CONNECTED)
    {
        NSLog(@"Connect okay.");
        usfnwtSocketConnected(*globaData);
    }
    else if (events & (BEV_EVENT_EOF))
    {
        printf("BEV_EVENT_EOF from %s\n", globaData->host.c_str() );
        usfnwtSocketClosed(bev, *globaData);
    }
    else if (events & (BEV_EVENT_TIMEOUT))
    {
        printf("BEV_EVENT_TIMEOUT from %s \n",
               globaData->host.c_str() );
        usfnwtSocketClosed(bev, *globaData);
    }
    else if (events & (BEV_EVENT_ERROR))
    {
        printf("BEV_EVENT_ERROR from %s: %s\n",
               globaData->host.c_str(),
               evutil_socket_error_to_string(errorcode));

        int err = bufferevent_socket_get_dns_error(bev);
        if (err)
        {
            NSLog(@"DNS error{%d}: %s\n", err, evutil_gai_strerror(err));
            if ((globaData->ip).length()<1) {
                usfnwtStartDnsResolve(*globaData);
            }
        }
        usfnwtSocketClosed(bev, *globaData);
    }
}

void usfnwtTimerCb(evutil_socket_t fd, short what, void *arg)
{
    usfnwtGlobalData *globaData = (usfnwtGlobalData *)(arg);
    
    if (usfnwt_Connected==globaData->connStatus)
    {
        char heartBeart[9];
        memset(heartBeart, 0, sizeof(heartBeart));
        bufferevent_write(globaData->bev, heartBeart, sizeof(heartBeart));
    } else if (usfnwt_NotConnected==globaData->connStatus)
    {
        
    }
}


void usfnwtDnsResolveCb(int result, char type, int count,
                  int ttl, void *addresses, void *arg)
{
    usfnwtGlobalData *globaData = (usfnwtGlobalData *)(arg);
    //    DNS_ERR_NONE
    //    DNS_IPv4_A
    printf("usfnwtDnsResolveCb, result=%d, type=%d, count=%d, ttl=%d \n",
           result, type, count, ttl);
    if (DNS_ERR_NONE==result) {
        printf("usfnwtDnsResolveCb DNS_ERR_NONE\n");
        
        char buf[128];
        const char *s = NULL;
        if (DNS_IPv4_A == type) {
            
            struct sockaddr_in sin;
            memset(&sin, 0, sizeof(sin));
            sin.sin_addr.s_addr = *((unsigned*)(addresses));
            s = evutil_inet_ntop(AF_INET, &sin.sin_addr, buf, 128);
        } else if (DNS_IPv6_AAAA == type) {
            //struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)ai->ai_addr;
            //s = evutil_inet_ntop(AF_INET6, &sin6->sin6_addr, buf, 128);
        }
        if (s)
        {
            globaData->ip =s;
            printf("    -> %s\n", s);
            usfnwtConnectServer(*globaData);
        }
    }
}

int usfnwtStartDnsResolve(usfnwtGlobalData & globaData)
{
    struct evdns_request * r=evdns_base_resolve_ipv4(globaData.dnsBase,
                                                     globaData.host.c_str(),
                                                     0,
                                                     usfnwtDnsResolveCb,
                                                     &globaData);
    if (!r)
        return  -1;
    return 0;
}

int usfnwtConnectServer(usfnwtGlobalData & globaData)
{
    int res =-1;
    do{
        struct bufferevent *bev = bufferevent_socket_new(globaData.base, -1, BEV_OPT_CLOSE_ON_FREE);
        if (!bev) {
            break;
        }
        
        bufferevent_setcb(bev, usfnwtReadCb, usfnwtWriteCb, usfnwtEventCb, &globaData);
        bufferevent_enable(bev, EV_READ|EV_WRITE);
        
        if (globaData.ip.length()>0) {
            struct sockaddr_in sin;
            memset(&sin, 0, sizeof(sin));
            sin.sin_family = AF_INET;
            struct in_addr s;
            int rt =evutil_inet_pton(AF_INET, globaData.ip.c_str(), &s);
            if (rt!= 1) {
                bufferevent_free(bev);
                break;
            }
            sin.sin_addr =s;
            sin.sin_port = htons(globaData.port);
            
            rt =bufferevent_socket_connect(bev,
                                               (struct sockaddr *)&sin,
                                               sizeof(sin));
            if (rt!= 0) {
                bufferevent_free(bev);
                break;
            }
        } else {
            int rt =bufferevent_socket_connect_hostname(bev,
                                                globaData.dnsBase,
                                                AF_UNSPEC,
                                                globaData.host.c_str(),
                                                        globaData.port);
            if (rt!= 0) {
                bufferevent_free(bev);
                break;
            }
        }
        
        usfnwtSocketConnect(bev, globaData);
        res =0;
    }while(0);
    return res;
}

-(NSInteger) startLoop:(NSString *)hostOrIp port:(NSUInteger) port{
    if (hostOrIp.length <=0 ) {
        return -1;
    }
    
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(q,^{
        NSLog(@"startLoop");
        usfnwtGlobalData globaData;
        
        globaData.host =[hostOrIp cStringUsingEncoding:NSUTF8StringEncoding];
        globaData.port =(int)(port);
        
        struct event_base *base = event_base_new();
        globaData.base =base;

        struct evdns_base *dnsBase = evdns_base_new(base, 1);
        evdns_base_nameserver_ip_add(dnsBase, "114.114.114.114");
        evdns_base_nameserver_ip_add(dnsBase, "8.8.8.8");
        globaData.dnsBase =dnsBase;
        
        struct timeval intervalTimer = {100, 0};
        struct event *evTimer= event_new(base, -1, EV_PERSIST,
                                         usfnwtTimerCb, &globaData);
        event_add(evTimer, &intervalTimer);
        
        usfnwtConnectServer(globaData);
        
        event_base_dispatch(base);
        evdns_base_free(dnsBase, 1);
        event_base_free(base);
    });
    
    return 0;
}


@end
