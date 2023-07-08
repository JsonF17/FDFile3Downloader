//
//  TDFile3Data.h
//  SJMediaCacheServer
//
//  Created by BlueDancer on 2020/7/7.
//

#import "TDFile3Download.h"

NS_ASSUME_NONNULL_BEGIN

@interface TDFile3Data : NSObject<TDFile3DownloadTaskDelegate>

+ (NSData *)dataWithContentsOfRequest:(NSURLRequest *)request networkTaskPriority:(float)networkTaskPriority error:(NSError **)error willPerformHTTPRedirection:(void(^_Nullable)(NSHTTPURLResponse *response, NSURLRequest *newRequest))block;

@end

NS_ASSUME_NONNULL_END
