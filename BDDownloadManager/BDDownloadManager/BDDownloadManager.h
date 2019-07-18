//
//  BDDownloadManager.h
//  BDDownloadManager
//
//  Created by 酌晨茗 on 18/9/24.
//  Copyright © 2018年 酌晨茗. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDDownloadModel.h"
#import "BDDownloadHeader.h"

@interface BDDownloadManager : NSObject <NSURLSessionDataDelegate>

// 下载中的模型 只读
@property (nonatomic, strong, readonly) NSMutableArray *downloadingModels;
// 等待中的模型 只读
@property (nonatomic, strong, readonly) NSMutableArray *waitingDownloadModels;

// 最大下载数
@property (nonatomic, assign) NSInteger maxDownloadCount;

// 是否支持后台下载 默认YES
@property (nonatomic, assign) BOOL isBackgroundDownload;

// 等待下载队列 先进先出 默认YES， 当NO时，先进后出
@property (nonatomic, assign) BOOL resumeDownloadFIFO;

// 全部并发 默认NO, 当YES时，忽略maxDownloadCount
@property (nonatomic, assign) BOOL isBatchDownload;



/** 初始化单例 */
+ (BDDownloadManager *)manager;



/**
 框架的开始下载、暂停、继续下载、取消下载都基于由此获得的下载模型，即使使用过程中程序被杀死，依旧可以通过此方法获取某个下载URL的进度等信息

 @param URLString 下载URL
 @param destinationPath 下载文件路径
 @return 模型
 */
- (BDDownloadModel *)modelWithURLString:(NSString *)URLString toDestinationPath:(NSString *)destinationPath;



/**
 开始下载 保存在默认文件路径 里(复用机制请用通知，在cell里面处理进度等UI刷新)

 @param model 下载model
 @param progress 进度model
 @param state 下载状态
 */
- (void)startModel:(BDDownloadModel *)model progress:(BDDownloadProgressBlock)progress state:(BDDownloadStateBlock)state;
/** 开始下载 */
- (void)startModel:(BDDownloadModel *)model;

/** 暂停下载 */
- (void)suspendModel:(BDDownloadModel *)model;

/** 恢复下载（除非确定对这个model进行了suspend，否则使用start）*/
- (void)resumeModel:(BDDownloadModel *)model;

/** 取消下载 */
- (void)cancleModel:(BDDownloadModel *)model;
- (void)cancleModels:(NSArray <BDDownloadModel *>*)models;
- (void)cancleAllDownload;



/** 当前的URL下载状态 */
- (BDDownloadState)stateWithModel:(BDDownloadModel *)model;
/** 获取正在下载模型 */
- (BDDownloadModel *)downLoadingModelForURLString:(NSString *)URLString;
/** 当前的URL是否正在下载 */
- (BOOL)isDownloadingURL:(NSString *)url;
/** 当前的URL是否在等待下载 */
- (BOOL)isWaitingDownloadURL:(NSString *)url;
/** 当前的URL是否在下载队列里 */
- (BOOL)isQueueURL:(NSString *)url;
/** 是否已经下载 */
- (BOOL)isDownloadCompletedWithModel:(BDDownloadModel *)model;



/** 删除下载的文件 */
- (void)deleteFileWithURLString:(NSString *)URLString filePath:(NSString *)filePath;
- (void)deleteFileWithModel:(BDDownloadModel *)model;
- (void)deleteAllFileInDirectory:(NSString *)downloadDic;

@end
