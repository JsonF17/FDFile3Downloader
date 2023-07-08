//
//  TDFile3DownloadListOperation.m
//  TDFile3Downloader
//
//  Created by BlueDancer on 2019/12/18.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import "TDFile3DownloadListOperation.h"

NS_ASSUME_NONNULL_BEGIN
@interface TDFile3DownloadListOperation () {
    BOOL _isCancelled;
}
@property (nonatomic, strong, readonly) TDFile3Downloader *downloader;
@property (nonatomic, strong, nullable) TDFile3TSDownloadOperationQueue *queue;
@property (nonatomic, getter=isExecuting) BOOL executing;
@property (nonatomic, getter=isFinished) BOOL finished;
@end
@implementation TDFile3DownloadListOperation
@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithUrl:(NSString *)url folderName:(nullable NSString *)folderName downloader:(TDFile3Downloader *)downloader delegate:(id<TDFile3DownloadListOperationDelegate>)delegate {
    self = [super init];
    if ( self ){
        _url = url;
        _folderName = folderName;
        _downloader = downloader;
        _delegate = delegate;
    }
    return self;
}

- (float)progress {
    @synchronized (self) {
        return _queue.progress;
    }
}

- (int64_t)speed {
    @synchronized (self) {
        return _queue.speed;
    }
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)setExecuting:(BOOL)executing {
    if ( executing == _executing ) return;
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)finished {
    if ( finished == _finished ) return;
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark -
- (void)start {
    @synchronized (self) {
        if ( _isCancelled ) {
            self.finished = YES;
            return;
        }
        
        self.executing = YES;
        _queue = [self.downloader download:_url folderName:_folderName];
        __weak typeof(self) _self = self;
        _queue.progressDidChangeExeBlock = ^(TDFile3TSDownloadOperationQueue * _Nonnull queue) {
            __strong typeof(_self) self = _self;
            if ( !self ) return;
            [self _progressDidChange];
        };
        _queue.stateDidChangeExeBlock = ^(TDFile3TSDownloadOperationQueue * _Nonnull queue) {
            __strong typeof(_self) self = _self;
            if ( !self ) return;
            [self _stateDidChange:queue];
        };
        [_queue resume];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate operationDidStart:self];
        });
        
        [self _stateDidChange:_queue];
        [self _progressDidChange];
    }
}

- (NSTimeInterval)periodicTimeInterval {
    return 0.5;
}

- (void)cancelOperation {
    @synchronized (self) {
        _isCancelled = YES;
        [_queue suspend];
        
        if ( self.executing == YES ) {
            [self finishedOperation];
        }
    }
}

- (void)finishedOperation {
    @synchronized (self) {
        self.executing = NO;
        self.finished = YES;
        [_queue suspend];
    }
}

#pragma mark -

- (void)_stateDidChange:(TDFile3TSDownloadOperationQueue *)queue {
    __weak typeof(self) _self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( queue.state == TDDownloadTaskStateFailed ) {
            [self.delegate operation:self didComplete:NO];
        }
        else if ( queue.state == TDDownloadTaskStateFinished ) {
            [self.delegate operation:self didComplete:YES];
        }
    });
}

- (void)_progressDidChange {
    __weak typeof(self) _self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        [self.delegate progressDidChangeForOperation:self];
    });
}
@end
NS_ASSUME_NONNULL_END
