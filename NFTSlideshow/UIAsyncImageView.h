//
//  UIAsyncImageView.h
//  AsyncImage
//

#import <Foundation/Foundation.h>

@class UIAsyncImageView;

@protocol UIAsyncImageViewDelegate <NSObject>
@optional
- (void)imageViewDidFinishedLoading:(UIAsyncImageView *)imageView;
@end

@interface UIAsyncImageView : UIImageView
{
	NSURLConnection	*conn_;
	NSMutableData	*data_;
	NSURL			*url_;
}

@property (nonatomic, weak) id <UIAsyncImageViewDelegate> delegate;

-(void)loadImage:(NSString *)url;
-(void)abort;

@end
