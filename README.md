# ATFileDownloadManager
文件下载工具,支持文件在应用重启后断点下载

##使用
```
ATFileDownloadManager *manager = [ATFileDownloadManager sharedManager];
[manager downloadWithURLString:@"your_download_url" progress:^(NSInteger receivedSize, NSInteger expectedSize) {
    // do something
} completion:^(NSURL *cachedUrl, NSError *error) {
    // do something
}];

// 开始下载
[manager resume];

// 暂停下载
[manager suspend];

// 清除硬盘缓存
[manager clearDiskOnCompletion:^{
  // do something
}];  
```
