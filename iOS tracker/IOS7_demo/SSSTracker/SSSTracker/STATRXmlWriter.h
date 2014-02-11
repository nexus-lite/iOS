//
//  statxmlwriter.h
//  SSSTracker
//
//  Created by Denis Dvoryanchenko on 5/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STATRConstants.h"
#import "STATR.h"

@interface STATRXmlWriter : NSObject
{
    NSMutableArray *elementsArray;
    BOOL isOpen;
}

- (void)writeElementStart:(NSString *)elementName;
- (void)writeElementEnd:(NSString *)elementName;
- (void)writeAttribute:(NSString *)attributeName value:(NSString *)attributeValue;
- (NSString *)xmlString;
- (STATRXmlWriter *)clean;


@end


