//
//  stathttprequest.m
//  SSSTracker
//
//  Created by Denis Dvoryanchenko on 5/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "STATRHttpRequest.h"
#import "STATR.h"
#import "STATRConstants.h"


@interface STATRHttpRequest ()

- (NSString *)postDataToURL:(NSString *)urlString data:(NSData *)data;
- (NSStringEncoding)stringEncodingForTextEncodingName:(NSString *)encodingName;

@end

@implementation STATRHttpRequest


- (STATRHttpRequestResult)postToURL:(NSString *)URLString data:(NSData *)postData response:(NSString **)responseString
{
    STATRHttpRequestResult res;
    @try {
        *responseString = [self postDataToURL:URLString data:postData];
        res = STATRHttpRequestResultOk;
    }
    @catch (NSException *e) {
        *responseString = @"";
        res = STATRHttpRequestResultError;
        if ([[e name] isEqualToString:@"NSURLErrorDomain"])
            res = STATRRequestResultNoConnection;
        [[NSNotificationCenter defaultCenter] postNotificationName:kExceptionEventNotification object:[e name] userInfo:nil];
    }
    return res;
}

- (NSString *)postDataToURL:(NSString *)urlString data:(NSData *)data
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    [request setTimeoutInterval:kTimeoutInterval];

    NSError *error = nil;
    NSURLResponse *response = nil;
    NSData *resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if (error) {
        @throw [NSException exceptionWithName:[error domain] reason:@"Error when send request." userInfo:[error userInfo]];
    }

    if (response == nil) {
        return @"";
    }

    if (resultData == nil) {
        @throw [NSException exceptionWithName:@"Result is nil" reason:@"Error when send request." userInfo:[error userInfo]];
    }

    NSString *encodingName = [response textEncodingName];
    if (encodingName == nil) {
        encodingName = @"utf-8";
    }
    NSStringEncoding stringEncoding = [self stringEncodingForTextEncodingName:encodingName];

    NSString *string = [[NSString alloc] initWithData:resultData encoding:stringEncoding];

    if (!string) {
        NSLog(@"Can't get string from response");
        NSLog(@"%@\n%@", encodingName, string);
        [[NSNotificationCenter defaultCenter] postNotificationName:kExceptionEventNotification object:@"Can't get string from response" userInfo:nil];
        return @"";
    }

    if ([string length] == 0) {
        NSLog(@"String from response don't have any data");
        NSLog(@"%@\n%@", encodingName, string);
        [[NSNotificationCenter defaultCenter] postNotificationName:kExceptionEventNotification object:@"String from response don't have any data" userInfo:nil];
        return @"";
    }

    return string;
}

- (NSStringEncoding)stringEncodingForTextEncodingName:(NSString *)encodingName
{
    CFStringEncoding cfStringEncoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)encodingName);
    NSStringEncoding stringEncoding = CFStringConvertEncodingToNSStringEncoding(cfStringEncoding);
    return stringEncoding;
}

@end









