//
//  ATFileDownloadManager.m
//  ResumeBrokenDownloads
//
//  Created by 敖然 on 15/7/16.
//  Copyright (c) 2015年 AT. All rights reserved.
//

#import "ATFileDownloadManager.h"
#import <CommonCrypto/CommonDigest.h>

#define CachesPath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]

static ATFileDownloadManager *_manager;
static NSString * const lengthMapName = @"lengthMap.plist";
static NSString * const cacheDirectoryName = @"ATFileDownloadManagerCache";

static NSString * const progressCallBackKey = @"progress";
static NSString * const completionCallBackKey = @"completion";
static NSString * const cancelCallBackKey = @"cancel";
static NSString * const taskKey = @"task";
static NSString * const outputStreamKey = @"stream";

@interface ATFileDownloadManager()<NSCopying,NSURLSessionDataDelegate>

@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) NSMutableDictionary *tasks;
@property (nonatomic, strong) NSMutableDictionary *lengthMap;


@end

@interface NSURL(fileName)
- (NSString *)fileName;
@end

@implementation ATFileDownloadManager

- (instancetype)init {
    if (self = [super init]) {
        _downloadQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (NSURLSessionDataTask *)downloadWithURL:(NSURL *)url
                                 progress:(ATFileDownloaderProgressBlock)progress
                               completion:(ATFileDownloaderCompletedBlock)completion {
    NSMutableDictionary *taskDic = [NSMutableDictionary dictionary];
    taskDic[progressCallBackKey] = [progress copy];
    taskDic[completionCallBackKey] = [completion copy];


    // 先获取这个文件的长度,以免二次下载或者需要再连接一下才从响应头中获取文件长度
//    NSDictionary *lengthDic = [NSDictionary dictionaryWithContentsOfFile:self.lengthMapPath];
    NSString *fileName = url.fileName;
    NSInteger totalFileLength = [self.lengthMap[fileName] integerValue];
    NSInteger downloadedFileLength = [self downloadFileLengthWithURL:url];
    // 已经下载结束
    if (totalFileLength && downloadedFileLength == totalFileLength) {
        NSLog(@"already downloaded");
        return nil;
    }
    // 没有下载结束,需要继续下载
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *downloadRange = [NSString stringWithFormat:@"bytes=%zd-", downloadedFileLength];
    [request setValue:downloadRange forHTTPHeaderField:@"Range"];

    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    taskDic[taskKey] = task;

    self.tasks[url] = taskDic;

    NSLog(@"%@",self.tasks);
    
    [task resume];

    return task;
}

- (NSURLSessionDataTask *)taskWithURL:(NSURL *)url {
    return self.tasks[url][taskKey];
}

- (void)resumeAll {
    NSArray *allKeys = [self.tasks allKeys];
    for (NSURL *url in allKeys) {
        NSURLSessionDataTask *task = self.tasks[url][taskKey];
        [task resume];
    }
}

- (void)suspendAll {
    NSArray *allKeys = [self.tasks allKeys];
    for (NSURL *url in allKeys) {
        NSURLSessionDataTask *task = self.tasks[url][taskKey];
        [task suspend];
    }
}

- (void)cancelAllTask {
    NSArray *allKeys = [self.tasks allKeys];
    for (NSURL *url in allKeys) {
        NSURLSessionDataTask *task = self.tasks[url][taskKey];
        [task cancel];
    }
//    [_downloadQueue cancelAllOperations];

}

- (void)clearDisk {
    [self clearDiskOnCompletion:nil];
}

- (void)clearDiskOnCompletion:(ATFileDownloaderNoParamBlock)block {
    [self cancelAllTask];
    self.tasks = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.diskCachedPath error:nil];
    if (block) {
        block();
    }
    NSLog(@"%@",self.tasks);
}

#pragma mark - getters

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:self
                                            delegateQueue:self.downloadQueue];
    }
    return _session;
}

- (NSMutableDictionary *)tasks {
    if (!_tasks) {
        _tasks = [NSMutableDictionary dictionary];
    }
    return _tasks;
}

- (NSString *)diskCachedPath {
    NSFileManager *fManager = [NSFileManager defaultManager];
    NSString *cachedPath = [CachesPath stringByAppendingPathComponent:cacheDirectoryName];
    BOOL isDir = YES;
    if (![fManager fileExistsAtPath:cachedPath isDirectory:&isDir]) {
        [fManager createDirectoryAtURL:[NSURL fileURLWithPath:cachedPath] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return cachedPath;
}

- (NSMutableDictionary *)lengthMap {
    if (!_lengthMap) {
        _lengthMap = [NSMutableDictionary dictionaryWithContentsOfFile:self.lengthMapPath];
        if (!_lengthMap) {
            _lengthMap = [NSMutableDictionary dictionary];
        }
    }
    return _lengthMap;
}

- (NSString *)filePathWithURL:(NSURL *)url {
    return [self.diskCachedPath stringByAppendingPathComponent:url.fileName];
}

- (NSString *)lengthMapPath {
    return [self.diskCachedPath stringByAppendingPathComponent:lengthMapName];
}

- (NSInteger)fileTotalLengthWithURL:(NSURL *)url {
    return [[NSDictionary dictionaryWithContentsOfFile:self.lengthMapPath][url.fileName] integerValue];
}

- (NSInteger)downloadFileLengthWithURL:(NSURL *)url {
    NSString *path = [self.diskCachedPath stringByAppendingPathComponent:url.fileName];
    return  [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil][NSFileSize] integerValue];
}

- (NSURL *)URLWithDataTask:(NSURLSessionDataTask *)task {
    return task.originalRequest.URL;
}


#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {

    NSURL *taskUrl = [self URLWithDataTask:dataTask];
    NSOutputStream *outputStream = self.tasks[taskUrl][outputStreamKey];
    if (!outputStream) {
        outputStream = [NSOutputStream outputStreamToFileAtPath:[self filePathWithURL:taskUrl] append:YES];
        self.tasks[taskUrl][outputStreamKey] = outputStream;
    }
    [outputStream open];
    // 本次需要下载的长度
    NSInteger needDownloadLength = [response.allHeaderFields[@"Content-Length"] integerValue];
    NSInteger fileTotalLength = [self downloadFileLengthWithURL:taskUrl] + needDownloadLength;
    self.lengthMap[taskUrl.fileName] = @(fileTotalLength);
    // 写入长度
    [self.lengthMap writeToFile:self.lengthMapPath atomically:YES];

//    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:self.lengthMapPath];
//    if (!dic) {
//        dic = [NSMutableDictionary dictionary];
//    }
//    [dic setValue:@(fileTotalLength) forKey:taskUrl.fileName];
//    [dic writeToFile:self.lengthMapPath atomically:YES];

    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSURL *taskUrl = [self URLWithDataTask:dataTask];
    NSOutputStream *outputStream = self.tasks[taskUrl][outputStreamKey];
    [outputStream write:data.bytes maxLength:data.length];
    if (self.tasks[taskUrl][progressCallBackKey]) {
        ATFileDownloaderProgressBlock progressBlock = self.tasks[taskUrl][progressCallBackKey];
        progressBlock([self downloadFileLengthWithURL:taskUrl], [self fileTotalLengthWithURL:taskUrl]);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDataTask *)task didCompleteWithError:(NSError *)error {
    NSURL *taskUrl = [self URLWithDataTask:task];
    NSOutputStream *outputStream = self.tasks[taskUrl][outputStreamKey];
    [outputStream close];
    outputStream = nil;
    if (self.tasks[taskUrl][completionCallBackKey]) {
        ATFileDownloaderCompletedBlock completionBlock = self.tasks[taskUrl][completionCallBackKey];
        NSURL *url = [NSURL fileURLWithPath:[self filePathWithURL:taskUrl]];
        completionBlock(url, error);
    }
    [self.tasks removeObjectForKey:taskUrl];
}

#pragma mark - singleton

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    return _manager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [super allocWithZone:zone];
    });
    return _manager;
}

- (id)copyWithZone:(NSZone *)zone {
    return _manager;
}

@end

@implementation NSURL(fileName)

- (NSString *)fileName {
    const char *cStr = [self.absoluteString UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    return result;
}
@end;





