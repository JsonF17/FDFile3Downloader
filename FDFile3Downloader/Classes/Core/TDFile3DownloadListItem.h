//
//  TDFile3DownloadListItem.h
//  TDFile3Downloader
//
//  Created by BlueDancer on 2019/12/18.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SJUIKit/SJSQLiteTableModelProtocol.h>
#import "TDFile3DownloadListControllerDefines.h"
#import "TDFile3DownloadListOperation.h"

NS_ASSUME_NONNULL_BEGIN
@interface TDFile3DownloadListItem : NSObject<TDFile3DownloadListItem, SJSQLiteTableModelProtocol>
- (instancetype)initWithUrl:(NSString *)url folderName:(nullable NSString *)name;
@property (nonatomic, weak, nullable) id<TDFile3DownloadListItemDelegate> delegate;
@property (nonatomic, copy, readonly, nullable) NSString *folderName;

@property (nonatomic, readonly) NSInteger id;
@property (nonatomic, copy, readonly) NSString *url;
@property (nonatomic) SJDownloadState state;
@property (nonatomic) float progress;
@property (nonatomic) double speed;
@property (nonatomic, strong, nullable) TDFile3DownloadListOperation *operation;
@end
NS_ASSUME_NONNULL_END
