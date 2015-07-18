//
//  ViewController.m
//  ResumeBrokenDownloads
//
//  Created by 敖然 on 15/7/16.
//  Copyright (c) 2015年 AT. All rights reserved.
//

#import "ViewController.h"
#import "ATFileDownloadManager.h"

@interface ViewController ()<NSURLSessionDownloadDelegate>
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    ATFileDownloadManager *manager = [ATFileDownloadManager sharedManager];
    manager.at_debugLogEnabled = YES;
    [manager downloadWithURLString:@"http://120.25.226.186:32812/resources/videos/minion_01.mp4" progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        NSLog(@"%f", 1.0 * receivedSize / expectedSize);
    } completion:^(NSURL *cachedUrl, NSError *error) {
        if (error) {
            NSLog(@"%@",error.localizedDescription);
        }
        NSLog(@"%@",cachedUrl.absoluteString);
    }];

}

- (IBAction)resume:(id)sender {
    [[ATFileDownloadManager sharedManager] resume];
}

- (IBAction)pause:(id)sender {
    [[ATFileDownloadManager sharedManager] suspend];
}
- (IBAction)clearCache:(id)sender {
    [[ATFileDownloadManager sharedManager] clearDiskOnCompletion:^{
        NSLog(@"clear!");
    }];
}




@end

