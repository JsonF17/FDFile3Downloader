//
//  TDFile3Downloader.h
//  TDFile3Downloader
//
//  Created by BlueDancer on 2019/12/16.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDFile3TSDownloadOperationQueue.h"

NS_ASSUME_NONNULL_BEGIN
@interface TDFile3Downloader : NSObject
+ (instancetype)shared;
- (instancetype)initWithRootFolder:(NSString *)path;
- (instancetype)initWithRootFolder:(NSString *)path port:(UInt16)port;

- (nullable TDFile3TSDownloadOperationQueue *)download:(NSString *)url;
- (nullable TDFile3TSDownloadOperationQueue *)download:(NSString *)url folderName:(nullable NSString *)name;

- (void)deleteWithUrl:(NSString *)url;
- (void)deleteWithFolderName:(NSString *)name;

- (NSString *)localPlayUrlByUrl:(NSString *)url;
- (NSString *)localPlayUrlByFolderName:(NSString *)name;
@end
NS_ASSUME_NONNULL_END
