//
//  ViewController.m
//  BDDownloadManager
//
//  Created by 酌晨茗 on 2018/10/23.
//  Copyright © 2018 酌晨茗. All rights reserved.
//

#import "ViewController.h"
#import "TableViewCell.h"
#import "BDDownloadManager.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataArray = [NSMutableArray arrayWithCapacity:0];
    NSArray *urls = @[@"http://he.yinyuetai.com/uploads/videos/common/D20B016667AF7187FE3DF4EB8D60A30C.mp4?sc=67b2d3131cccf816", @"http://data.vod.itc.cn/?rb=1&key=jbZhEJhlqlUN-Wj_HEI8BjaVqKNFvDrn&prod=flash&pt=1&new=/20/111/bOT648IiIIVJPS33wZpYWH.mp4", @"http://data.vod.itc.cn/?rb=1&key=jbZhEJhlqlUN-Wj_HEI8BjaVqKNFvDrn&prod=flash&pt=1&new=/113/78/i4k625vZTyWFLyvR9nrKzC.mp4"];
    [self.dataArray addObjectsFromArray:urls];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame];
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerClass:[TableViewCell class] forCellReuseIdentifier:@"cell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    BDDownloadManager *manager = [BDDownloadManager manager];
    manager.maxDownloadCount = 3;
    BDDownloadModel *downloadModel = [manager modelWithURLString:_dataArray[indexPath.row] toDestinationPath:nil];
    
    cell.url = _dataArray[indexPath.row];
    [cell updateProgress:downloadModel.progress.progress];
    [cell updateDownloadState:downloadModel.state];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    BDDownloadManager *manager = [BDDownloadManager manager];
    manager.maxDownloadCount = 3;
    BDDownloadModel *downloadModel = [manager modelWithURLString:_dataArray[indexPath.row] toDestinationPath:nil];
    BDDownloadState state = downloadModel.state;
    
    if (state == BDDownloadStateNone || state == BDDownloadStateReadying) {
        [manager startModel:downloadModel];
    } else if (state == BDDownloadStateSuspended) {
        [manager resumeModel:downloadModel];
    } else if (state == BDDownloadStateReadying || state == BDDownloadStateRunning) {
        [manager suspendModel:downloadModel];
    } else if (state == BDDownloadStateCompleted) {
        
    } else {
        [manager cancleModel:downloadModel];
    }
    TableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell updateDownloadState:downloadModel.state];
    [cell updateProgress:downloadModel.progress.progress];
}

@end
