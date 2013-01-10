//
//  ZipDownloader.h
//  ZipTest
//
//  Created by Nikita on 27.11.12.
//
//

#import <Foundation/Foundation.h>
#import "ZipArchive.h"
#import "AFDownloadRequestOperation.h"


@interface ZipDownloader : NSObject
{
    AFDownloadRequestOperation *operation;
}
@property (nonatomic, readonly) AFDownloadRequestOperation *operation;

+ (ZipDownloader*) sharedInstance;

- (AFDownloadRequestOperation*) downloadFileFromURL:(NSURL*) fileURL toPath: (NSString*) path;

- (void) unzipFilesFromFile: (NSString*) filePath toPath:(NSString*) toPath completion:(void (^)())success;
- (void) unzipFilesFrom: (NSString*) filePath fileName: (NSString*)fileName toPath: (NSString*) path;


@end
