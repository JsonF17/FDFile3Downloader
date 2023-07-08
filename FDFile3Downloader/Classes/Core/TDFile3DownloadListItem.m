//
//  TDFile3DownloadListItem.m
//  TDFile3Downloader
//
//  Created by BlueDancer on 2019/12/18.
//  Copyright © 2019 SanJiang. All rights reserved.
//

#import "TDFile3DownloadListItem.h"
#if __has_include(<YYModel/YYModel.h>)
#import <YYModel/NSObject+YYModel.h>
#elif __has_include(<YYKit/YYKit.h>)
#import <YYKit/YYKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN
@interface TDFile3DownloadListItem ()
@property (nonatomic) NSInteger id;
@property (nonatomic, copy) NSString *url;
@end

@implementation TDFile3DownloadListItem
+ (nullable NSString *)sql_primaryKey {
    return @"id";
}

+ (nullable NSArray<NSString *> *)sql_autoincrementlist {
    return @[@"id"];
}

+ (nullable NSArray<NSString *> *)sql_blacklist {
    return @[@"operation", @"speed", @"delegate"];
}

- (instancetype)initWithUrl:(NSString *)url folderName:(nullable NSString *)name {
    self = [super init];
    if ( self ) {
        _url = url;
        _folderName = name;
    }
    return self;
}

- (void)setProgress:(float)progress {
    _progress = progress;
    if ( [self.delegate respondsToSelector:@selector(downloadItemProgressDidChange:)] ) {
        [self.delegate downloadItemProgressDidChange:self];
    }
}

- (void)setState:(SJDownloadState)state {
    _state = state;
    if ( [self.delegate respondsToSelector:@selector(downloadItemStateDidChange:)] ) {
        [self.delegate downloadItemStateDidChange:self];
    }
}
@end
NS_ASSUME_NONNULL_END
