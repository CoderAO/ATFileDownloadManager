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

@property (nonatomic, strong) NSURL *url0;
@property (nonatomic, strong) NSURL *url1;

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];

    self.url0 = [NSURL URLWithString:@"http://weixin.yamichefs.com/yami/uploadv2/media/20140923/20140923164942_39960.mp4"];
    self.url1 = [NSURL URLWithString:@"http://weixin.yamichefs.com/yami/uploadv2/media/20140929/20140929105406_38550.mp4"];
}

- (IBAction)addTask:(id)sender {
    ATFileDownloadManager *manager = [ATFileDownloadManager sharedManager];
    [manager downloadWithURL:self.url0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        NSLog(@"1---%.2f--%@",1.0 * receivedSize / expectedSize,[NSThread currentThread]);

    } completion:^(NSURL *cachedUrl, NSError *error) {
        NSLog(@"%@",cachedUrl.absoluteString);
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
    }];


    [manager downloadWithURL:self.url1 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        NSLog(@"2---%.2f--%@",1.0 * receivedSize / expectedSize,[NSThread currentThread]);

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
//    [[ATFileDownloadManager sharedManager] suspendAll];
    NSURLSessionDataTask *task0 = [[ATFileDownloadManager sharedManager] taskWithURL:self.url1];
    [task0 suspend];
}
- (IBAction)clearCache:(id)sender {
    [[ATFileDownloadManager sharedManager] clearDiskOnCompletion:^{
        NSLog(@"clear!");
    }];
}




@end

