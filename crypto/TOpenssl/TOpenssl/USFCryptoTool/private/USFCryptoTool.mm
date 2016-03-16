//
//  USFCryptoTool.m
//  TOpenssl
//
//  Created by mxw on 16/3/16.
//  Copyright © 2016年 mtzijin. All rights reserved.
//

#import "USFCryptoTool.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <openssl/aes.h>

#include <openssl/evp.h>

#include <openssl/md5.h>
#include <openssl/sha.h>

@implementation USFCryptoTool


/*
 len=16
 encrypted string =ae0a18944d22e0685d415a821a93679d
 decrypted string =abcdabcdabcdabcd
 */


- (NSInteger) AEST
{
    AES_KEY aes;
    unsigned char key[AES_BLOCK_SIZE];        // AES_BLOCK_SIZE = 16
    unsigned char iv[AES_BLOCK_SIZE];        // init vector
    unsigned char* input_string;
    unsigned char* encrypt_string;
    unsigned char* decrypt_string;
    unsigned int len;        // encrypt length (in multiple of AES_BLOCK_SIZE)
    unsigned int i;
    
    
    const char * plainText ="abcdabcdabcdabcd";
    
    // set the encryption length
    len = strlen(plainText);
    printf("len=%d \n", len);
    
    // set the input string
    input_string = (unsigned char*)calloc(len, sizeof(unsigned char));
    if (input_string == NULL) {
        fprintf(stderr, "Unable to allocate memory for input_string\n");
        exit(-1);
    }
    //padding! Important!
    memset( input_string,len-strlen(plainText),len );
    strncpy((char*)input_string, plainText, strlen(plainText));
    
    
    // Generate AES 128-bit key
    memset(key, 'a', AES_BLOCK_SIZE);
    
    // Set encryption key
    memset(iv, 'x', AES_BLOCK_SIZE);
    if (AES_set_encrypt_key(key, 128, &aes) < 0) {
        fprintf(stderr, "Unable to set encryption key in AES\n");
        exit(-1);
    }
    
    // alloc encrypt_string
    encrypt_string = (unsigned char*)calloc(len, sizeof(unsigned char));
    if (encrypt_string == NULL) {
        fprintf(stderr, "Unable to allocate memory for encrypt_string\n");
        exit(-1);
    }
    
    // encrypt (iv will change)
    AES_cbc_encrypt(input_string, encrypt_string, len, &aes, iv, AES_ENCRYPT);
    
    /////////////////////////////////////
    
    // alloc decrypt_string
    decrypt_string = (unsigned char*)calloc(len+1, sizeof(unsigned char));
    if (decrypt_string == NULL) {
        fprintf(stderr, "Unable to allocate memory for decrypt_string\n");
        exit(-1);
    }
    memset(decrypt_string, 0, len+1);
    
    // Set decryption key
    memset(iv, 'x', AES_BLOCK_SIZE);
    if (AES_set_decrypt_key(key, 128, &aes) < 0) {
        fprintf(stderr, "Unable to set decryption key in AES\n");
        exit(-1);
    }
    
    // decrypt
    AES_cbc_encrypt(encrypt_string, decrypt_string, len, &aes, iv,
                    AES_DECRYPT);
    
    // print
    //    printf("input_string =%s\n", input_string);
    printf("encrypted string =");
    for (i=0; i<len; ++i) {
        printf("%02x", (unsigned char)(encrypt_string[i]));
    }
    printf("\n");
    printf("decrypted string =");
    printf("%s\n", decrypt_string);
    
    
    
    return 0;
}

/**
 * Use EVP to Base64 encode the input byte array to readable text
 */
char* base64(const unsigned char *inputBuffer, int inputLen)
{
    EVP_ENCODE_CTX	ctx;
    int base64Len = (((inputLen+2)/3)*4) + 1; // Base64 text length
    int pemLen = base64Len + base64Len/64; // PEM adds a newline every 64 bytes
    char* base64 = new char[pemLen];
    int result;
    EVP_EncodeInit(&ctx);
    EVP_EncodeUpdate(&ctx, (unsigned char *)base64, &result, (unsigned char *)inputBuffer, inputLen);
    EVP_EncodeFinal(&ctx, (unsigned char *)&base64[result], &result);
    return base64;
}

/**
 * Use EVP to Base64 decode the input readable text to original bytes
 */
unsigned char* unbase64(char *input, int length, int* outLen)
{
    EVP_ENCODE_CTX	ctx;
    int orgLen = (((length+2)/4)*3) + 1;
    unsigned char* orgBuf = new unsigned char[orgLen];
    int result, tmpLen;
    EVP_DecodeInit(&ctx);
    EVP_DecodeUpdate(&ctx, (unsigned char *)orgBuf, &result, (unsigned char *)input, length);
    EVP_DecodeFinal(&ctx, (unsigned char *)&orgBuf[result], &tmpLen);
    result += tmpLen;
    *outLen = result;
    return orgBuf;
}

- (NSInteger) BASE64T
{
    unsigned char inputBuffer[] ="ab·Ç";
    int inputLen =strlen((char*)inputBuffer);
    char* b64 =base64(inputBuffer, inputLen);
    printf("%s",b64);
    
    int length =strlen(b64);
    int outLen;
    unsigned char* unb64 =unbase64(b64, length, &outLen);
    printf("%s\n",unb64);
    return 0;
}

- (NSInteger) HASHT
{
    unsigned char	in[]="3dsferyewyrtetegvbzVEgarhaggavxcv";
    unsigned char	out[128] ={0};
    size_t			n;
    int				i;
    
    n=strlen((const char*)in);
    
    MD5(in,n,out);
    printf("\n\nMD5 digest result :\n");
    for(i=0;i<16;i++)
        printf("%x ",out[i]);
    
    SHA(in,n,out);
    printf("\n\nSHA digest result :\n");
    for(i=0;i<20;i++)
        printf("%x ",out[i]);
    
    SHA1(in,n,out);
    printf("\n\nSHA1 digest result :\n");
    for(i=0;i<20;i++)
        printf("%x ",out[i]);
    
    SHA256(in,n,out);
    printf("\n\nSHA256 digest result :\n");
    for(i=0;i<32;i++)
        printf("%x ",out[i]);
    
    SHA512(in,n,out);
    printf("\n\nSHA512 digest result :\n");
    for(i=0;i<64;i++)
        printf("%x ",out[i]);
    printf("\n");
    return 0;
}

@end
