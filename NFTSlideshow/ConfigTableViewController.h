//
//  ConfigTableViewController.h
//  Marimo
//
//  Created by USER on 10/09/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <StoreKit/StoreKit.h>


@protocol ConfigTableViewControllerDelegate <NSObject>
- (void)configClosedWithNeedReload:(BOOL)needReload;
@end

@interface ConfigTableViewController : UITableViewController <CLLocationManagerDelegate, SKPaymentTransactionObserver, SKProductsRequestDelegate, ConfigTableViewControllerDelegate> {
	id <ConfigTableViewControllerDelegate>	delegate_;
	CLLocationManager	*locationManager_;
	BOOL				needReload_;
}

@property (nonatomic, assign) id <ConfigTableViewControllerDelegate> delegate;

@end
