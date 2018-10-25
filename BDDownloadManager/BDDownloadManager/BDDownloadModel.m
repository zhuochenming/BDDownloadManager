//
//  BDDownloadModel.m
//  BDDownloadManager
//
//  Created by 酌晨茗 on 18/9/24.
//  Copyright © 2018年 酌晨茗. All rights reserved.
//

#import "BDDownloadModel.h"

@interface BDDownloadProgress ()
// 续传大小
@property (nonatomic, assign) int64_t resumeBytesWritten;
// 这次写入的数量
@property (nonatomic, assign) int64_t bytesWritten;
// 已下载的数量
@property (nonatomic, assign) int64_t totalBytesWritten;
// 文件的总大小
@property (nonatomic, assign) int64_t totalBytesExpectedToWrite;
// 下载进度
@property (nonatomic, assign) CGFloat progress;
// 下载速度
@property (nonatomic, assign) CGFloat speed;
// 下载剩余时间
@property (nonatomic, assign) NSInteger remainingTime;

@end

@interface BDDownloadModel ()
// 下载地址
@property (nonatomic, strong) NSString *downloadURL;
// 文件名 默认nil 则为下载URL中的文件名
@property (nonatomic, strong) NSString *fileName;
// 缓存文件目录 默认nil 则为manger缓存目录
@property (nonatomic, strong) NSString *downloadDirectory;
// 下载状态
@property (nonatomic, assign) BDDownloadState state;
// 下载任务
@property (nonatomic, strong) NSURLSessionTask *task;
// 文件流
@property (nonatomic, strong) NSOutputStream *stream;
// 下载文件路径,下载完成后有值,把它移动到你的目录
@property (nonatomic, strong) NSString *filePath;
// 下载时间
@property (nonatomic, strong) NSDate *downloadDate;
// 断点续传需要设置这个数据 
@property (nonatomic, strong) NSData *resumeData;
// 手动取消当做暂停
@property (nonatomic, assign) BOOL manualCancle;

@end

@implementation BDDownloadModel

- (instancetype)init {
    if (self = [super init]) {
        _progress = [[BDDownloadProgress alloc] init];
    }
    return self;
}

- (instancetype)initWithURLString:(NSString *)URLString filePath:(NSString *)filePath {
    if (self = [self init]) {
        _downloadURL = URLString;
        if (filePath.length == 0) {
            _fileName = _downloadURL.lastPathComponent;
            _downloadDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:kDefaultCacheDirectory];
            _filePath = [self.downloadDirectory stringByAppendingPathComponent:self.fileName];
        } else {
            _fileName = filePath.lastPathComponent;
            _downloadDirectory = filePath.stringByDeletingLastPathComponent;
            _filePath = filePath;
        }
    }
    return self;
}

@end



@implementation BDDownloadProgress

@end
