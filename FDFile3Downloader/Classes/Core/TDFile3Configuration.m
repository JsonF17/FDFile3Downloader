//
//  TDFile3Configuration.m
//  TDFile3Downloader
//
//  Created by BlueDancer on 2021/1/15.
//

#import "TDFile3Configuration.h"

@implementation TDFile3Configuration

+ (instancetype)shared {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = TDFile3Configuration.alloc.init;
    });
    return instance;
}

@end
