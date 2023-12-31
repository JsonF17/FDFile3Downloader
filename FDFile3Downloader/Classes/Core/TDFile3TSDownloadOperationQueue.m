//
//  TDFile3TSDownloadOperationQueue.m
//  TDFile3Downloader
//
//  Created by BlueDancer on 2019/12/16.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SJDownloadDataTask/NSTimer+SJDownloadDataTaskAdd.h>
#import "TDFile3TSDownloadOperationQueue.h"
#import "TDFile3FileParser.h"
#import "TDFile3TSDownloadOperation.h"

NS_ASSUME_NONNULL_BEGIN
#define SJM3U8TSPath(__folder__, __name__)           [__folder__ stringByAppendingPathComponent:__name__]
#define SJM3U8ContentsPath(__folder__)               [__folder__ stringByAppendingPathComponent:@"index.m3u8"]
#define SJM3U8ExtraPath(__folder__)                  [__folder__ stringByAppendingPathComponent:@"extra.plist"]
#define SJM3U8InfoPath(__folder__)                   [__folder__ stringByAppendingPathComponent:@"info.plist"]

NSNotificationName const TDFile3TSDownloadOperationQueueStateDidChangeNotification = @"TDFile3TSDownloadOperationQueueStateDidChangeNotification";
NSNotificationName const TDFile3TSDownloadOperationQueueProgressDidChangeNotification = @"TDFile3TSDownloadOperationQueueProgressDidChangeNotification";

///
/// 附加内容, 目前只存了已下载完成的ts索引
///
/// 完成一次ts的下载, 就写入一次
///
@interface SJM3U8ExtraContent : NSObject
- (instancetype)initWithContentsOfFile:(NSString *)path;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, strong, readonly) NSArray<NSNumber *> *indexs;
- (void)addIndex:(NSInteger)index;
- (BOOL)contains:(NSInteger)index;
@end

@interface SJM3U8ExtraContent () {
    NSMutableArray<NSNumber *> *_m;
}
@end
@implementation SJM3U8ExtraContent
- (instancetype)initWithContentsOfFile:(NSString *)path {
    self = [super init];
    if ( self ) {
        _path = path;
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:path];
        _m = info[@"idxs"] != nil ? [info[@"idxs"] mutableCopy] : NSMutableArray.array;
    }
    return self;
}

- (void)addIndex:(NSInteger)index {
    [_m addObject:@(index)];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(_synchronize) withObject:nil afterDelay:3 inModes:@[NSRunLoopCommonModes]];
}

- (BOOL)contains:(NSInteger)index {
    return [_m containsObject:@(index)];
}

- (void)_synchronize {
    NSDictionary *info = @{@"idxs":_m};
    [info writeToFile:_path atomically:NO];
}
@end

@interface TDFile3TSDownloadOperationQueue ()
@property (nonatomic) NSInteger errorCode;
@property (nonatomic, copy, readonly) NSString *folder;
@property (nonatomic) TDDownloadTaskState state;
@property (nonatomic) float progress;
@property (nonatomic) int64_t previousWrote;
@property (nonatomic) int64_t speed;
@property (nonatomic, strong, nullable) TDFile3FileParser *fileParser;
@property (nonatomic, strong, nullable) NSArray<TDFile3TSDownloadOperation *> *operations;
@property (nonatomic, strong, nullable) SJM3U8ExtraContent *extraContent;
@property (nonatomic, strong, nullable) NSTimer *progressRefreshTimer;
@property (nonatomic, strong, nullable) NSOperationQueue *queue;
@property (nonatomic) BOOL isLoadingFileParser;
@end

@implementation TDFile3TSDownloadOperationQueue
- (instancetype)initWithUrl:(NSString *)url saveToFolder:(NSString *)folder {
    self = [super init];
    if ( self ) {
        _url = url.copy;
        _folder = folder.copy;
        _periodicTimeInterval = 0.5;
        
        ///
        /// 将在下载完成后生成m3u8索引文件, 如果存在, 则标识当前已下载完成
        ///
        if ( [NSFileManager.defaultManager fileExistsAtPath:SJM3U8ContentsPath(folder)] ) {
            self.progress = 1;
            self.state = TDDownloadTaskStateFinished;
        }
        else {
            if ( ![NSFileManager.defaultManager fileExistsAtPath:folder] ) {
                [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
            }
            NSString *extraPath = SJM3U8ExtraPath(self.folder);
            self.extraContent = [SJM3U8ExtraContent.alloc initWithContentsOfFile:extraPath];
            [self _loadFileParserIfNeeded];
        }
    }
    return self;
}

///
/// 暂停下载
///
- (void)suspend {
    if ( self.state == TDDownloadTaskStateCancelled || self.state == TDDownloadTaskStateFinished )
        return;
    [self.queue.operations makeObjectsPerformSelector:@selector(suspend)];
    self.queue.suspended = YES;
    self.state = TDDownloadTaskStateSuspended;
}

///
/// 恢复下载
///
- (void)resume {
    if ( self.state == TDDownloadTaskStateCancelled || self.state == TDDownloadTaskStateFinished )
        return;
    [self _loadFileParserIfNeeded];
    [self.queue.operations makeObjectsPerformSelector:@selector(resume)];
    self.queue.suspended = NO;
    self.state = TDDownloadTaskStateRunning;
    [self _updateDownloadProgress];
}

///
/// 取消下载
///
///     该方法将会删除已下载的文件, 请谨慎操作
///
- (void)cancel {
    if ( self.state == TDDownloadTaskStateCancelled )
        return;
    [self.queue.operations makeObjectsPerformSelector:@selector(cancelOperation)];
    [self.queue cancelAllOperations];
    self.state = TDDownloadTaskStateCancelled;
    [NSFileManager.defaultManager removeItemAtPath:_folder error:NULL];

    self.fileParser = nil;
    self.extraContent = nil;
    self.operations = nil;
    self.queue = nil;
}

#pragma mark -

- (void)setState:(TDDownloadTaskState)state {
    _state = state;
    
    [self _startOrStopRefreshTimer];
    if ( _stateDidChangeExeBlock ) _stateDidChangeExeBlock(self);
    [self _postNotification:TDFile3TSDownloadOperationQueueStateDidChangeNotification];
}

- (void)setProgress:(float)progress {
    _progress = progress;
    if ( _progressDidChangeExeBlock ) _progressDidChangeExeBlock(self);
    [self _postNotification:TDFile3TSDownloadOperationQueueProgressDidChangeNotification];
}

#pragma mark -

- (void)_loadFileParserIfNeeded {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( self.fileParser != nil ) return;
        if ( self.isLoadingFileParser ) return;
        self.isLoadingFileParser = YES;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSError *error = nil;
            NSString *infoPath = SJM3U8InfoPath(self.folder);
            TDFile3FileParser *fileParser = nil;
            if ( [NSFileManager.defaultManager fileExistsAtPath:infoPath] ) {
                fileParser = [TDFile3FileParser fileParserWithContentsOfFile:infoPath error:&error];
            }
            else {
                fileParser = [TDFile3FileParser fileParserWithURL:self.url saveKeyToFolder:self.folder error:&error];
                if ( error == nil ) {
                    [fileParser writeToFile:infoPath error:&error];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if ( self.state == TDDownloadTaskStateCancelled )
                    return ;
                
                if ( error != nil ) {
                    [self _onErrorWithCode:3000];
                }
                else {
                    self.fileParser = fileParser;
                    [self _addOperationsToQueue];
                    [self _updateDownloadProgress];
                }
                self.isLoadingFileParser = NO;
            });
        });
    });
}

- (void)_addOperationsToQueue {
    if ( _queue == nil ) {
        _queue = NSOperationQueue.alloc.init;
        _queue.maxConcurrentOperationCount = 5;
        _queue.suspended = self.state == TDDownloadTaskStateSuspended;
    }
    
    NSMutableArray<TDFile3TSDownloadOperation *> *m = [NSMutableArray arrayWithCapacity:self.fileParser.tsArray.count];
    __weak typeof(self) _self = self;
    [self.fileParser.tsArray enumerateObjectsUsingBlock:^(NSString * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *path = SJM3U8TSPath(self.folder, [self.fileParser TSFilenameAtIndex:idx]);
        TDFile3TSDownloadOperation *operation = [TDFile3TSDownloadOperation.alloc initWithURL:url toPath:path];
        operation.downalodCompletionHandler = ^(TDFile3TSDownloadOperation * _Nonnull operation, NSError * _Nullable error) {
          __strong typeof(_self) self = _self;
            if ( !self ) return;
            
            /// finished
            if ( error == nil ) {
                [operation finishedOperation];
                [self.extraContent addIndex:idx];
                
                BOOL isDownloadedAll = YES;
                for ( TDFile3TSDownloadOperation *operation in self.operations ) {
                    if ( operation.isDownloadFininished == NO ) {
                        isDownloadedAll = NO;
                        break;
                    }
                }
                
                if ( isDownloadedAll ) {
                    [self _finishedDownload];
                }
            }
            /// failed
            else {
                [self _onErrorWithCode:3002];
            }
        };
        
        [m addObject:operation];
        [self.queue addOperation:operation];
    }];
    
    _operations = m.copy;
}

- (void)_startOrStopRefreshTimer {
    switch ( _state ) {
        case TDDownloadTaskStateRunning: {
            if ( _progressRefreshTimer == nil ) {
                __weak typeof(self) _self = self;
                _progressRefreshTimer = [NSTimer DownloadDataTaskAdd_timerWithTimeInterval:_periodicTimeInterval block:^(NSTimer * _Nonnull timer) {
                    __strong typeof(_self) self = _self;
                    if ( !self ) {
                        [timer invalidate];
                        return ;
                    }
                    [self _updateDownloadProgress];
                } repeats:YES];
                [NSRunLoop.mainRunLoop addTimer:_progressRefreshTimer forMode:NSRunLoopCommonModes];
                [_progressRefreshTimer fire];
            }
        }
            break;
        case TDDownloadTaskStateSuspended:
        case TDDownloadTaskStateCancelled:
        case TDDownloadTaskStateFinished:
        case TDDownloadTaskStateFailed: {
            [_progressRefreshTimer invalidate];
            _progressRefreshTimer = nil;
        }
            break;
    }
}

- (void)_finishedDownload {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ///
        /// 将重组的m3u8文件保存
        ///
        NSError *error = nil;
        [self.fileParser writeContentsToFile:SJM3U8ContentsPath(self.folder) error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( error != nil ) {
                [self _onErrorWithCode:3001];
                return;
            }
            
            ///
            /// finished download
            ///
            self.progress = 1;
            self.state = TDDownloadTaskStateFinished;
            self.fileParser = nil;
            self.extraContent = nil;
            self.operations = nil;
            self.queue = nil;
        });
    });
}

///
/// 计算当前进度
///
- (void)_updateDownloadProgress {
    if ( self.operations.count != 0 ) {
        __block float curr = 0;
        __block int64_t wrote = 0;
        [self.operations enumerateObjectsUsingBlock:^(TDFile3TSDownloadOperation * _Nonnull operation, NSUInteger idx, BOOL * _Nonnull stop) {
            curr += ([self.extraContent contains:idx] ? 1 : operation.downloadProgress);
            wrote += operation.wroteSize;
        }];
        
        float progress = curr / self.operations.count;
        self.progress = progress;
        
        if ( self.previousWrote != 0 )
            self.speed = wrote - self.previousWrote;
        self.previousWrote = wrote;
        
#ifdef SJDEBUG
        double kb = _speed * 1.0 / 1024;
        double m = kb / 1024 / _periodicTimeInterval;
        
        NSLog(@"%lf - %.02lfm/s", progress, m);
#endif
    }
}

- (void)_postNotification:(NSNotificationName)name {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:name object:self];
    });
}

- (void)_onErrorWithCode:(NSInteger)code {
#ifdef DEBUG
    NSLog(@"TDFile3DownloaderErrorCode: %ld", (long)code);
#endif
    [self.operations makeObjectsPerformSelector:@selector(suspend)];
    self.queue.suspended = YES;
    self.errorCode = code;
    self.state = TDDownloadTaskStateFailed;
}
@end
NS_ASSUME_NONNULL_END
