#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>


@protocol ConfigViewControllerDelegate <NSObject>
- (void)configClosed;
@end

@interface ConfigViewController : UIViewController

@property (nonatomic, weak) id <ConfigViewControllerDelegate> delegate;

@end
