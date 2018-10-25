//
//  BDDownloadModel.h
//  BDDownloadManager
//
//  Created by 酌晨茗 on 18/9/24.
//  Copyright © 2018年 酌晨茗. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDDownloadHeader.h"

@class BDDownloadProgress, BDDownloadModel;

// 进度更新block
typedef void (^BDDownloadProgressBlock)(id bindingData, BDDownloadProgress *progress);
// 状态更新block
typedef void (^BDDownloadStateBlock)(BDDownloadState state, NSString *filePath, NSError *error);

@interface BDDownloadModel : NSObject
// 下载地址
@property (nonatomic, strong, readonly) NSString *downloadURL;
// 文件名 默认nil 则为下载URL中的文件名
@property (nonatomic, strong, readonly) NSString *fileName;
// 缓存文件目录 默认nil 则为manger缓存目录
@property (nonatomic, strong, readonly) NSString *downloadDirectory;
// 下载路径 如果设置了downloadDirectory，文件下载完成后会移动到这个目录，否则，在manager默认cache目录里
@property (nonatomic, strong, readonly) NSString *filePath;

// 下载状态
@property (nonatomic, assign, readonly) BDDownloadState state;
// 下载任务
@property (nonatomic, strong, readonly) NSURLSessionTask *task;
// 文件流
@property (nonatomic, strong, readonly) NSOutputStream *stream;
// 下载进度
@property (nonatomic, strong ,readonly) BDDownloadProgress *progress;

// 下载进度更新block
@property (nonatomic, copy) BDDownloadProgressBlock progressBlock;
// 下载状态更新block
@property (nonatomic, copy) BDDownloadStateBlock stateBlock;

@property (nonatomic, strong) id bindingData;

/**
 初始化方法
 
 @param URLString 下载地址
 @param filePath  缓存地址 当为nil 默认缓存到cache
 */
- (instancetype)initWithURLString:(NSString *)URLString filePath:(NSString *)filePath;

@end



@interface BDDownloadProgress : NSObject

// 续传大小
@property (nonatomic, assign, readonly) int64_t resumeBytesWritten;
// 这次写入的数量
@property (nonatomic, assign, readonly) int64_t bytesWritten;
// 已下载的数量
@property (nonatomic, assign, readonly) int64_t totalBytesWritten;
// 文件的总大小
@property (nonatomic, assign, readonly) int64_t totalBytesExpectedToWrite;
// 下载进度
@property (nonatomic, assign, readonly) CGFloat progress;
// 下载速度
@property (nonatomic, assign, readonly) CGFloat speed;
// 下载剩余时间
@property (nonatomic, assign, readonly) NSInteger remainingTime;

@end
