//
//  ATFileDownloadManager.h
//  ResumeBrokenDownloads
//
//  Created by 敖然 on 15/7/16.
//  Copyright (c) 2015年 AT. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ATFileDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize);
typedef void(^ATFileDownloaderCompletedBlock)(NSURL *cachedUrl, NSError *error);
typedef void(^ATFileDownloaderNoParamBlock)();

@interface ATFileDownloadManager : NSObject

// 文件下载进度
@property (nonatomic, assign, readonly) CGFloat progress;

+ (instancetype)sharedManager;

/**
 *  断点下载文件
 *
 *  @param urlString  文件的地址
 *  @param progress   下载进度
 *  @param completion 完成后执行的操作
 */
- (void)downloadWithURLString:(NSString *)urlString progress:(ATFileDownloaderProgressBlock)progress completion:(ATFileDownloaderCompletedBlock)completion;

/**
 *  开始或恢复下载任务
 */
- (void)resume;

/**
 *  挂起下载任务
 */
- (void)suspend;

/**
 *  清除文件硬盘缓存
 */
- (void)clearDisk;

/**
 *  清除文件硬盘缓存并执行需要的操作
 *
 *  @param block 清理结束后执行的操作
 */
- (void)clearDiskOnCompletion:(ATFileDownloaderNoParamBlock)block;

/**
 *  是否开启调试打印(可查看下载进度等信息)
 */
@property (nonatomic, assign) BOOL at_debugLogEnabled;

@end
