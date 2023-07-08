//
//  TDFile3Configuration.h
//  TDFile3Downloader
//
//  Created by BlueDancer on 2021/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TDFile3Configuration : NSObject

+ (instancetype)shared;

@property (nonatomic, copy, nullable) BOOL(^allowDownloads)(NSURLResponse *response);

@end

NS_ASSUME_NONNULL_END
