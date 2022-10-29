#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import "UIAsyncImageView.h"
#import "ConfigViewController.h"

@interface SlideShowViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, UIAsyncImageViewDelegate, ConfigViewControllerDelegate>

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)configClosed;

@end
