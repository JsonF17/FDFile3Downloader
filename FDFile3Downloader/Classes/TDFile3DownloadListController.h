//
//  TDFile3DownloadListController.h
//  TDFile3Downloader
//
//  Created by BlueDancer on 2019/12/18.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import "TDFile3DownloadListControllerDefines.h"
#import "TDFile3Downloader.h"

NS_ASSUME_NONNULL_BEGIN
@interface TDFile3DownloadListController : NSObject<TDFile3DownloadListController>
+ (instancetype)shared;
- (instancetype)initWithDownloader:(TDFile3Downloader *)downloader;

@property (nonatomic) NSUInteger maxConcurrentDownloadCount;

@property (nonatomic, weak, nullable) id<TDFile3DownloadListControllerDelegate> delegate;

///
/// 当前存在的任务数量
///
@property (nonatomic, readonly) NSInteger count;

// ceshi tag
- (nullable NSArray<id<TDFile3DownloadListItem>> *)items;

///
/// 获取下载后的item的播放地址
///
- (NSString *)localPlayUrlByUrl:(NSString *)url;
- (NSString *)localPlayUrlByFolderName:(NSString *)name;

- (nullable id<TDFile3DownloadListItem>)itemAtIndex:(NSInteger)idx;
- (nullable id<TDFile3DownloadListItem>)itemByUrl:(NSString *)url;
- (nullable id<TDFile3DownloadListItem>)itemByFolderName:(NSString *)name;
- (NSInteger)indexOfItemByUrl:(NSString *)url;
- (NSInteger)indexOfItemByFolderName:(NSString *)name;

///
/// 恢复下载
///
- (void)resumeItemAtIndex:(NSInteger)index;
- (void)resumeItemByUrl:(NSString *)url;
- (void)resumeItemByFolderName:(NSString *)name;
- (void)resumeAllItems;

///
/// 暂停下载
///
- (void)suspendItemAtIndex:(NSInteger)index;
- (void)suspendItemByUrl:(NSString *)url;
- (void)suspendItemByFolderName:(NSString *)name;
- (void)suspendAllItems;

///
/// 添加到下载队列
///
- (NSInteger)addItemWithUrl:(NSString *)url;
- (NSInteger)addItemWithUrl:(NSString *)url folderName:(nullable NSString *)name;

///
/// 主动同步当前item的信息到数据库
///
- (void)updateContentsForItemAtIndex:(NSInteger)idx;
- (void)updateContentsForItemByUrl:(NSString *)url;
- (void)updateContentsForItemByFolderName:(NSString *)name;

///
/// 移除
///
- (void)deleteItemAtIndex:(NSInteger)index;
- (void)deleteItemForUrl:(NSString *)url;
- (void)deleteItemForFolderName:(NSString *)name;
- (void)deleteAllItems;
@end
NS_ASSUME_NONNULL_END
