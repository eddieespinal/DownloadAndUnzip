//
//  ZipDownloader.m
//  ZipTest
//
//  Created by Nikita on 27.11.12.
//
//

#import "ZipDownloader.h"
#import "AFDownloadRequestOperation.h"

@implementation ZipDownloader

@synthesize operation;

static ZipDownloader* sharedInstance = nil;

+ (ZipDownloader*) sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [NSAllocateObject([self class], 0, NULL) init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

- (AFDownloadRequestOperation*) downloadFileFromURL:(NSURL*) fileURL toPath: (NSString*) path deleteOriginalFile:(BOOL)yesNo
{
    deleteOriginalFile_ = yesNo;
    
    NSError* error = nil;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* defaultPath = [paths lastObject]; // Get documents folder
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        if ([[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error])
        {
            path = defaultPath;
        }
    
    NSString *filename = [NSString stringWithFormat:@"%@/%@", path, [fileURL lastPathComponent]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename])
        [[NSFileManager defaultManager] removeItemAtPath:filename error:&error];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fileURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3600];
    
    
    //request is the NSRequest object for the file getting downloaded and targetPath is the final location of file once its downloaded. Don't forget to set shouldResume to YES
    operation = [[AFDownloadRequestOperation alloc] initWithRequest:request
                                                         targetPath:path
                                                       shouldResume:YES];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully downloaded file to %@", path);
        
        // unzip to default path
        [self unzipFilesFrom:nil fileName:[fileURL lastPathComponent] toPath:defaultPath];
        
    }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    
    [operation setProgressiveDownloadProgressBlock:^(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
        NSLog(@"Operation%i: bytesRead: %d", 1, bytesRead);
        NSLog(@"Operation%i: totalBytesRead: %lld", 1, totalBytesRead);
        NSLog(@"Operation%i: totalBytesExpected: %lld", 1, totalBytesExpected);
        NSLog(@"Operation%i: totalBytesReadForFile: %lld", 1, totalBytesReadForFile);
        NSLog(@"Operation%i: totalBytesExpectedToReadForFile: %lld", 1, totalBytesExpectedToReadForFile);
        
    }];
    
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
        [operation resume];
    }];
    
    [operation start];
    
    return operation;
}

//used to pause the download
-(void)pauseDownload{
    [operation pause];
}
//used to resume download
-(void)resumeDownload{
    [operation resume];
}

#pragma mark - UnZipArchive


- (void) unzipFilesFrom: (NSString*) filePath fileName: (NSString*)fileName toPath: (NSString*) path
{
    NSError* error = nil;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* defaultPath = [paths objectAtIndex:0]; // Get documents folder
    
    if ( !filePath )
    {
        filePath = defaultPath; // Get documents folder
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        if ([[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error])
        {
            path = defaultPath;
        }
    NSLog(@"%@", [error localizedDescription]);
    
    NSString* genmToFile = [filePath stringByAppendingPathComponent:fileName];
    
    [self unzipFilesFromFile:genmToFile toPath:path completion:^{
        NSArray* allFilesArray = [NSArray arrayWithArray: [[NSFileManager defaultManager] contentsOfDirectoryAtPath: path error: nil]];
        
        for (NSString *v in allFilesArray) {
            NSLog(@"%@", v);
            
            //Delete unwanted __MACOSX hidden folder inside the zip file
            if ([v isEqualToString:@"__MACOSX"]) {
                NSError *error;
                if (![[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingPathComponent:v] error:&error])
                {
                    NSLog(@"Error removing folder: %@", error);
                };
            }
        }
        
    }];
    
}

- (void) unzipFilesFromFile: (NSString*) filePath toPath:(NSString*) toPath completion:(void (^)())success
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
        return;
    
    ZipArchive *za = [[ZipArchive alloc] init];
    if ([za UnzipOpenFile: filePath])
    {
        BOOL ret = [za UnzipFileTo:toPath  overWrite: YES];
        if (ret)
        {
            NSLog(@"UnZip finished");
            
            if (deleteOriginalFile_)
            {
                NSError *error;
                if (![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error])
                {
                    NSLog(@"Error removing file: %@", error);
                };
            }
            success();
            
        }
        [za UnzipCloseFile];
        
    }
    else
        NSLog(@"File not exist!");
    
    [za release];
    
}


#pragma mark - ZipArchiveDelegate

-(void) ErrorMessage:(NSString*) msg
{
    NSLog(@"%@",msg);
}
-(BOOL) OverWriteOperation:(NSString*) file
{return YES;}

-(void) UnzipProgress:(uLong)myCurrentFileIndex total:(uLong)myTotalFileCount
{}

-(void) ZipProgress:(uLong)myCurrentFileIndex total:(uLong)myTotalFileCount
{}



@end
