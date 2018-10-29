//
//  BDDownloadManager.m
//  BDDownloadManager
//
//  Created by 酌晨茗 on 18/9/24.
//  Copyright © 2018年 酌晨茗. All rights reserved.
//

#import "BDDownloadManager.h"
#import "BDDownloadUtility.h"

@interface BDDownloadModel ()

// 下载状态
@property (nonatomic, assign) BDDownloadState state;
// 下载任务
@property (nonatomic, strong) NSURLSessionDataTask *task;
// 文件流
@property (nonatomic, strong) NSOutputStream *stream;
// 下载文件路径
@property (nonatomic, strong) NSString *filePath;
// 下载时间
@property (nonatomic, strong) NSDate *downloadDate;
// 手动取消当做暂停
@property (nonatomic, assign) BOOL manualCancle;

@end



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


@interface BDDownloadManager ()
// 文件管理
@property (nonatomic, strong) NSFileManager *fileManager;
// 缓存文件目录
@property (nonatomic, strong) NSString *downloadDirectory;

// 下载seesion会话
@property (nonatomic, strong) NSURLSession *session;
// 下载模型字典 key = url
@property (nonatomic, strong) NSMutableDictionary *downloadingModelDic;
// 下载中的模型
@property (nonatomic, strong) NSMutableArray *waitingDownloadModels;
// 等待中的模型
@property (nonatomic, strong) NSMutableArray *downloadingModels;
// 回调代理的队列
@property (nonatomic, strong) NSOperationQueue *queue;
// 后台任务标识
@property (nonatomic, assign) UIBackgroundTaskIdentifier taskIdentifier;

@end

@implementation BDDownloadManager

- (void)dealloc {
    self.isBackgroundDownload = NO;
}

#pragma mark - 初始化
+ (BDDownloadManager *)manager {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.fileManager = [NSFileManager defaultManager];
        self.downloadDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:kDefaultCacheDirectory];
        [self createDirectory:_downloadDirectory];

        //下载线程
        self.maxDownloadCount = 1;
        self.isBackgroundDownload = YES;
        
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = _maxDownloadCount;
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:_queue];
        
        self.downloadingModelDic = [NSMutableDictionary dictionary];
        self.downloadingModels = [NSMutableArray array];
        self.waitingDownloadModels = [NSMutableArray array];
        
        self.resumeDownloadFIFO = YES;
        self.isBatchDownload = NO;
    }
    return self;
}

- (void)setMaxDownloadCount:(NSInteger)maxDownloadCount {
    _maxDownloadCount = maxDownloadCount;
    self.queue.maxConcurrentOperationCount = maxDownloadCount;
}

- (void)setIsBackgroundDownload:(BOOL)isBackgroundDownload {
    if (isBackgroundDownload) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundDownload) name:UIApplicationDidEnterBackgroundNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
}

#pragma mark - 下载状态以及model
// 获取下载模型
- (BDDownloadModel *)modelWithURLString:(NSString *)URLString toDestinationPath:(NSString *)destinationPath {
    
    //如果不是URL链接 返回nil
    if (![BDDownloadUtility isURLString:URLString]) {
        return nil;
    }

    BDDownloadModel *model = [self downLoadingModelForURLString:URLString];
    if (!model) {
        model = [[BDDownloadModel alloc] initWithURLString:URLString filePath:destinationPath];
        model.progress.totalBytesExpectedToWrite = [self fileSizeInCachePlistWithDownloadModel:model];
        model.progress.totalBytesWritten = MIN([self fileSizeWithDownloadModel:model], model.progress.totalBytesExpectedToWrite);
        model.progress.progress = model.progress.totalBytesExpectedToWrite > 0 ? 1.0 * model.progress.totalBytesWritten / model.progress.totalBytesExpectedToWrite : 0;
        model.state = [self stateWithModel:model];
        // 创建目录
        [self createDirectory:model.downloadDirectory];
    }
    return model;
}

- (BDDownloadModel *)downLoadingModelForURLString:(NSString *)URLString {
    return [self.downloadingModelDic objectForKey:URLString];
}

- (BDDownloadState)stateWithModel:(BDDownloadModel *)model {
    if (![BDDownloadUtility isURLString:model.downloadURL]) {
        return BDDownloadStateFailed;
    }
    
    NSString *url = model.downloadURL;
    BDDownloadModel *downloadModel = self.downloadingModelDic[url];
    if (downloadModel) {
        return downloadModel.state;
    }
    
    BDDownloadManager *manager = [BDDownloadManager manager];
    BDDownloadProgress *progress = model.progress;
    if (progress.totalBytesWritten == 0) {
        if ([manager isQueueURL:url]) {
            return BDDownloadStateReadying;
        } else {
            return BDDownloadStateNone;
        }
    } else if (progress.totalBytesWritten == progress.totalBytesExpectedToWrite) {
        return BDDownloadStateCompleted;
    } else {
        if ([manager isDownloadingURL:url]) {
            return BDDownloadStateRunning;
        } else if ([manager isWaitingDownloadURL:url]) {
            return BDDownloadStateReadying;
        } else {
            return BDDownloadStateSuspended;
        }
    }
}

- (BOOL)isDownloadingURL:(NSString *)url {
    if (url.length == 0) {
        return NO;
    }
    for (NSInteger i = 0; i < _downloadingModels.count; i++) {
        BDDownloadModel *model = _downloadingModels[i];
        if ([model.downloadURL isEqualToString:url]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isWaitingDownloadURL:(NSString *)url {
    if (url.length == 0) {
        return NO;
    }
    
    for (NSInteger i = 0; i < _waitingDownloadModels.count; i++) {
        BDDownloadModel *model = _waitingDownloadModels[i];
        if ([model.downloadURL isEqualToString:url]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isQueueURL:(NSString *)url {
    return [self isDownloadingURL:url] | [self isWaitingDownloadURL:url];
}

// 是否已经下载
- (BOOL)isDownloadCompletedWithModel:(BDDownloadModel *)downloadModel {
    long long fileSize = [self fileSizeInCachePlistWithDownloadModel:downloadModel];
    if (fileSize > 0 && fileSize == [self fileSizeWithDownloadModel:downloadModel]) {
        return YES;
    }
    return NO;
}

#pragma mark - 下载相关
- (void)startModel:(BDDownloadModel *)model progress:(BDDownloadProgressBlock)progress state:(BDDownloadStateBlock)state {
    model.progressBlock = progress;
    model.stateBlock = state;
    [self startModel:model];
}
- (void)startModel:(BDDownloadModel *)model {
    if (!model) {
        return;
    }
    
    if (model.state == BDDownloadStateReadying) {
        [self model:model didChangedState:BDDownloadStateReadying filePath:nil error:nil];
        return;
    }
    
    // 验证是否已经下载文件
    if ([self isDownloadCompletedWithModel:model]) {
        [self model:model didChangedState:BDDownloadStateCompleted filePath:model.filePath error:nil];
        return;
    }
    
    // 验证是否存在
    if (model.task && model.task.state == NSURLSessionTaskStateRunning) {
        [self model:model didChangedState:BDDownloadStateRunning filePath:nil error:nil];
        return;
    }
    
    //保护措施 并不直接添加model
    [self resumeModel:model];
}

// 恢复下载
- (void)resumeModel:(BDDownloadModel *)model {
    if (!model) {
        [self model:model didChangedState:BDDownloadStateFailed filePath:nil error:nil];
        return;
    }
    
    if (![self canResumeDownlaodModel:model]) {
        [self model:model didChangedState:BDDownloadStateFailed filePath:nil error:nil];
        return;
    }
    
    // 如果task 不存在 或者 取消了
    if (!model.task || model.task.state == NSURLSessionTaskStateCanceling) {
        NSString *URLString = model.downloadURL;
        
        // 创建请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
        
        // 设置请求头
        NSString *range = [NSString stringWithFormat:@"bytes=%lld-", [self fileSizeWithDownloadModel:model]];
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        // 创建流
        model.stream = [NSOutputStream outputStreamToFileAtPath:model.filePath append:YES];
        
        model.downloadDate = [NSDate date];
        self.downloadingModelDic[model.downloadURL] = model;
        // 创建一个Data任务
        model.task = [self.session dataTaskWithRequest:request];
        model.task.taskDescription = URLString;
    }
    
    [model.task resume];
    model.manualCancle = NO;
    [self model:model didChangedState:BDDownloadStateRunning filePath:nil error:nil];
}

// 暂停下载
- (void)suspendModel:(BDDownloadModel *)model {
    if (!model.manualCancle) {
        model.manualCancle = YES;
    }
    [model.task suspend];
    [self model:model didChangedState:BDDownloadStateSuspended filePath:model.filePath error:nil];
}

// 取消下载
- (void)cancleModel:(BDDownloadModel *)model {
    if (!model.task && model.state == BDDownloadStateReadying) {
        [self removeDownLoadingModelForURLString:model.downloadURL];
        [self.downloadingModels removeObject:model];
        [self.waitingDownloadModels removeObject:model];
        [model.task cancel];
        [self model:model didChangedState:BDDownloadStateNone filePath:nil error:nil];
        return;
    }
    
    if (model.state != BDDownloadStateCompleted && model.state != BDDownloadStateFailed) {
        [model.task cancel];
        [self model:model didChangedState:BDDownloadStateNone filePath:nil error:nil];
    }
}
- (void)cancleModels:(NSArray *)models {
    for (NSInteger i = 0; i < models.count; i++) {
        BDDownloadModel *model = models[i];
        [self cancleModel:model];
    }
}
- (void)cancleAllDownload {
    [self cancleModels:_downloadingModels];
    [self cancleModels:_waitingDownloadModels];
}

#pragma mark - NSURLSessionDelegate代理回调
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    BDDownloadModel *model = [self downLoadingModelForURLString:dataTask.taskDescription];
    if (!model) {
        return;
    }
    // 打开流
    [model.stream open];
    
    // 获得服务器这次请求 返回数据的总长度
    long long totalBytesWritten =  [self fileSizeWithDownloadModel:model];
    long long totalBytesExpectedToWrite = totalBytesWritten + dataTask.countOfBytesExpectedToReceive;
    
    model.progress.resumeBytesWritten = totalBytesWritten;
    model.progress.totalBytesWritten = totalBytesWritten;
    model.progress.totalBytesExpectedToWrite = totalBytesExpectedToWrite;
    
    // 存储总长度
    @synchronized (self) {
        NSMutableDictionary *dic = [self fileSizePlistWithDownloadModel:model];
        dic[model.downloadURL] = @(totalBytesExpectedToWrite);
        [dic writeToFile:[self fileSizePathWithDownloadModel:model] atomically:YES];
    }
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

// 接收到服务器返回的数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    BDDownloadModel *model = [self downLoadingModelForURLString:dataTask.taskDescription];
    if (!model || model.state == BDDownloadStateSuspended) {
        return;
    }
    // 写入数据
    [model.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    model.progress.bytesWritten = data.length;
    model.progress.totalBytesWritten += model.progress.bytesWritten;
    model.progress.progress  = MIN(1.0, 1.0 * model.progress.totalBytesWritten / model.progress.totalBytesExpectedToWrite);
    
    // 时间
    NSTimeInterval downloadTime = -1 * [model.downloadDate timeIntervalSinceNow];
    model.progress.speed = (model.progress.totalBytesWritten - model.progress.resumeBytesWritten) / downloadTime;
    
    int64_t remainingContentLength = model.progress.totalBytesExpectedToWrite - model.progress.totalBytesWritten;
    model.progress.remainingTime = ceilf(remainingContentLength / model.progress.speed);

    dispatch_async(dispatch_get_main_queue(), ^(){
        [[NSNotificationCenter defaultCenter] postNotificationName:BDDownloadProgressNofification object:model];
        [self downloadModel:model progress:model.progress];
    });
}

// 请求完毕（成功|失败）
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    BDDownloadModel *model = [self downLoadingModelForURLString:task.taskDescription];
    
    if (!model) {
        return;
    }
    
    // 关闭流
    [model.stream close];
    model.stream = nil;
    model.task = nil;
    
    [self removeDownLoadingModelForURLString:model.downloadURL];
    if (model.manualCancle) {
        // 暂停下载
        dispatch_async(dispatch_get_main_queue(), ^(){
            model.manualCancle = NO;
            [self model:model didChangedState:BDDownloadStateSuspended filePath:nil error:nil];
            [self willResumeNextWithDowloadModel:model];
        });
    } else if (error) {
        // 下载失败
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self model:model didChangedState:BDDownloadStateFailed filePath:nil error:error];
            [self willResumeNextWithDowloadModel:model];
        });
    } else if ([self isDownloadCompletedWithModel:model]) {
        // 下载完成
        [self downloadCompleted:model];
    } else {
        // 下载完成
        [self downloadCompleted:model];
    }
}

- (void)downloadCompleted:(BDDownloadModel *)model {
    dispatch_async(dispatch_get_main_queue(), ^(){
        [[NSNotificationCenter defaultCenter] postNotificationName:BDDownloadCompletedNofification object:model];
        [self model:model didChangedState:BDDownloadStateCompleted filePath:model.filePath error:nil];
        [self willResumeNextWithDowloadModel:model];
    });
}

#pragma mark - 文件管理
// 创建缓存目录文件
- (void)createDirectory:(NSString *)directory {
    if (![self.fileManager fileExistsAtPath:directory]) {
        [self.fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

// 下载文件信息plist路径
- (NSString *)fileSizePathWithDownloadModel:(BDDownloadModel *)model {
    return [model.downloadDirectory stringByAppendingPathComponent:kPlistName];
}

// 获取plist文件内容
- (NSMutableDictionary *)fileSizePlistWithDownloadModel:(BDDownloadModel *)model {
    NSMutableDictionary *plistDic = [NSMutableDictionary dictionaryWithContentsOfFile:[self fileSizePathWithDownloadModel:model]];
    if (!plistDic) {
        plistDic = [NSMutableDictionary dictionary];
    }
    return plistDic;
}

// 获取文件大小
- (long long)fileSizeWithDownloadModel:(BDDownloadModel *)model {
    NSString *filePath = model.filePath;
    if (![self.fileManager fileExistsAtPath:filePath]) {
        return 0;
    }
    return [[self.fileManager attributesOfItemAtPath:filePath error:nil] fileSize];
}

// 获取plist保存文件大小
- (long long)fileSizeInCachePlistWithDownloadModel:(BDDownloadModel *)model {
    NSDictionary *downloadsFileSizePlist = [NSDictionary dictionaryWithContentsOfFile:[self fileSizePathWithDownloadModel:model]];
    return [downloadsFileSizePlist[model.downloadURL] longLongValue];
}

//删除文件
- (void)deleteFileWithURL:(NSString *)url filePath:(NSString *)filePath {
    BDDownloadModel *model = [_downloadingModelDic objectForKey:url];
    if (!model) {
        model = [[BDDownloadModel alloc] initWithURLString:url filePath:filePath];
    }
    [self deleteFileWithModel:model];
}

- (void)deleteFileWithModel:(BDDownloadModel *)model {
    if (!model || !model.filePath) {
        return;
    }
    
    // 文件是否存在
    if ([self.fileManager fileExistsAtPath:model.filePath]) {
        
        // 删除任务
        model.task.taskDescription = nil;
        [model.task cancel];
        model.task = nil;
        
        // 删除流
        if (model.stream.streamStatus > NSStreamStatusNotOpen && model.stream.streamStatus < NSStreamStatusClosed) {
            [model.stream close];
        }
        model.stream = nil;
        // 删除沙盒中的资源
        NSError *error = nil;
        [self.fileManager removeItemAtPath:model.filePath error:&error];
        if (error) {
            NSLog(@"delete file error %@",error);
        }
        
        [self removeDownLoadingModelForURLString:model.downloadURL];
        // 删除资源总长度
        if ([self.fileManager fileExistsAtPath:[self fileSizePathWithDownloadModel:model]]) {
            @synchronized (self) {
                NSMutableDictionary *dict = [self fileSizePlistWithDownloadModel:model];
                [dict removeObjectForKey:model.downloadURL];
                [dict writeToFile:[self fileSizePathWithDownloadModel:model] atomically:YES];
            }
        }
    }
}

- (void)deleteAllFileInDirectory:(NSString *)downloadDic {
    if (!downloadDic) {
        downloadDic = self.downloadDirectory;
    }
    if ([self.fileManager fileExistsAtPath:downloadDic]) {
        
        // 删除任务
        for (BDDownloadModel *model in [self.downloadingModelDic allValues]) {
            if ([model.downloadDirectory isEqualToString:downloadDic]) {
                // 删除任务
                model.task.taskDescription = nil;
                [model.task cancel];
                model.task = nil;
                
                // 删除流
                if (model.stream.streamStatus > NSStreamStatusNotOpen && model.stream.streamStatus < NSStreamStatusClosed) {
                    [model.stream close];
                }
                model.stream = nil;
            }
        }
        // 删除沙盒中所有资源
        [self.fileManager removeItemAtPath:downloadDic error:nil];
    }
}

#pragma mark - 后台下载
- (void)backgroundDownload {
    // 后台任务存在
    if (_taskIdentifier != UIBackgroundTaskInvalid) {
        return;
    }
    UIApplication *application = [UIApplication sharedApplication];
    self.taskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        // stop backgroundTask
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.taskIdentifier != UIBackgroundTaskInvalid) {
                [application endBackgroundTask:self.taskIdentifier];
                self.taskIdentifier = UIBackgroundTaskInvalid;
            }
        });
    }];
}

#pragma mark - private
//自动下载下一个等待队列任务
- (void)willResumeNextWithDowloadModel:(BDDownloadModel *)model {
    if (_isBatchDownload) {
        return;
    }
    
    @synchronized (self) {
        [self.downloadingModels removeObject:model];
        // 还有未下载的
        if (self.waitingDownloadModels.count > 0) {
            BDDownloadModel *nextModel = _resumeDownloadFIFO ? self.waitingDownloadModels.firstObject : self.waitingDownloadModels.lastObject;
            [self resumeModel:nextModel];
        }
    }
}

// 是否开启下载等待队列任务
- (BOOL)canResumeDownlaodModel:(BDDownloadModel *)model {
    if (_isBatchDownload) {
        return YES;
    }
    
    @synchronized (self) {
        if (self.downloadingModels.count >= _maxDownloadCount) {
            if ([self.waitingDownloadModels indexOfObject:model] == NSNotFound) {
                [self.waitingDownloadModels addObject:model];
                self.downloadingModelDic[model.downloadURL] = model;
            }
            [self model:model didChangedState:BDDownloadStateReadying filePath:nil error:nil];
            return NO;
        }
        
        if ([self.waitingDownloadModels indexOfObject:model] != NSNotFound) {
            [self.waitingDownloadModels removeObject:model];
        }
        
        if ([self.downloadingModels indexOfObject:model] == NSNotFound) {
            [self.downloadingModels addObject:model];
        }
        return YES;
    }
}

- (void)model:(BDDownloadModel *)model didChangedState:(BDDownloadState)state filePath:(NSString *)filePath error:(NSError *)error {
    model.state = state;
    if (model.stateBlock) {
        model.stateBlock(state, filePath, error);
    }
}

- (void)downloadModel:(BDDownloadModel *)downloadModel progress:(BDDownloadProgress *)progress {
    if (downloadModel.progressBlock) {
        downloadModel.progressBlock(downloadModel.bindingData, progress);
    }
}

- (void)removeDownLoadingModelForURLString:(NSString *)URLString {
    [self.downloadingModelDic removeObjectForKey:URLString];
}


@end
