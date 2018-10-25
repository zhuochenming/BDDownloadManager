//
//  BDDownloadHeader.h
//  PDFReader
//
//  Created by 酌晨茗 on 2018/9/30.
//  Copyright © 2018 酌晨茗. All rights reserved.
//

#ifndef BDDownloadHeader_h
#define BDDownloadHeader_h

static NSString *kDefaultCacheDirectory = @"BDDownloadCache";
static NSString *kPlistName = @"DownloadsLength.plist";

//下载进度的通知
static NSString *BDDownloadProgressNofification = @"BDDownloadProgressNofification";
//下载完成的通知
static NSString *BDDownloadCompletedNofification = @"BDDownloadCompletedNofification";

// 下载状态
typedef NS_ENUM(NSUInteger, BDDownloadState) {
    BDDownloadStateNone,        // 未下载 或 下载删除了
    BDDownloadStateReadying,    // 等待下载
    BDDownloadStateRunning,     // 正在下载
    BDDownloadStateSuspended,   // 下载暂停
    BDDownloadStateCompleted,   // 下载完成
    BDDownloadStateFailed       // 下载失败
};



#endif /* BDDownloadHeader_h */
