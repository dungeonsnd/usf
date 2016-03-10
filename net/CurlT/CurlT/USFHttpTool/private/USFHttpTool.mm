//
//  USFHttpTool.m
//  CurlT
//
//  Created by jeffery on 16/3/9.
//  Copyright © 2016年 jeffery. All rights reserved.
//

#import "USFHttpTool.h"

#import "curl.h"

@implementation USFHttpTool

#include <string>
#include "curl.h"


static size_t writecb(void *contents, size_t size, size_t nmemb, void *userp)
{
    size_t realsize = size * nmemb;
    std::string *mem = (std::string *)userp;
    *mem +=std::string((char*)(contents), realsize);
    return realsize;
}


- (NSInteger) HttpGet:(NSString *)nsurl result:(NSString **)nsresult out_errstr:(NSString **)nsout_errstr{
    
    std::string result;
    std::string out_errstr;
    const std::string url =[nsurl UTF8String];
    
    curl_global_init(CURL_GLOBAL_ALL);
    
    long httpRetCode =-1;
    out_errstr.assign(CURL_ERROR_SIZE,'\0');
    do
    {
        NSLog(@"Enter HttpGet");
        
        CURLcode urlcode;
        CURL * curl =curl_easy_init();
        if(NULL==curl)
        {
            NSLog(@"HttpGet, curl_easy_init failed! \n");
            break;
        }
        
        urlcode =curl_easy_setopt(curl,CURLOPT_VERBOSE, 0);
        if(urlcode!=CURLE_OK)
        {
            NSLog(@"HttpGet, curl_easy_setopt CURLOPT_VERBOSE failed,urlcode=%d",int(urlcode));
            break;
        }
        
        urlcode =curl_easy_setopt(curl,CURLOPT_ERRORBUFFER,&out_errstr[0]);
        if(urlcode!=CURLE_OK)
        {
            NSLog(@"HttpGet, curl_easy_setopt CURLOPT_ERRORBUFFER failed,urlcode=%d",int(urlcode));
            break;
        }
        
        urlcode =curl_easy_setopt(curl,CURLOPT_NOSIGNAL,1);
        if(urlcode!=CURLE_OK)
        {
            NSLog(@"HttpGet, curl_easy_setopt CURLOPT_NOSIGNAL failed,urlcode=%d,%s", int(urlcode),curl_easy_strerror(urlcode));
            break;
        }
        
        urlcode =curl_easy_setopt(curl,CURLOPT_CONNECTTIMEOUT,12);
        if(urlcode!=CURLE_OK)
        {
            NSLog(@"HttpGet, curl_easy_setopt CURLOPT_CONNECTTIMEOUT failed,urlcode=%d,%s",
                  int(urlcode),curl_easy_strerror(urlcode));
            break;
        }
        
        urlcode =curl_easy_setopt(curl,CURLOPT_TIMEOUT,30);
        if(urlcode!=CURLE_OK)
        {
            NSLog(@"HttpGet, curl_easy_setopt CURLOPT_TIMEOUT failed,urlcode=%d,%s",
                  int(urlcode),curl_easy_strerror(urlcode));
            break;
        }
        
        /* example.com is redirected, so we tell libcurl to follow redirection */
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
        
        urlcode =curl_easy_setopt(curl,CURLOPT_URL,url.c_str());
        if(urlcode!=CURLE_OK)
        {
            NSLog(@"HttpGet, curl_easy_setopt CURLOPT_URL failed,urlcode=%d,%s",
                   int(urlcode),curl_easy_strerror(urlcode));
            break;
        }
        
        /* send all data to this function  */
        urlcode =curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writecb);
        if(urlcode!=CURLE_OK)
        {
            NSLog(@"HttpGet, curl_easy_setopt CURLOPT_WRITEFUNCTION failed,urlcode=%d,%s",
                  int(urlcode),curl_easy_strerror(urlcode));
            break;
        }
        
        /* we pass our 'chunk' struct to the callback function */
        urlcode =curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)(&result));
        if(urlcode!=CURLE_OK)
        {
            NSLog(@"HttpGet, curl_easy_setopt CURLOPT_WRITEDATA failed,urlcode=%d,%s \n",
                  int(urlcode),curl_easy_strerror(urlcode));
            break;
        }
        
        /* some servers don't like requests that are made without a user-agent
         field, so we provide one */
        urlcode =curl_easy_setopt(curl, CURLOPT_USERAGENT, "libcurl-agent/1.0");
        if(urlcode!=CURLE_OK)
        {
            NSLog(@"HttpGet, curl_easy_setopt CURLOPT_USERAGENT failed,urlcode=%d,%s \n",
                  int(urlcode),curl_easy_strerror(urlcode));
            break;
        }
        
        
        urlcode =curl_easy_perform(curl);
        if(urlcode!=CURLE_OK)
        {
            NSLog(@"HttpGet, curl_easy_perform failed,urlcode=%d,%s \n",
                   int(urlcode),curl_easy_strerror(urlcode));
            break;
        }
        
        urlcode =curl_easy_getinfo(curl,CURLINFO_RESPONSE_CODE,&httpRetCode);
        if(urlcode!=CURLE_OK)
        {
            NSLog(@"HttpGet, curl_easy_getinfo CURLINFO_RESPONSE_CODE failed,urlcode=%d,%s \n",
                  int(urlcode),curl_easy_strerror(urlcode));
            break;
        }
        
        NSLog(@"http server return code:%ld , result.size=%d",
              httpRetCode, (int)(result.size()));
        
        curl_easy_cleanup(curl);
    }while(0);
    
    
    *nsresult =[[NSString alloc] initWithBytes:result.c_str() length:result.size() encoding:NSUTF8StringEncoding];
    *nsout_errstr =[[NSString alloc] initWithBytes:out_errstr.c_str() length:out_errstr.size() encoding:NSUTF8StringEncoding];
    
    /* we're done with libcurl, so clean it up */
    curl_global_cleanup();
    return httpRetCode;
}

@end
