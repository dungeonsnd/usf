//
//  USFHttpTool.m
//  CurlT
//
//  Created by jeffery on 16/3/9.
//  Copyright © 2016年 jeffery. All rights reserved.
//

#import "USFHttpTool.h"

#import "curl.h"
#include <string>
using namespace std;

@implementation USFHttpTool


bool CurlInit(CURL *&curl, const char* url,string &content)
{
    CURLcode code;
    string error;
    curl = curl_easy_init();
    if (curl == NULL)
    {
        printf( "Failed to create CURL connection\n");
        return false;
    }
    code = curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, error);
    if (code != CURLE_OK)
    {
        printf( "Failed to set error buffer [%d]\n", code );
        return false;
    }
    curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);
    code = curl_easy_setopt(curl, CURLOPT_URL, url);
    if (code != CURLE_OK)
    {
        printf("Failed to set URL [%s]\n", error);
        return false;
    }
    code = curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1);
    if (code != CURLE_OK)
    {
        printf( "Failed to set redirect option [%s]\n", error );
        return false;
    }
    code = curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writer);
    if (code != CURLE_OK)
    {
        printf( "Failed to set writer [%s]\n", error);
        return false;
    }
    code = curl_easy_setopt(curl, CURLOPT_WRITEDATA, &content);
    if (code != CURLE_OK)
    {
        printf( "Failed to set write data [%s]\n", error );
        return false;
    }
    return true;
}

long writer(void *data, int size, int nmemb, string &content)
{
    long sizes = size * nmemb;
    string temp(data,sizes);
    content += temp;
    return sizes;
}

bool GetURLDataBycurl(const char* URL,  string &content)
{
    CURL *curl = NULL;
    CURLcode code;
    string error;
    
    code = curl_global_init(CURL_GLOBAL_DEFAULT);
    if (code != CURLE_OK)
    {
        printf( "Failed to global init default [%d]\n", code );
        return false;
    }
    
    if ( !CurlInit(curl,URL,content) )
    {
        printf( "Failed to global init default [%d]\n" );
        return PM_FALSE;
    }
    code = curl_easy_perform(curl);
    if (code != CURLE_OK)
    {
        printf( "Failed to get '%s' [%s]\n", URL, error);
        return false;
    }
    long retcode = 0;
    code = curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE , &retcode);
    if ( (code == CURLE_OK) && retcode == 200 )
    {
        double length = 0;
        code = curl_easy_getinfo(curl, CURLINFO_CONTENT_LENGTH_DOWNLOAD , &length);
        printf("%d",retcode);
        FILE * file = fopen("1.gif","wb");
        fseek(file,0,SEEK_SET);
        fwrite(content.c_str(),1,length,file);
        fclose(file);
        
        //struct curl_slist *list;
        //code = curl_easy_getinfo(curl,CURLINFO_COOKIELIST,&list);
        //curl_slist_free_all (list);
        
        return true;
    }
    else
    {
        //    debug1( "%s \n ",getStatusCode(retcode));
        return false;
    }
    curl_easy_cleanup(curl);
    return false;
}


@end
