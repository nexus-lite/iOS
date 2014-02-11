//
//  statxmlwriter.m
//  SSSTracker
//
//  Created by Denis Dvoryanchenko on 5/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "STATRXmlWriter.h"

NSString *kExceptionEventNotification = @"SSSExceptionEvent";
NSString *kTrackerSettingsReceived = @"SSSTrackerSettingsReceived";
NSString *kEventDataSentAndResponse = @"SSSEventDataSentAndResponse";
NSString *kManualDataSendIsPossibleAfterFailureNotification = @"SSSManualDataSendIsPossibleAfterFailureNotification";
NSString *kEventDataXML = @"SSSeventDataXML";
NSString *kResponseText = @"SSSresponseText";

@implementation STATRXmlWriter

- (id)init
{
    if ([super init]) {
        isOpen = false;
        elementsArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)writeElementStart:(NSString *)elementName
{
    if (isOpen) {
        [elementsArray addObject:@">"];
        [elementsArray addObject:@"\n"];
    }

    [elementsArray addObject:[NSString stringWithFormat:@"<%@", elementName]];
    isOpen = YES;
}


- (void)writeElementEnd:(NSString *)elementName
{
    if (isOpen) {
        [elementsArray addObject:@"/>"];
    }
    else {
        [elementsArray addObject:[NSString stringWithFormat:@"</%@>", elementName]];
    }

    [elementsArray addObject:@"\n"];
    isOpen = NO;
}


- (void)writeAttribute:(NSString *)attributeName value:(NSString *)attributeValue
{
    [elementsArray addObject:[NSString stringWithFormat:@" %@=\"%@\"", attributeName, [self encodeString:attributeValue]]];
}


- (NSString *)xmlString
{
    NSMutableString *result = [[NSMutableString alloc] init];
    for (NSString *i in elementsArray) {
        [result appendString:i];
    }

    return result;
}


- (STATRXmlWriter *)clean
{
    [elementsArray removeAllObjects];
    return self;
}


- (NSString *)encodeString:(NSString *)string
{
    NSMutableString *resultString = [[NSMutableString alloc] initWithString:string];

    [resultString replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0, [resultString length])];
    [resultString replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0, [resultString length])];
    [resultString replaceOccurrencesOfString:@"\\" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0, [resultString length])];
    [resultString replaceOccurrencesOfString:@"\'" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [resultString length])];

    return resultString;
}

@end
