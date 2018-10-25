//
//  TableViewCell.m
//  BDDownloadManager
//
//  Created by 酌晨茗 on 2018/10/23.
//  Copyright © 2018 酌晨茗. All rights reserved.
//

#import "TableViewCell.h"

@implementation TableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BDDownloadProgressNofification object:nil];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.progressView = [[UIView alloc] initWithFrame:CGRectMake(10, 15, 0, 5)];
        self.progressView.backgroundColor = [UIColor blueColor];
        [self.contentView addSubview:_progressView];
        
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(820, 0, 100, 45)];
        self.label.text = @"下载";
        self.label.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_label];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStyle:) name:BDDownloadProgressNofification object:nil];
    }
    return self;
}

- (void)updateStyle:(NSNotification *)sender {
    BDDownloadModel *model = sender.object;
    
    NSLog(@"下载URL：%@， 下载进度：%f", _url, model.progress.progress);
    if ([model.downloadURL isEqualToString:_url]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateDownloadState:model.state];
            [self updateProgress:model.progress.progress];
        });
    }
}

- (void)updateProgress:(CGFloat)progress {
    CGRect rect = _progressView.frame;
    rect.size.width = progress * 800;
    self.progressView.frame = rect;
}

- (void)updateDownloadState:(BDDownloadState)state {
    switch (state) {
        case BDDownloadStateNone:
            self.label.text = @"下载";
            break;
            
        case BDDownloadStateCompleted:
            self.label.text = @"下载完成";
            break;
        case BDDownloadStateReadying:
            self.label.text = @"等待中";
            break;
        case BDDownloadStateRunning:
            self.label.text = @"下载中";
            break;
        case BDDownloadStateSuspended:
            self.label.text = @"暂停";
            break;
        default:
            self.label.text = @"下载";
            break;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
