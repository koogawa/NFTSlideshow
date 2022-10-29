//
//  UIAsyncImageView.m
//  AsyncImage
//

#import <QuartzCore/QuartzCore.h>
#import "UIAsyncImageView.h"


@implementation UIAsyncImageView

- (NSString *)getTempPath
{
	NSString *fileName = [[url_ path] stringByReplacingOccurrencesOfString:@"/" withString:@"~"];
	NSString *tempPath = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/icon"];
	tempPath = [tempPath stringByAppendingPathComponent:fileName];
	return tempPath;
}

- (void)loadImage:(NSString *)url
{
	url_ = [NSURL URLWithString:url];
	
	[self abort];
	self.image = nil;
	
	// キャッシュされてるならそれ使う
	NSString *tempPath = [self getTempPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
		NSData *data = [NSData dataWithContentsOfFile:tempPath];
		self.image = [UIImage imageWithData:data];
		return;
	}		
	
	data_ = [[NSMutableData alloc] initWithCapacity:0];

	NSURLRequest *req = [NSURLRequest 
						 requestWithURL:[NSURL URLWithString:url] 
						 cachePolicy:NSURLRequestUseProtocolCachePolicy
						 timeoutInterval:30.0];
	conn_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[data_ setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)nsdata
{
	[data_ appendData:nsdata];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	LOG(@"connection didFailWithError - %@", error);

	[self abort];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	self.contentMode = UIViewContentModeScaleAspectFit;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.image = [UIImage imageWithData:data_];
    
    if ([self.delegate respondsToSelector:@selector(imageViewDidFinishedLoading:)]) {
        [self.delegate imageViewDidFinishedLoading:self];
    }
	
	[self abort];
}

-(void)abort{
	if(conn_ != nil){
		[conn_ cancel];
		conn_ = nil;
	}
	if(data_ != nil){
		data_ = nil;
	}
}

- (void)dealloc
{
    LOG_CURRENT_METHOD;
	[conn_ cancel];
}

@end
