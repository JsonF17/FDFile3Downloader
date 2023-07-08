//
//  TDFile3DownloadListController.m
//  TDFile3Downloader
//
//  Created by BlueDancer on 2019/12/18.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import "TDFile3DownloadListController.h"
#import <SJUIKit/SJSQLite3.h>
#import <SJUIKit/SJSQLite3+QueryExtended.h>
#import "TDFile3DownloadListItem.h"
#import "TDFile3DownloadListOperation.h"

NS_ASSUME_NONNULL_BEGIN
@interface TDFile3DownloadListController ()<TDFile3DownloadListOperationDelegate>
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;
@property (nonatomic, strong, readonly) NSMutableArray<TDFile3DownloadListItem *> *listItems;
@property (nonatomic, strong, readonly) SJSQLite3 *database;
@property (nonatomic, strong, readonly) TDFile3Downloader *downloader;
@end

@implementation TDFile3DownloadListController
+ (instancetype)shared {
    static id obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = self.new;
    });
    return obj;
}

- (instancetype)initWithDownloader:(TDFile3Downloader *)downloader {
    self = [super init];
    if ( self ) {
        _downloader = downloader;
         NSString *databasePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"sjlist.db"];
        _database = [SJSQLite3.alloc initWithDatabasePath:databasePath];
        NSArray<TDFile3DownloadListItem *> *_Nullable items = [_database objectsForClass:TDFile3DownloadListItem.class conditions:nil orderBy:nil error:NULL];
        for ( TDFile3DownloadListItem *listItem in items ) {
            if ( listItem.state == SJDownloadStateWaiting ||
                 listItem.state == SJDownloadStateRunning ) {
                listItem.state = SJDownloadStateSuspended;
                [_database update:listItem forKey:@"state" error:NULL];
            }
        }
        _listItems = items ? items.mutableCopy : NSMutableArray.array;
        _operationQueue = NSOperationQueue.alloc.init;
        _operationQueue.maxConcurrentOperationCount = 3;
    }
    return self;
}

- (instancetype)init {
    return [self initWithDownloader:TDFile3Downloader.shared];
}

#pragma mark -

- (NSString *)localPlayUrlByUrl:(NSString *)url {
    return [self.downloader localPlayUrlByUrl:url];
}

- (NSString *)localPlayUrlByFolderName:(NSString *)name {
    return [self.downloader localPlayUrlByFolderName:name];
}

- (nullable NSArray<id<TDFile3DownloadListItem>> *)items {
    return _listItems.count > 0 ? _listItems.copy : nil;
}

- (NSInteger)count {
    return _listItems.count;
}

#pragma mark -

- (void)setMaxConcurrentDownloadCount:(NSUInteger)maxConcurrentDownloadCount {
    _operationQueue.maxConcurrentOperationCount = maxConcurrentDownloadCount;
}

- (NSUInteger)maxConcurrentDownloadCount {
    return _operationQueue.maxConcurrentOperationCount;
}

#pragma mark -

- (nullable id<TDFile3DownloadListItem>)itemAtIndex:(NSInteger)idx {
    __auto_type items = self.listItems;
    if ( idx < items.count && idx >= 0 ){
        return items[idx];
    }
    return nil;
}
- (nullable id<TDFile3DownloadListItem>)itemByUrl:(NSString *)url {
    for ( id<TDFile3DownloadListItem> item in self.listItems ) {
        if ( [item.url isEqualToString:url] )
            return item;
    }
    return nil;
}
- (nullable id<TDFile3DownloadListItem>)itemByFolderName:(NSString *)name {
    for ( id<TDFile3DownloadListItem> item in self.listItems ) {
        if ( [item.folderName isEqualToString:name] )
            return item;
    }
    return nil;
}
- (NSInteger)indexOfItemByUrl:(NSString *)url {
    __auto_type items = self.listItems;
    for ( NSInteger i = 0 ; i < items.count ; ++ i ) {
        id<TDFile3DownloadListItem> item = items[i];
        if ( [item.url isEqualToString:url] )
            return i;
    }
    return NSNotFound;
}
- (NSInteger)indexOfItemByFolderName:(NSString *)name {
    __auto_type items = self.listItems;
    for ( NSInteger i = 0 ; i < items.count ; ++ i ) {
        id<TDFile3DownloadListItem> item = items[i];
        if ( [item.folderName isEqualToString:name] )
            return i;
    }
    return NSNotFound;
}

- (void)resumeItemAtIndex:(NSInteger)index {
    TDFile3DownloadListItem *_Nullable listItem = (id)[self itemAtIndex:index];
    if ( listItem != nil ) {
        if ( listItem.operation == nil ||
             listItem.operation.isCancelled ||
             listItem.operation.isFinished ) {
            ///
            /// 将在调用暂停时, 移除操作对象, 此时需重新创建新的操作对象
            ///
            listItem.operation = [TDFile3DownloadListOperation.alloc initWithUrl:listItem.url folderName:listItem.folderName downloader:self.downloader delegate:self];
            [self.operationQueue addOperation:listItem.operation];
            listItem.state = SJDownloadStateWaiting;
            [self.database update:listItem forKey:@"state" error:NULL];
        }
    }
}
- (void)resumeItemByUrl:(NSString *)url {
    [self resumeItemAtIndex:[self indexOfItemByUrl:url]];
}
- (void)resumeItemByFolderName:(NSString *)name {
    [self resumeItemAtIndex:[self indexOfItemByFolderName:name]];
}
- (void)resumeAllItems {
    for ( NSInteger i = 0 ; i < self.listItems.count ; ++ i ) {
        [self resumeItemAtIndex:i];
    }
}

- (void)suspendItemAtIndex:(NSInteger)index {
    TDFile3DownloadListItem *_Nullable listItem = (id)[self itemAtIndex:index];
    if ( listItem != nil ) {
        ///
        /// 暂停时, 移除操作对象
        ///
        [listItem.operation cancelOperation];
        listItem.operation = nil;
        listItem.state = SJDownloadStateSuspended;
        [self.database update:listItem forKey:@"state" error:NULL];
    }
}
- (void)suspendItemByUrl:(NSString *)url {
    [self suspendItemAtIndex:[self indexOfItemByUrl:url]];
}
- (void)suspendItemByFolderName:(NSString *)name {
    [self suspendItemAtIndex:[self indexOfItemByFolderName:name]];
}
- (void)suspendAllItems {
    for ( NSInteger i = 0 ; i < self.listItems.count ; ++ i ) {
        [self suspendItemAtIndex:i];
    }
}

- (NSInteger)addItemWithUrl:(NSString *)url {
    return [self addItemWithUrl:url folderName:nil];
}

- (NSInteger)addItemWithUrl:(NSString *)url folderName:(nullable NSString *)name {
    if ( url.length != 0 ) {
        NSInteger idx = (name.length == 0 ? [self indexOfItemByUrl:url] : [self indexOfItemByFolderName:name]);
        if ( idx == NSNotFound ) {
            TDFile3DownloadListItem *listItem = [TDFile3DownloadListItem.alloc initWithUrl:url folderName:name];
            [self.listItems addObject:listItem];
            [self.database save:listItem error:NULL];
            
            listItem.operation = [TDFile3DownloadListOperation.alloc initWithUrl:url folderName:name downloader:self.downloader delegate:self];
            [self.operationQueue addOperation:listItem.operation];
            idx = self.listItems.count - 1;
            [self _itemsDidChange];
        }
        return idx;
    }
    return NSNotFound;
}

- (void)updateContentsForItemAtIndex:(NSInteger)idx {
    TDFile3DownloadListItem *_Nullable listItem = (id)[self itemAtIndex:idx];
    if ( listItem != nil ) {
        [self.database save:listItem error:NULL];
    }
}
- (void)updateContentsForItemByUrl:(NSString *)url {
    [self updateContentsForItemAtIndex:[self indexOfItemByUrl:url]];
}
- (void)updateContentsForItemByFolderName:(NSString *)name {
    [self updateContentsForItemAtIndex:[self indexOfItemByFolderName:name]];
}

- (void)deleteItemAtIndex:(NSInteger)index {
    TDFile3DownloadListItem *_Nullable listItem = (id)[self itemAtIndex:index];
    if ( listItem != nil ) {
        if ( listItem.operation != nil ) {
            [listItem.operation cancelOperation];
            listItem.operation = nil;
        }
        
        listItem.state = SJDownloadStateCancelled;
        [self.downloader deleteWithUrl:listItem.url];
        [self.listItems removeObjectAtIndex:index];
        [self.database removeObjectForClass:TDFile3DownloadListItem.class primaryKeyValue:@(listItem.id) error:NULL];
        [self _itemsDidChange];
    }
}
- (void)deleteItemForUrl:(NSString *)url {
    [self deleteItemAtIndex:[self indexOfItemByUrl:url]];
}
- (void)deleteItemForFolderName:(NSString *)name {
    [self deleteItemAtIndex:[self indexOfItemByFolderName:name]];
}
- (void)deleteAllItems {
    for ( NSInteger i = self.listItems.count - 1; i >= 0 ; -- i ) {
        [self deleteItemAtIndex:i];
    }
}

#pragma mark -

- (void)operationDidStart:(TDFile3DownloadListOperation *)operation {
    if ( operation.isCancelled || operation.isFinished ) return;
    TDFile3DownloadListItem *listItem = (id)[self itemByUrl:operation.url];
    listItem.state = SJDownloadStateRunning;
    [self.database update:listItem forKey:@"state" error:NULL];
}

- (void)operation:(TDFile3DownloadListOperation *)operation didComplete:(BOOL)isFinished {
    NSInteger idx = [self indexOfItemByUrl:operation.url];
    if ( idx != NSNotFound ) {
        TDFile3DownloadListItem *listItem = (id)[self itemAtIndex:idx];
        listItem.state = isFinished ? SJDownloadStateFinished : SJDownloadStateFailed;
        [operation finishedOperation];
        
        /// 下载完成后, 从队列移除
        if ( isFinished ) {
            [self.database removeObjectForClass:listItem.class primaryKeyValue:@(listItem.id) error:NULL];
            [self.listItems removeObjectAtIndex:idx];
            [self _itemsDidChange];
        }
    }
}

- (void)progressDidChangeForOperation:(TDFile3DownloadListOperation *)operation {
    TDFile3DownloadListItem *listItem = (id)[self itemByUrl:operation.url];
    listItem.progress = operation.progress;
    double kb = operation.speed * 1.0 / 1024;
    double m = kb / 1024 / operation.periodicTimeInterval;
    listItem.speed = m;
}

#pragma mark -

- (void)_itemsDidChange {
    if ( [self.delegate respondsToSelector:@selector(listController:itemsDidChange:)] ) {
        [self.delegate listController:self itemsDidChange:self.items];
    }
}
@end
NS_ASSUME_NONNULL_END
