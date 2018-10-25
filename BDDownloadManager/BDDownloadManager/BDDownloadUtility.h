//
//  BDDownloadUtility.h
//  BDDownloadManager
//
//  Created by 酌晨茗 on 18/9/24.
//  Copyright © 2018年 酌晨茗. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BDDownloadUtility : NSObject

// 字符串是否是URL
+ (BOOL)isURLString:(NSString *)URLString;

// 返回文件大小
+ (float)calculateFileSizeInUnit:(unsigned long long)contentLength;

// 返回文件大小的单位
+ (NSString *)calculateUnit:(unsigned long long)contentLength;

@end
