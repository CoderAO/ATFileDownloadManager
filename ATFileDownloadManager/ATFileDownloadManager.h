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
typedef void(^ATFileDownloaderCanceledBlock)();
typedef void(^ATFileDownloaderNoParamBlock)();

@interface ATFileDownloadManager : NSObject


+ (instancetype)sharedManager;

/**
 *  添加下载任务并启动该任务,包含了程序重启后的断点下载功能,多次调用不会重复添加任务
 *
 *  @param urlString  文件的地址
 *  @param progress   下载进度
 *  @param completion 完成后执行的操作
 */
- (NSURLSessionDataTask *)downloadWithURL:(NSURL *)url
                                 progress:(ATFileDownloaderProgressBlock)progress
                               completion:(ATFileDownloaderCompletedBlock)completion;

/**
 *  根据URL获取下载任务,可以对这些任务进行单独的操作
 *
 *  @param url 任务的URL
 *
 *  @return URL对应的下载任务
 */
- (NSURLSessionDataTask *)taskWithURL:(NSURL *)url;

/**
 *  开始或恢复下载任务
 */
- (void)resumeAll;

/**
 *  挂起下载任务
 */
- (void)suspendAll;

/**
 *  取消所有任务
 */
- (void)cancelAllTask;

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



@end
