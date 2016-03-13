//
//  USFJsonTool.m
//  rapidjsonT
//
//  Created by jeffery on 16/3/13.
//  Copyright © 2016年 jeffery. All rights reserved.
//

#import "USFJsonTool.h"

#include "rapidjson/document.h"
using namespace rapidjson;

@implementation USFJsonTool

-(void) parse:(NSString*) jsonStr{
    
    const char * json =[jsonStr cStringUsingEncoding:NSUTF8StringEncoding];
    Document document;
    document.Parse(json);
    
    if(!document.HasMember("hello"))
        return;
    if(!document["hello"].IsString())
        return;
    printf("hello = %s\n", document["hello"].GetString());
    printf("n = %s\n", document["n"].IsNull() ? "null" : "?");
    
    // 使用引用来连续访问，方便之余还更高效。
    const Value& a = document["a"];
    if(!a.IsArray())
        return;
    for (SizeType i = 0; i < a.Size(); i++) // 使用 SizeType 而不是 size_t
        printf("a[%d] = %d\n", i, a[i].GetInt());
}

@end
