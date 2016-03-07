//
//  USFDBTool.m
//  SQLLiteTest
//
//  Created by jeffery on 16/3/7.
//  Copyright © 2016年 jeffery. All rights reserved.
//

#import "USFDBTool.h"

#include "sqlite3.h"  

@implementation USFDBTool

typedef struct tagUSFDBTOOL_Per
{
    char *name;
    int age;
    char *sex;
} USFDBTOOL_Per;

USFDBTOOL_Per USFDBTOOL_a[] = {
    "David",22,"man",
    "Eve",28,"man",
    "Frand",21,"woman"
};

// 这个函数可以用来打印出每行的信息
static int callback(void *NotUsed, int argc, char **argv, char **azColName){
    int i;
    for(i=0; i<argc; i++){
        NSLog(@"%s = %s\n", azColName[i], argv[i] ? argv[i] : "NULL");
    }
    NSLog(@"\n");
    return 0;
}

- (void) createDB:(NSString*) filename{
    const char * f =[filename cStringUsingEncoding:NSUTF8StringEncoding];
    sqlite3 *pdb;
    int nRet = sqlite3_open(f,&pdb);
    if(SQLITE_OK != nRet){
        NSLog(@"sqlite3_open failed!");
        return;
    }
    
    do{
        // 创建表
        const char *sql = "CREATE TABLE IF NOT EXISTS person(name VARCHAR(128),"
        "age INTEGER,"
        "sex VARCHAR(7)"
        ");";
        char *zErrMsg;
        nRet = sqlite3_exec(pdb,sql,NULL,NULL,&zErrMsg);
        if (SQLITE_OK != nRet)
        {
            NSLog(@"CREATE TABLE failed! %s",zErrMsg);
            break;
        }
        
        sql = "DELETE  FROM person;";
        nRet = sqlite3_exec(pdb,sql,NULL,NULL,&zErrMsg);
        if (SQLITE_OK != nRet)
        {
            NSLog(@"DELETE failed! %s",zErrMsg);
            break;
        }
        
        // 使用sqlite3_exec() 插入数据
        sql = "INSERT INTO person(name,age,sex) VALUES(\"Alice\",15,\"woman\");";
        nRet = sqlite3_exec(pdb,sql,NULL,NULL,&zErrMsg);
        if (SQLITE_OK != nRet)
        {
            NSLog(@"INSERT Alice failed! %s",zErrMsg);
            break;
        }
        
        sql = "INSERT INTO person(name,age,sex) VALUES(\"Bob\",18,\"man\");";
        nRet = sqlite3_exec(pdb,sql,NULL,NULL,&zErrMsg);
        if (SQLITE_OK != nRet)
        {
            NSLog(@"INSERT Bob failed! %s",zErrMsg);
            break;
        }
        
        
        int age;
        int nCol;
        sqlite3_stmt *pstmt;
        const unsigned char *pTmp;
        const char *pzTail;
        
        // 使用sqlite3_prepare_v2(), sqlite3_bind_...() 插入数据
        sql = "INSERT INTO person(name,age,sex) VALUES(?,?,?);";
        nRet = sqlite3_prepare_v2(pdb,sql,(int)(strlen(sql)),&pstmt,&pzTail);
        if (SQLITE_OK != nRet)
        {
            NSLog(@"sqlite3_prepare_v2 failed!");
            break;
        }
        
        int i;
        for (i=0;i<sizeof(USFDBTOOL_a)/sizeof(USFDBTOOL_Per);i++)
        {
            nCol = 1;
            sqlite3_bind_text(pstmt,nCol++,USFDBTOOL_a[i].name,(int)(strlen(USFDBTOOL_a[i].name)),NULL);
            sqlite3_bind_int(pstmt,nCol++,USFDBTOOL_a[i].age);
            sqlite3_bind_text(pstmt,nCol++,USFDBTOOL_a[i].sex,(int)(strlen(USFDBTOOL_a[i].sex)),NULL);
            
            sqlite3_step(pstmt);
            sqlite3_reset(pstmt);
        }  
        
        sqlite3_finalize(pstmt);
        
        
        // 使用sqlite3_exec() 查询数据
        NSLog(@"=====query by sqlite3_exec()=====\n");
        sql = "SELECT name,age,sex FROM person;";
        nRet = sqlite3_exec(pdb,sql,callback,NULL,&zErrMsg);
        if (SQLITE_OK != nRet)
        {
            NSLog(@"SELECT Bob failed! %s",zErrMsg);
            break;
        }
        
        // 使用sqlite3_prepare_v2(), sqlite3_column_...() 查询数据
        
        NSLog(@"====== query by sqlite3_prepare_v2()======\n");
        sql = "SELECT name,age,sex FROM person;";
        nRet = sqlite3_prepare_v2(pdb,sql,(int)(strlen(sql)),&pstmt,&pzTail);
        if (SQLITE_OK != nRet)
        {
            NSLog(@"sqlite3_prepare_v2 failed!");
            break;
        }
        
        while(1)
        {
            nRet = sqlite3_step(pstmt);
            if (SQLITE_DONE == nRet)
            {
                sqlite3_finalize(pstmt);
                break;
            }
            if (SQLITE_ROW == nRet)
            {
                nCol = 0;
                pTmp = sqlite3_column_text(pstmt,nCol++);
                printf("%s|",pTmp);
                
                age = sqlite3_column_int(pstmt,nCol++);
                printf("%d|",age);
                
                pTmp = sqlite3_column_text(pstmt,nCol++);
                printf("%s\n",pTmp);
                
                continue;  
            }  
            
            NSLog(@"something error!");
            sqlite3_finalize(pstmt);  
            break;  
        }
    }while (0);
    
    sqlite3_close(pdb);
}




@end
