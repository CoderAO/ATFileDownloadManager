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
#define ATFileLengthesMapPath [self.diskCachedPath stringByAppendingPathComponent:@"lengthesMap"]

#define ATFileName [self.taskUrlString fileName]
#define ATDownloadFilePath [CachesPath stringByAppendingPathComponent:ATFileName]

static ATFileDownloadManager *_manager;

@interface ATFileDownloadManager()<NSCopying,NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, assign) NSInteger fileTotalLength;

@property (nonatomic, copy) ATFileDownloaderProgressBlock progressBlock;
@property (nonatomic, copy) ATFileDownloaderCompletedBlock completion;
@property (nonatomic, copy) NSString *taskUrlString;

@end

@interface NSString(fileName)

- (NSString *)fileName;

@end

@implementation ATFileDownloadManager

- (void)downloadWithURLString:(NSString *)urlString progress:(ATFileDownloaderProgressBlock)progress completion:(ATFileDownloaderCompletedBlock)completion {
    self.taskUrlString = urlString;
    self.progressBlock = progress;
    self.completion = completion;
}

- (void)resume {
    [self.task resume];
}

- (void)suspend {
    [self.task suspend];
}

- (void)clearDisk {
    [self clearDiskOnCompletion:nil];
}

- (void)clearDiskOnCompletion:(ATFileDownloaderNoParamBlock)block {
    [[NSFileManager defaultManager] removeItemAtPath:self.diskCachedPath error:nil];
    if (block) {
        block();
    }
}

#pragma mark - getters

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _session;
}

- (NSURLSessionDataTask *)task {
    if (!_task) {
        // 先获取这个文件的长度,以免二次下载或者需要再连接一下才从响应头中获取文件长度
        NSDictionary *lengthDic = [NSDictionary dictionaryWithContentsOfFile:ATFileLengthesMapPath];
        NSString *fileName = ATFileName;//[self fileNameWithUrlString:self.taskUrlString];
        NSInteger fileLength = [lengthDic[fileName] integerValue];
        // 已经下载结束

        if (fileLength && self.downloadFileLength == fileLength) {
            [self at_debugLog:@"already downloaded"];
            return nil;
        }
        // 没有下载结束,需要继续下载
        NSURL *url = [NSURL URLWithString: self.taskUrlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        NSString *downloadRange = [NSString stringWithFormat:@"bytes=%zd-", self.downloadFileLength];
        [request setValue:downloadRange forHTTPHeaderField:@"Range"];

        _task = [self.session dataTaskWithRequest:request];
    }
    return _task;
}

- (NSOutputStream *)outputStream {
    if (!_outputStream) {
        _outputStream = [NSOutputStream outputStreamToFileAtPath:self.diskCachedPath append:YES];
    }
    return _outputStream;
}

- (NSInteger)downloadFileLength {
    return  [[[NSFileManager defaultManager] attributesOfItemAtPath:self.diskCachedPath error:nil][NSFileSize] integerValue];
}

- (NSString *)diskCachedPath {
    return ATDownloadFilePath;//[CachesPath stringByAppendingPathComponent:@"ATFileDownloadManagerCache"];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {

    [self.outputStream open];
    // 本次需要下载的长度
    NSInteger needDownloadLength = [response.allHeaderFields[@"Content-Length"] integerValue];
    self.fileTotalLength = self.downloadFileLength + needDownloadLength;
    // 写入长度
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:ATFileLengthesMapPath];
    if (!dic) {
        dic = [NSMutableDictionary dictionary];
    }
    [dic setValue:@(self.fileTotalLength) forKey:ATFileName];
    [dic writeToFile:ATFileLengthesMapPath atomically:YES];

    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.outputStream write:data.bytes maxLength:data.length];
    _progress = 1.0 * self.downloadFileLength / self.fileTotalLength;
    [self at_debugLog:[NSString stringWithFormat:@"%f", _progress]];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [self.outputStream close];
    self.outputStream = nil;
    task = nil;
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

#pragma mark - other

- (void)at_debugLog:(NSString *)message
{
    if (!self.at_debugLogEnabled) {
        return;
    }
    NSLog(@"%@", message);
}

@end

@implementation NSString(fileName)

- (NSString *)fileName {
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    return result;
}
@end;
