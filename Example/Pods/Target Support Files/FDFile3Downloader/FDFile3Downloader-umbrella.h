#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "TDFile3Configuration.h"
#import "TDFile3Data.h"
#import "TDFile3Download.h"
#import "TDFile3Downloader.h"
#import "TDFile3DownloadListControllerDefines.h"
#import "TDFile3DownloadListItem.h"
#import "TDFile3DownloadListOperation.h"
#import "TDFile3FileParser.h"
#import "TDFile3TSDownloadOperation.h"
#import "TDFile3TSDownloadOperationQueue.h"
#import "TDFile3DownloadListController.h"

FOUNDATION_EXPORT double FDFile3DownloaderVersionNumber;
FOUNDATION_EXPORT const unsigned char FDFile3DownloaderVersionString[];

