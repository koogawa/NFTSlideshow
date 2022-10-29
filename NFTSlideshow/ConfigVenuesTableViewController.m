//
//  ConfigVenuesTableViewController.m
//  VenueViewer
//
//  Created by USER on 10/11/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ConfigVenuesTableViewController.h"


@implementation ConfigVenuesTableViewController


#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
		self.title = @"venue to load";
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		venues_ = [defaults integerForKey:@"VENUE_TO_LOAD"];
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

	// 閉じるボタン
	UIBarButtonItem* closeButton;
	closeButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																 target:self
																 action:@selector(closeButtonAction)] autorelease];
	
	NSArray *buttons = [NSArray arrayWithObjects:closeButton, nil];
	[self setToolbarItems:buttons animated:YES];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Private method

- (void)closeButtonAction {
	[[self navigationController] popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 5;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
					cell.textLabel.text = @"10";
					if (venues_ == 10) {
						cell.accessoryType = UITableViewCellAccessoryCheckmark;
						selectedRow_ = indexPath.row;
					}
					break;
				case 1:
					cell.textLabel.text = @"20";
					if (venues_ == 20) {
						cell.accessoryType = UITableViewCellAccessoryCheckmark;
						selectedRow_ = indexPath.row;
					}
					break;
				case 2:
					cell.textLabel.text = @"30";
					if (venues_ == 30) {
						cell.accessoryType = UITableViewCellAccessoryCheckmark;
						selectedRow_ = indexPath.row;
					}
					break;
				case 3:
					cell.textLabel.text = @"40";
					if (venues_ == 40) {
						cell.accessoryType = UITableViewCellAccessoryCheckmark;
						selectedRow_ = indexPath.row;
					}
					break;
				case 4:
					cell.textLabel.text = @"50";
					if (venues_ == 50) {
						cell.accessoryType = UITableViewCellAccessoryCheckmark;
						selectedRow_ = indexPath.row;
					}
					break;
				default:
					break;
			}
			break;
	}
	
    return cell;
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
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	// チェックを外す
	UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRow_ inSection:0]];
	selectedCell.accessoryType = UITableViewCellAccessoryNone;
	
	// チェックをつける
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	cell.accessoryType = UITableViewCellAccessoryCheckmark;
	
	// 設定保存
	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
					venues_ = 10;
					break;
				case 1:
					venues_ = 20;
					break;
				case 2:
					venues_ = 30;
					break;
				case 3:
					venues_ = 40;
					break;
				case 4:
					venues_ = 50;
					break;
				default:
					break;
			}
			break;
		default:
			break;
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:venues_ forKey:@"VENUE_TO_LOAD"];

	[[self navigationController] popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end

