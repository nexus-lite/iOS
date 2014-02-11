//
// Created by Yuriy Pavlyshak on 21.08.13.
//

#define MAX_PARAMETER_VALUE_LENGTH 255

#import "STATR.h"


@implementation STATREventParameter
@synthesize name =_name, value =_value;


- (id)initWithName:(NSString *)name value:(NSString *)value type:(STATRParameterType)type
{
    if (self = [super init]) {
        _name = name;
        if ([value length] > MAX_PARAMETER_VALUE_LENGTH ) {
            _value = [value substringToIndex:MAX_PARAMETER_VALUE_LENGTH];
        } else {
            _value = value;
        }
        _type = type;
    }

    return self;
}

- (NSString *)typeAsString
{
    NSString *res;
    switch (_type) {
        case STATRParameterTypeText:
            res = @"text";
            break;

        case STATRParameterTypeNumeric:
            res = @"numeric";
            break;

        case STATRParameterTypeError:
            res = @"error";
            break;

        case STATRParameterTypeLog:
            res = @"log";
            break;

        default:
            res = @"";
    }
    return res;
}

@end