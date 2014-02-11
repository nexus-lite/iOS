//
//  stathttprequest.h
//  SSSTracker
//
//  Created by Denis Dvoryanchenko on 5/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    STATRHttpRequestResultOk,
    STATRRequestResultNoConnection,
    STATRHttpRequestResultError
} STATRHttpRequestResult;

@interface STATRHttpRequest : NSObject

- (STATRHttpRequestResult)postToURL:(NSString *)URLString data:(NSData *)postData response:(NSString **)responseString;

@end
