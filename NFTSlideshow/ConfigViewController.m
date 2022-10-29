#import "ConfigViewController.h"

@interface ConfigViewController ()
{
    UITextField             *textField_;
}

@end

@implementation ConfigViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Wallet address";
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

	[self.navigationController setToolbarHidden:NO animated:NO];
    self.view.backgroundColor = [UIColor whiteColor];

    // アドレスフォーム配置
    textField_ = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    textField_.placeholder = @"0x0000000000000000000000000000000000000000";
    textField_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:textField_];

	// 閉じるボタン
	UIBarButtonItem *closeButton;
	closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                target:self
                                                                action:@selector(closeButtonAction)];
	UIBarButtonItem *adjustment =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                  target:nil
                                                  action:nil];

	NSArray *buttons = [NSArray arrayWithObjects:adjustment, closeButton, nil];
	[self setToolbarItems:buttons animated:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}


#pragma mark -
#pragma mark Private method


- (void)closeButtonAction
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:textField_.text forKey:@"WALLET_ADDRESS"];
    [defaults synchronize];
    
	if ([self.delegate respondsToSelector:@selector(configClosed)]) {
		[self.delegate configClosed];
	}
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
