//
//  TDFile3TSDownloadOperationQueue.h
//  TDFile3Downloader
//
//  Created by BlueDancer on 2019/12/16.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
extern NSNotificationName const TDFile3TSDownloadOperationQueueStateDidChangeNotification;
extern NSNotificationName const TDFile3TSDownloadOperationQueueProgressDidChangeNotification;

typedef enum : NSUInteger {
    TDDownloadTaskStateSuspended,
    TDDownloadTaskStateRunning,
    TDDownloadTaskStateCancelled,
    TDDownloadTaskStateFinished,
    TDDownloadTaskStateFailed,
} TDDownloadTaskState;

@interface TDFile3TSDownloadOperationQueue : NSObject
- (instancetype)initWithUrl:(NSString *)m3u8url saveToFolder:(NSString *)folder;

///
/// errorCode:
///     3000    解析m3u8文件失败
///     3001    文件保存失败
///     3002    下载ts失败
///
///
@property (nonatomic, readonly) NSInteger errorCode;
@property (nonatomic, readonly) TDDownloadTaskState state;
@property (nonatomic, copy, readonly) NSString *url;
@property (nonatomic, readonly) float progress;
@property (nonatomic, readonly) int64_t speed; ///< bytes


@property (nonatomic) NSTimeInterval periodicTimeInterval; ///< default value is 0.5
@property (nonatomic, copy, nullable) void(^progressDidChangeExeBlock)(TDFile3TSDownloadOperationQueue *queue);
@property (nonatomic, copy, nullable) void(^stateDidChangeExeBlock)(TDFile3TSDownloadOperationQueue *queue);

- (void)resume;
- (void)suspend;
- (void)cancel;
@end
NS_ASSUME_NONNULL_END
