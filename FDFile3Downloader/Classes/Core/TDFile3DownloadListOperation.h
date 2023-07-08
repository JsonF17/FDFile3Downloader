//
//  TDFile3DownloadListOperation.h
//  TDFile3Downloader
//
//  Created by BlueDancer on 2019/12/18.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDFile3DownloadListControllerDefines.h"
#import "TDFile3Downloader.h"
@protocol TDFile3DownloadListOperationDelegate;

NS_ASSUME_NONNULL_BEGIN
@interface TDFile3DownloadListOperation : NSOperation
- (instancetype)initWithUrl:(NSString *)url folderName:(nullable NSString *)folderName downloader:(TDFile3Downloader *)downloader delegate:(id<TDFile3DownloadListOperationDelegate>)delegate;
@property (nonatomic, weak, nullable) id<TDFile3DownloadListOperationDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *url;
@property (nonatomic, copy, readonly, nullable) NSString *folderName;
@property (nonatomic, readonly) float progress;
@property (nonatomic, readonly) int64_t speed;
@property (nonatomic, readonly) NSTimeInterval periodicTimeInterval;

- (void)finishedOperation;
- (void)cancelOperation;
@end

@protocol TDFile3DownloadListOperationDelegate <NSObject>
- (void)operationDidStart:(TDFile3DownloadListOperation *)operation;
- (void)operation:(TDFile3DownloadListOperation *)operation didComplete:(BOOL)isFinished;
- (void)progressDidChangeForOperation:(TDFile3DownloadListOperation *)operation;
@end
NS_ASSUME_NONNULL_END
