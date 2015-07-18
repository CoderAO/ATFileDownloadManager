//
//  ViewController.m
//  ResumeBrokenDownloads
//
//  Created by 敖然 on 15/7/16.
//  Copyright (c) 2015年 AT. All rights reserved.
//

#import "ViewController.h"
#import "ATFileDownloadManager.h"

@interface ViewController ()
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];

}

- (IBAction)addTask:(id)sender {
    ATFileDownloadManager *manager = [ATFileDownloadManager sharedManager];
    [manager downloadWithURL:[NSURL URLWithString:@"http://weixin.yamichefs.com/yami/uploadv2/media/20140923/20140923164942_39960.mp4"] progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        NSLog(@"1---%.2f",1.0 * receivedSize / expectedSize);

    } completion:^(NSURL *cachedUrl, NSError *error) {
        NSLog(@"%@",cachedUrl.absoluteString);
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
    }];


    [manager downloadWithURL:[NSURL URLWithString:@"http://weixin.yamichefs.com/yami/uploadv2/media/20140929/20140929105406_38550.mp4"] progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        NSLog(@"2---%.2f",1.0 * receivedSize / expectedSize);

    } completion:^(NSURL *cachedUrl, NSError *error) {
        NSLog(@"%@",cachedUrl.absoluteString);
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}


- (IBAction)resume:(id)sender {
    [[ATFileDownloadManager sharedManager] resumeAll];
}

- (IBAction)pause:(id)sender {
    [[ATFileDownloadManager sharedManager] suspendAll];
}
- (IBAction)clearCache:(id)sender {
    [[ATFileDownloadManager sharedManager] clearDiskOnCompletion:^{
        NSLog(@"clear!");
    }];
}




@end

