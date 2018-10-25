//
//  TableViewCell.h
//  BDDownloadManager
//
//  Created by 酌晨茗 on 2018/10/23.
//  Copyright © 2018 酌晨茗. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDDownloadManager/BDDownloadManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface TableViewCell : UITableViewCell

@property (nonatomic, strong) UIView *progressView;

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) NSString *url;

- (void)updateProgress:(CGFloat)progress;
- (void)updateDownloadState:(BDDownloadState)state;

@end

NS_ASSUME_NONNULL_END
