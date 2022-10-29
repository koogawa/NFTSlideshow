//
//  ConfigTableViewController.m
//  VenueMap
//
//  Created by USER on 10/09/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ConfigTableViewController.h"
#import "ConfigVenuesTableViewController.h"
#import "ConfigMapTypeTableViewController.h"
#import "ConfigPinTypeTableViewController.h"
#import "URLLoader.h"
#import "CJSONDeserializer.h"


@interface ConfigTableViewController (Private)
- (void)completePurchaseAddon;
@end

@implementation ConfigTableViewController

@synthesize delegate = delegate_;

#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
		self.title = @"Configuration";
		needReload_ = NO;
    }
    return self;
}


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// ヘッダ作成
	UIView *tableHeaderView;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		tableHeaderView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.view.frame.size.width, 50)];
	} else {
		tableHeaderView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.view.frame.size.width, 140)];
	}

	self.tableView.tableHeaderView = tableHeaderView;
    [tableHeaderView release];
	
	// フッタ作成
	UIView *tableFooterView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.view.frame.size.width, 30)];
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width - 20, 20)];
	label.textAlignment =  UITextAlignmentCenter;
	label.backgroundColor = [UIColor clearColor];
	label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	label.adjustsFontSizeToFitWidth = YES;
	label.numberOfLines = 1;
	label.text = @"(c) 2010 - 2011 Kosuke Ogawa";
	[tableFooterView addSubview:label];
	[label release];
	self.tableView.tableFooterView = tableFooterView;
    [tableFooterView release];

	// 閉じるボタン
	UIBarButtonItem* closeButton;
	closeButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                  target:self
                                                  action:@selector(closeButtonAction)] autorelease];
//	self.navigationItem.rightBarButtonItem = closeButton;
//	[closeButton release];
	UIBarButtonItem* adjustment =
    [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
												   target:nil
												   action:nil] autorelease];
	
	//	self.navigationItem.rightBarButtonItem = currentButton;
	//	[currentButton release];
	
	NSArray *buttons = [NSArray arrayWithObjects:adjustment, closeButton, nil];
	[self setToolbarItems:buttons animated:YES];

	locationManager_ = [[CLLocationManager alloc] init];  
    [locationManager_ setDelegate:self];  
    [locationManager_ setDesiredAccuracy:kCLLocationAccuracyBest];  
    [locationManager_ setDistanceFilter:kCLDistanceFilterNone];
    [locationManager_ startUpdatingLocation];

	// Check foursquare status
	NSString *url = @"https://api.foursquare.com/v2/test";
    URLLoader *loder = [[[URLLoader alloc] init] autorelease];
    
    [[NSNotificationCenter defaultCenter] addObserver:self                         
                                             selector:@selector(loadStatusDidEnd:)
                                                 name:@"connectionDidFinishNotification"
                                               object:loder];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStatusFailed:)
                                                 name:@"connectionDidFailWithError"
                                               object:loder];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
//	NSLog(@"url = %@", url);
    [loder loadFromUrl:url method: @"GET"];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.tableView reloadData];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	[locationManager_ stopUpdatingLocation];
}

/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//	NSLog(@"%s", __func__);
    // Return YES for supported orientations
	return YES;
}


#pragma mark -
#pragma mark Private method

- (void)closeButtonAction {
	if ([self.delegate respondsToSelector:@selector(configClosedWithNeedReload:)]) {
		[self.delegate configClosedWithNeedReload:needReload_];
	}
	[self dismissModalViewControllerAnimated:YES];
}

- (void)loadStatusDidEnd:(NSNotification *)notification
{
	LOG_CURRENT_METHOD;
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    URLLoader *loder = (URLLoader *)[notification object];
    NSData *jsonData = loder.data;

	NSString *jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease];
	
	// 結果判定
	NSString *result;
	UIColor *textColor;
	if ([jsonString isEqualToString:@"{message: \"hi\"}"]) {
		result = @"OK";
		textColor = [UIColor blueColor];
	} else {
		result = @"NG";
		textColor = [UIColor redColor];
	}
	
	// セル更新
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
	cell.detailTextLabel.text = result;
	cell.detailTextLabel.textColor = textColor;
	[self.tableView reloadData];
}

- (void)loadStatusFailed:(NSNotification *)notification
{
	LOG_CURRENT_METHOD;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// セル更新
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
	cell.detailTextLabel.text = @"error";
	cell.detailTextLabel.textColor = [UIColor redColor];
	[self.tableView reloadData];
}

- (void)purchaseAddon
{
	LOG_CURRENT_METHOD;
	
    // すでにアップグレード済みなら
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"AD_REMOVED"] == YES) {
		[self completePurchaseAddon];
        return;
	}
    
    // アプリ内課金が許可されているかを確認
    if ([SKPaymentQueue canMakePayments] == NO) {
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Payment Error"
							  message:@"You are not authorized to purchase from AppStore."
							  delegate:nil
							  cancelButtonTitle:nil
							  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
        return;
    }
    
    // ネットワークの接続を確認
	/*
    if ([[UIDevice currentDevice] networkAvailable] == NO) {
    }
	*/
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // 決済中、他の操作をされないように
	CGRect rect = [UIScreen mainScreen].applicationFrame;
    UIView *grayView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, rect.size.width, rect.size.height)];
    [grayView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]];
    grayView.tag = 21;
    [self.view.window addSubview:grayView];
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [indicator setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2)];
    [grayView addSubview:indicator];
    [indicator startAnimating];
    
    [indicator release];
    [grayView release];
    
    // プロダクト情報の取得開始
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    NSSet *productIds = [NSSet setWithObject:PRODUCT_ID];
    SKProductsRequest *skProductRequest = [[[SKProductsRequest alloc] initWithProductIdentifiers:productIds] autorelease];
    skProductRequest.delegate = self;
    [skProductRequest start];
}

// 課金が行われた後、呼び出す
- (void)completePurchaseAddon
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:YES forKey:@"AD_REMOVED"];
    [self.tableView reloadData];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section) {
        case 0:
            return @"Settings";
            break;
        case 1:
            return @"Information";
            break;
		default:
			return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	switch(section) {
		case 0:
			return 5;
			break;
		case 1:
			return 2;
			break;
		default:
			return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifierText		= @"CellText";
    static NSString *CellIdentifierSwitch	= @"CellSwitch";
    
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierText];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifierText] autorelease];
					}
					cell.textLabel.text = @"Venue to load";
					cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [defaults integerForKey:@"VENUE_TO_LOAD"]];
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					return cell;
					break;
				}
				case 1:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierSwitch];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifierSwitch] autorelease];
					}
					cell.textLabel.text = @"Auto reload";
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					UISwitch *configSwitch = [[[UISwitch alloc] init] autorelease];
					CGFloat xPoint;
					if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
						xPoint = self.tableView.frame.size.width - configSwitch.frame.size.width - 30;
					} else {
						xPoint = self.tableView.frame.size.width - configSwitch.frame.size.width - 100;
					}
					CGRect frame = CGRectMake(xPoint,
											  8,
											  configSwitch.frame.size.width,
											  configSwitch.frame.size.height);
					configSwitch.frame = frame;
					configSwitch.on = [defaults boolForKey:@"AUTO_RELOAD"];
					[configSwitch addTarget:self
									 action:@selector(autoReloadSwitchAction:)
					   forControlEvents:UIControlEventValueChanged];
					[cell.contentView addSubview:configSwitch];
					return cell;
					break;
				}
				case 2:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierText];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifierText] autorelease];
					}
					cell.textLabel.text = @"Map type";
					NSString *mapTypeLabel = [defaults stringForKey:@"MAP_TYPE_LABEL"];
					cell.detailTextLabel.text = (mapTypeLabel) ? mapTypeLabel : MAP_TYPE_LABEL_STANDARD;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					return cell;
					break;
				}
				case 3:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierText];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifierText] autorelease];
					}
					cell.textLabel.text = @"Pin type";
					NSString *mapTypeLabel = [defaults stringForKey:@"PIN_TYPE_LABEL"];
					cell.detailTextLabel.text = (mapTypeLabel) ? mapTypeLabel : PIN_TYPE_LABEL_CATEGORY_ICON;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					return cell;
					break;
				}
				case 4:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierText];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifierText] autorelease];
					}
					cell.textLabel.text = @"Remove Ads";
//					BOOL adRemoved = [defaults boolForKey:@"AD_REMOVED"];
					if ([defaults boolForKey:@"AD_REMOVED"]) {
						cell.detailTextLabel.text = @"Purchased";
						cell.selectionStyle = UITableViewCellSelectionStyleNone;
					} else {
						cell.detailTextLabel.text = @"Not Purchased";
					}
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					return cell;
					break;
				}
				default:
					break;
			}
			break;
		case 1:
			switch (indexPath.row) {
				case 0:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierText];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifierText] autorelease];
					}
					cell.textLabel.text = @"Location";
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					return cell;
					break;
				}
				case 1:
				{
					UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierText];
					if (cell == nil) {
						cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifierText] autorelease];
					}
					cell.textLabel.text = @"foursquare API status";
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					return cell;
					break;
				}
				default:
					break;
			}
			break;
	}
	return nil;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case 0:
			switch (indexPath.row) {
				case 0:
				{
					UIViewController *viewController;
					viewController = [[ConfigVenuesTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
					[self.navigationController pushViewController:viewController animated:YES];
					[viewController release];
					break;
				}
				case 2:
				{
					UIViewController *viewController;
					viewController = [[ConfigMapTypeTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
					[self.navigationController pushViewController:viewController animated:YES];
					[viewController release];
					break;
				}
				case 3:
				{
					needReload_ = YES;
					UIViewController *viewController;
					viewController = [[ConfigPinTypeTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
					[self.navigationController pushViewController:viewController animated:YES];
					[viewController release];
					break;
				}
				case 4:
				{
					/* アラートは自分で用意する必要が無かった
					UIAlertView *alert = [[UIAlertView alloc]
										  initWithTitle:@"Add-on"
										  message:@"Do you want to purchase \"Remove Ads\"? ($0.99)"
										  delegate:self
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:@"OK", nil];
					[alert show];
					[alert release];
					 */
					[self purchaseAddon];
					break;
				}
				default:
					break;
			}
			break;
		default:
			break;
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -
#pragma mark CLLocationManager delegate

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation {
	
	// location 更新
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%f, %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude];
	[self.tableView reloadData];
}


#pragma mark -
#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	LOG(@"buttonIndex = %d", buttonIndex);
	
	if (buttonIndex == 1) {
		[self purchaseAddon];
	}
}


#pragma mark -
#pragma mark SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	LOG_CURRENT_METHOD;
	
    if (response == nil) {
        LOG(@"Product Response is nil");
        return;
    }
    
    // 確認できなかったidentifierをログに記録
    for (NSString *identifier in response.invalidProductIdentifiers) {
        LOG(@"invalid product identifier: %@", identifier);
    }
    
    for (SKProduct *product in response.products ) {
        LOG(@"valid product identifier: %@", product.productIdentifier);
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }    
}


#pragma mark -
#pragma mark SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	LOG_CURRENT_METHOD;
	
    BOOL purchasing = YES;
	
    for (SKPaymentTransaction *transaction in transactions)
	{
        switch (transaction.transactionState)
		{
			// 購入中
			case SKPaymentTransactionStatePurchasing:
			{
				LOG(@"Payment Transaction Purchasing");
				break;
			}
				
			// 購入成功
			case SKPaymentTransactionStatePurchased:
			{
				LOG(@"Payment Transaction END Purchased: %@", transaction.transactionIdentifier);
				purchasing = NO;
				[self completePurchaseAddon];
				[queue finishTransaction:transaction];
				break;
			}
			
			// 購入失敗
			case SKPaymentTransactionStateFailed:
			{
				LOG(@"Payment Transaction END Failed: %@ %@", transaction.transactionIdentifier, transaction.error);
				purchasing = NO;
				UIAlertView *alert = [[UIAlertView alloc]
									  initWithTitle:@"Payment Error"
									  message:@"Payment Failed (Not yet purchased)"
									  delegate:nil
									  cancelButtonTitle:nil
									  otherButtonTitles:@"OK", nil];
				[alert show];
				[alert release];
				[queue finishTransaction:transaction];
				break;
			}
			
			// 購入履歴復元
			case SKPaymentTransactionStateRestored:
			{
				LOG(@"Payment Transaction END Restored: %@", transaction.transactionIdentifier);
				// 本来ここに到達しない
				purchasing = NO;
				[queue finishTransaction:transaction];
				break;
			}
        }
    }
    
    if (purchasing == NO) {
        [(UIView *)[self.view.window viewWithTag:21] removeFromSuperview];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}


#pragma mark -
#pragma mark UIView Action

- (void)autoReloadSwitchAction:(UISwitch *)sender {
//	NSLog(@"%s:%d", __func__, sender.on);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:sender.on forKey:@"AUTO_RELOAD"];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

