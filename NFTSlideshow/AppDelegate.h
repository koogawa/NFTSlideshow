#import <UIKit/UIKit.h>

@class SlideShowViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate>
{
    UINavigationController *_navigationController;
}

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UINavigationController	*navigationController;
@property (nonatomic, strong) SlideShowViewController *viewController;

@end
