#import <Foundation/Foundation.h>
#import "ImageLoaderThreadTester.h"
#import <React/RCTImageLoader.h>

@interface RCTImageLoader()
- (void)setUp;
@end

@implementation ImageLoaderThreadTester: NSObject
+(void)start:(RCTBridge*)bridge {
  [self performSelector:@selector(runTests:) withObject:bridge afterDelay:1.0];
}
+(void)runTests:(RCTBridge*)bridge {
  RCTImageLoader* loader = [bridge moduleForName:@"ImageLoader" lazilyLoadIfNecessary:true];
  
  if (false) {
    [self callSetupOnce:loader];
  }

  NSLog(@"download");
  int concurrency = 20;

  dispatch_group_t group = dispatch_group_create();

  dispatch_group_t start = dispatch_group_create();
  dispatch_group_t started = dispatch_group_create();

  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  dispatch_group_enter(start);
  for (int i = 0; i < concurrency; i++) {
    dispatch_group_enter(started);
    dispatch_group_async(group, queue, ^{
      
      NSLog(@"download start %d on thread: %@", i, [NSThread currentThread]);
      dispatch_group_leave(started);
      dispatch_group_wait(start, DISPATCH_TIME_FOREVER);
      [loader loadImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://dummyimage.com/30x20/000/fff"]]
                  callback:^(NSError* _Nullable error, UIImage* _Nullable image) {
        NSLog(@"downloaded %d", i);
      }];
    });
  }

  dispatch_group_wait(started,DISPATCH_TIME_FOREVER);
  dispatch_group_leave(start);

  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

+ (void)callSetupOnce:(RCTImageLoader*)loader {
  [loader setUp];
  /*
  [loader loadImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://dummyimage.com/30x20/000/fff"]]
              callback:^(NSError* _Nullable error, UIImage* _Nullable image) {
  }];*/
}

+(UInt32)readTopLeftPixel:(UIImage*)image {
  CGImageRef cgImage = [image CGImage];
  NSUInteger width = CGImageGetWidth(cgImage);
  NSUInteger height = CGImageGetHeight(cgImage);
  
  if (width == 0 || height == 0) {
    return 0;
  }
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
  NSUInteger bytesPerPixel = 4;
  NSUInteger bytesPerRow = bytesPerPixel * width;
  NSUInteger bitsPerComponent = 8;
  
  CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  CGColorSpaceRelease(colorSpace);
  
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
  CGContextRelease(context);
  
  UInt32 *pixels = (UInt32*)rawData;
  UInt32 topLeftPixel = pixels[0];
  
  free(rawData);
  
  return topLeftPixel;
}
@end
