//
//  TDFile3DownloadListControllerDefines.h
//  TDFile3Downloader
//
//  Created by BlueDancer on 2019/12/18.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#ifndef TDFile3DownloadListControllerDefines_h
#define TDFile3DownloadListControllerDefines_h
#import <Foundation/Foundation.h>
#import <SJUIKit/SJSQLiteTableModelProtocol.h>

@protocol TDFile3DownloadListItem, TDFile3DownloadListItemDelegate, TDFile3DownloadListControllerDelegate;

NS_ASSUME_NONNULL_BEGIN
///
/// 列表管理, 此为对TDFile3Downloader的上层封装
///
@protocol TDFile3DownloadListController <NSObject>

@property (nonatomic) NSUInteger maxConcurrentDownloadCount;

@property (nonatomic, weak, nullable) id<TDFile3DownloadListControllerDelegate> delegate;

@property (nonatomic, readonly) NSInteger count; ///< 队列中的任务数量
- (nullable NSArray<id<TDFile3DownloadListItem>> *)items;

/// 获取下载后的item的播放地址
- (NSString *)localPlayUrlByUrl:(NSString *)url;
- (NSString *)localPlayUrlByFolderName:(NSString *)name;

- (nullable id<TDFile3DownloadListItem>)itemAtIndex:(NSInteger)idx;
- (nullable id<TDFile3DownloadListItem>)itemByUrl:(NSString *)url;
- (nullable id<TDFile3DownloadListItem>)itemByFolderName:(NSString *)name;
- (NSInteger)indexOfItemByUrl:(NSString *)url;
- (NSInteger)indexOfItemByFolderName:(NSString *)name;

/// 恢复下载
- (void)resumeItemAtIndex:(NSInteger)index;
- (void)resumeItemByUrl:(NSString *)url;
- (void)resumeItemByFolderName:(NSString *)name;
- (void)resumeAllItems;

/// 暂停下载
- (void)suspendItemAtIndex:(NSInteger)index;
- (void)suspendItemByUrl:(NSString *)url;
- (void)suspendItemByFolderName:(NSString *)name;
- (void)suspendAllItems;

/// 添加到下载队列
- (NSInteger)addItemWithUrl:(NSString *)url;
- (NSInteger)addItemWithUrl:(NSString *)url folderName:(nullable NSString *)name;

/// 主动同步当前item的信息
- (void)updateContentsForItemAtIndex:(NSInteger)idx;
- (void)updateContentsForItemByUrl:(NSString *)url;
- (void)updateContentsForItemByFolderName:(NSString *)name;

/// 移除
- (void)deleteItemAtIndex:(NSInteger)index;
- (void)deleteItemForUrl:(NSString *)url;
- (void)deleteItemForFolderName:(NSString *)name;
- (void)deleteAllItems;
@end

@protocol TDFile3DownloadListControllerDelegate <NSObject>
- (void)listController:(id<TDFile3DownloadListController>)controller itemsDidChange:(NSArray<id<TDFile3DownloadListItem>> *)items;
@end

typedef enum : NSUInteger {
    /// 排队等待下载中
    SJDownloadStateWaiting,
    /// 用户已暂停
    SJDownloadStateSuspended,
    /// 下载中
    SJDownloadStateRunning,
    /// 已取消
    SJDownloadStateCancelled,
    /// 已完成
    SJDownloadStateFinished, ///< 已完成的任务, 将会从队列移除
    /// 失败
    SJDownloadStateFailed
} SJDownloadState;

@protocol TDFile3DownloadListItem <NSObject>
@property (nonatomic, copy, readonly, nullable) NSString *url;
@property (nonatomic, copy, readonly, nullable) NSString *folderName;
@property (nonatomic, weak, nullable) id<TDFile3DownloadListItemDelegate> delegate;

@property (nonatomic, readonly) SJDownloadState state;
@property (nonatomic, readonly) float progress;
@property (nonatomic, readonly) double speed; ///< m/s   兆/每秒
@end

@protocol TDFile3DownloadListItemDelegate <NSObject>
- (void)downloadItemStateDidChange:(id<TDFile3DownloadListItem>)item;
- (void)downloadItemProgressDidChange:(id<TDFile3DownloadListItem>)item;
@end
NS_ASSUME_NONNULL_END

#endif /* TDFile3DownloadListControllerDefines_h */
