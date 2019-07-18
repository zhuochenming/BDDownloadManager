//
//  BDDownloadUtility.m
//  BDDownloadManager
//
//  Created by 酌晨茗 on 18/9/24.
//  Copyright © 2018年 酌晨茗. All rights reserved.
//

#import "BDDownloadUtility.h"

@implementation BDDownloadUtility

+ (BOOL)isURLString:(NSString *)URLString {
    NSString *pattern = @"http(s)?://([\\w-]+\\.)+[\\w-]+(/[\\w- ./?%&=]*)?";
    NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:nil];
    NSArray *regularArray = [regular matchesInString:URLString options:0 range:NSMakeRange(0, URLString.length)];
    if (regularArray.count > 0) {
        return YES;
    } else {
        return NO;
    }
}

//+ (float)calculateFileSizeInUnit:(unsigned long long)contentLength {
//    if (contentLength >= pow(1024, 3)) {
//        return (float) (contentLength / (float)pow(1024, 3));
//    } else if(contentLength >= pow(1024, 2)) {
//        return (float) (contentLength / (float)pow(1024, 2));
//    } else if(contentLength >= 1024) {
//        return (float) (contentLength / (float)1024);
//    } else {
//        return (float) (contentLength);
//    }
//}
+ (float)calculateFileSizeInUnit:(unsigned long long)contentLength {
    double length = pow(1024, 3);
    if (contentLength >= length) {
        return (float)(contentLength / length);
    }
    
    length = pow(1024, 2);
    if (contentLength >= length) {
        return (float)(contentLength / length);
    }
    
    if (contentLength >= 1024) {
        return (float)(contentLength / 1024);
    } else {
        return (float) (contentLength);
    }
}

+ (NSString *)calculateUnit:(unsigned long long)contentLength {
    if (contentLength >= pow(1024, 3)) {
        return @"GB";
    } else if (contentLength >= pow(1024, 2)) {
        return @"MB";
    } else if (contentLength >= 1024) {
        return @"KB";
    } else {
        return @"Bytes";
    }
}

@end
