#import "SlideShowViewController.h"
#import "MyScrollView.h"
#import "FSNConnection.h"
#import "ViewUtil.h"

@interface SlideShowViewController()
{
    UIActivityIndicatorView *indicator_;
	UIBarButtonItem         *playButton_;
	UIBarButtonItem         *pauseButton_;
	UIBarButtonItem         *actionButton_;

    NSMutableArray          *_venues;
    NSInteger               _currentIndex;

    NSString                *vId_;
    NSString                *permalink_;
    NSString                *vName_;

	BOOL					isInitialized_;
    BOOL                    isStopping_;
}

@property (nonatomic, strong) MyScrollView      *baseScrollView;

@property (nonatomic, strong) NSMutableArray    *venues;
@property (nonatomic, strong) NSMutableArray    *slides;
@property (nonatomic, strong) NSMutableArray    *photoImageViews;
@property (nonatomic, strong) NSTimer           *scrollTimer;

@end

@implementation SlideShowViewController

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

    self.navigationController.toolbarHidden = NO;
    self.view.backgroundColor = [UIColor whiteColor];

    // 設定ボタン
	UIBarButtonItem *configButton =
	[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"preferences"]
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(configButtonAction)];
    // 再生ボタン
    playButton_ =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                  target:self
                                                  action:@selector(playButtonAction)];
    playButton_.tag = 102;

    // 停止ボタン
	pauseButton_ =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                  target:self
                                                  action:@selector(pauseButtonAction)];
    pauseButton_.tag = 118;

    // アクションボタン
	actionButton_ =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                  target:self
                                                  action:@selector(actionButtonAction)];
    // 詰め物
	UIBarButtonItem *adjustment =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                  target:nil
                                                  action:nil];
	NSArray *buttons =
    [NSArray arrayWithObjects:configButton, adjustment, pauseButton_, adjustment, actionButton_, nil];
	[self setToolbarItems:buttons animated:YES];

    // アクティビティインジケータ準備
	indicator_ = [[UIActivityIndicatorView alloc] init];
	indicator_.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    indicator_.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
	[self.view addSubview:indicator_];
    [indicator_ setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2)];
    [indicator_ startAnimating];

    [self loadVenues];
    [self performSelector:@selector(startTimer) withObject:nil afterDelay:PLAY_INTERVAL];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    LOG_CURRENT_METHOD;

    NSUInteger count = [self.photoImageViews count];

    [UIView animateWithDuration:0.2
                     animations:^{
                         // 回転後の画面用にリサイズ
                         self.baseScrollView.contentSize = CGSizeMake(self.view.frame.size.width * count, self.view.frame.size.height);
                         self.baseScrollView.contentOffset = CGPointMake(self.view.frame.size.width * _currentIndex, 0);
                         for (int i = 0; i < count; i++) {
                             UIAsyncImageView *imageView = [self.photoImageViews objectAtIndex:i];
                             imageView.frame = CGRectMake(self.view.frame.size.width * i, 0, self.view.frame.size.width, self.view.frame.size.height);
                         }
                     }
                     completion:^(BOOL finished){
                         // アニメーションが終わった後実行する処理
                     }];
}


#pragma mark - Private Method

- (void)loadVenues
{
    LOG_CURRENT_METHOD;
    
	static NSString *urlString = @"https://api.opensea.io/api/v1/assets";
    NSDictionary *headers = @{@"X-API-KEY": @""};
    NSMutableDictionary *parameters = [@{@"limit": @"30"} mutableCopy];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults stringForKey:@"WALLET_ADDRESS"].length > 0)
    {
        [parameters setObject:[defaults stringForKey:@"WALLET_ADDRESS"] forKey:@"owner"];
    }

    FSNConnection *connection = [FSNConnection withUrl:[NSURL URLWithString:urlString]
                                                method:FSNRequestMethodGET
                                               headers:headers
                                            parameters:parameters
                                            parseBlock:^id(FSNConnection *c, NSError **error)
                                 {
                                     return [c.responseData dictionaryFromJSONWithError:error];
                                 }
                                       completionBlock:^(FSNConnection *c)
                                 {
                                     NSDictionary *jsonDic = (NSDictionary *)c.parseResult;
                                     [self loadVenuesDidEnd:jsonDic];
                                 }
                                         progressBlock:^(FSNConnection *c) {
                                         }];
    [connection start];
}

- (void)loadVenuesDidEnd:(NSDictionary *)jsonDic
{
    LOG_CURRENT_METHOD;
    LOG(@"dic = %@", jsonDic);

    // 初期化
    _currentIndex = 0;
    _venues = nil;
    self.slides = @[].mutableCopy;
    self.photoImageViews = @[].mutableCopy;
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [indicator_ stopAnimating];

	NSInteger errorCode = [[[jsonDic objectForKey:@"meta"] objectForKey:@"code"] intValue];

    NSArray *venues = [jsonDic objectForKey:@"assets"];
    LOG(@"venues.count = %d", venues.count);

    if (venues.count == 0) {
        [self loadVenuesFailed:nil];
        return;
    }
    
    _venues = [[NSMutableArray alloc] initWithArray:venues];
    NSUInteger count = [venues count];

    // 写真を載せる枠を作る（最初は幅ゼロ）
    self.baseScrollView = [[MyScrollView alloc] init];
    self.baseScrollView.delegate = self;
    self.baseScrollView.frame = self.view.frame;
    self.baseScrollView.contentSize = CGSizeMake(0, self.view.frame.size.height);
    self.baseScrollView.pagingEnabled = YES;
    self.baseScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.baseScrollView.autoresizesSubviews = YES;
    [self.view addSubview:self.baseScrollView];

    for (int i = 0; i < count; i++) {
        [self loadPhotoAtIndex:i];
    }

    [self startTimer];
}

- (void)loadVenuesFailed:(NSNotification *)notification
{
    LOG_CURRENT_METHOD;

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[indicator_ stopAnimating];

    // 再生も止める
    [self pauseButtonAction];
	
    UIAlertView *alert = [[UIAlertView alloc]  
                          initWithTitle:@"Error"  
						  message:@"Couldn't get venues"  
						  delegate:self
						  cancelButtonTitle:@"Close"  
						  otherButtonTitles:nil];
    [alert show];
}

// アセットリストの先頭アセットに登録されている写真を取ってくる
- (void)loadPhotoAtIndex:(NSUInteger)index
{
    LOG_CURRENT_METHOD;
    
    NSDictionary *venueDic = [_venues objectAtIndex:index];
    vId_ = [venueDic objectForKey:@"id"];
    permalink_ = [venueDic objectForKey:@"permalink"];
    vName_ = [venueDic objectForKey:@"name"];
    NSString *imageUrl = [venueDic objectForKey:@"image_url"];

    // 写真があるならそのうち一枚を表示
    if ([imageUrl isKindOfClass:[NSString class]] && imageUrl.length > 0)
    {
        // スライドに追加
        [self.slides addObject:venueDic];

        // スクロールビューの枠を広げる
        CGFloat maxX = self.baseScrollView.contentSize.width;
        self.baseScrollView.contentSize = CGSizeMake(maxX + self.view.frame.size.width, self.view.frame.size.height);

        UIAsyncImageView *photoView = [[UIAsyncImageView alloc] init];
        photoView.frame = CGRectMake(maxX, 0, self.view.frame.size.width, self.view.frame.size.height);
        photoView.contentMode = UIViewContentModeScaleAspectFit;
        [self.baseScrollView addSubview:photoView];
        [photoView loadImage:imageUrl];

        // 写真リストにも追加
        [self.photoImageViews addObject:photoView];

        // 最初の写真のタイトルだけ表示
        if (maxX == 0) {
            [self updateNavigationbarTitle];
        }
    }
}

- (void)startTransition
{
    CATransition *animation = [CATransition animation];
    
    // アニメーションのタイプ
    [animation setType:kCATransitionFade];
    [animation setSubtype:kCATransitionFromBottom];
    
    // アニメーションの長さ
    [animation setDuration:0.5];
    
    // アニメーションのタイミング
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    
    // アニメーションを登録する。forKeyはアニメの識別子
    [[self.view layer] addAnimation:animation forKey:@"transitionViewAnimation"];
}

- (void)startTimer
{
    if ([self.scrollTimer isValid]) return;

    self.scrollTimer = [NSTimer scheduledTimerWithTimeInterval:PLAY_INTERVAL
                                                        target:self
                                                      selector:@selector(showNextPhoto)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)showNextPhoto
{
    LOG_CURRENT_METHOD;

    if ([self.slides count] == 0) return;
    
    _currentIndex++;

    // 最後まで来たら先頭に
    if (_currentIndex >= [self.slides count]) {
        _currentIndex = 0;
    }

    [self startTransition];
    CGPoint nextOffset = {self.view.frame.size.width * _currentIndex, 0};
    [self.baseScrollView setContentOffset:nextOffset];

    [self updateNavigationbarTitle];
}

- (void)updateNavigationbarTitle
{
    LOG_CURRENT_METHOD;
    
    if ([self.slides count] == 0) return;

    // ナビゲーションバーのタイトル更新
    NSDictionary *venue = self.slides[_currentIndex];
    self.title = venue[@"name"];
    vId_ = venue[@"id"];
    permalink_ = venue[@"permalink"];
}

- (void)playButtonAction
{
    LOG_CURRENT_METHOD;

    [self startTimer];
    isStopping_ = NO;

    [self replaceButtonWithTag:102 withItem:pauseButton_];
}

- (void)pauseButtonAction
{
    LOG_CURRENT_METHOD;

    [self.scrollTimer invalidate];

    isStopping_ = YES;

    [self replaceButtonWithTag:118 withItem:playButton_];
}

- (void)actionButtonAction
{
    [self pauseButtonAction];
    
	UIActionSheet* sheet = [[UIActionSheet alloc] init];
	sheet.delegate = self;
	[sheet addButtonWithTitle:@"Open in other app"];
	[sheet addButtonWithTitle:@"Open in safari"];
	[sheet addButtonWithTitle:@"Cancel"];
	sheet.cancelButtonIndex = 2;
    
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
		// for iPhone
		[sheet showInView:[self.view window]];
	}
    else {
		// for iPad
		[sheet showInView:self.view];
	}
}

- (void)configButtonAction
{
	[self pauseButtonAction];

	ConfigViewController *configViewController = [[ConfigViewController alloc] init];
	configViewController.delegate = self;
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:configViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)replaceButtonWithTag:(NSInteger)tag withItem:(UIBarButtonItem *)item
{
	NSInteger index = 0;
	for (UIBarButtonItem *button in self.navigationController.toolbar.items) {
		if (button.tag == tag) {
			NSMutableArray *newItems = [NSMutableArray arrayWithArray:self.navigationController.toolbar.items];
			[newItems replaceObjectAtIndex:index withObject:item];
			self.navigationController.toolbar.items = newItems;
			break;
		}
		++index;
	}
}


#pragma mark - UIAsyncImageView delegate

// 画像のダウンロードが終わったときに呼ばれる
- (void)imageViewDidFinishedLoading:(UIAsyncImageView *)imageView
{
    LOG_CURRENT_METHOD;

    //    self.navigationItem.titleView = [ViewUtil createTitleViewWithRect:self.navigationController.navigationBar.frame title:vName_];
    self.title = vName_;

    // 画像の入れ替え処理
    [self startTransition];
    UIImageView *oldImageView = (UIImageView *)[self.baseScrollView viewWithTag:IMAGE_TAG];
    [oldImageView removeFromSuperview];

    [self.baseScrollView addSubview:imageView];
    imageView.userInteractionEnabled = YES;

    // 停止中ならここで終わり
    if (isStopping_) {
        return;
    }

    // 次へ
    [self performSelector:@selector(loadPhotos)
               withObject:nil
               afterDelay:PLAY_INTERVAL];
}


#pragma mark - ConfigViewController delegate

- (void)configClosed
{
    LOG_CURRENT_METHOD;

    // スライドショーを作り直す
    [self.baseScrollView removeFromSuperview];
    self.baseScrollView = nil;

    [self loadVenues];
}


#pragma mark - Touch Event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    LOG_CURRENT_METHOD;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    LOG_CURRENT_METHOD;

    if ([UIApplication sharedApplication].statusBarHidden)
    {
        // 表示
        [UIApplication sharedApplication].statusBarHidden = NO;
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [self.navigationController setToolbarHidden:NO animated:YES];
    }
    else {
        // 非表示
        [UIApplication sharedApplication].statusBarHidden = YES;
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
}


#pragma mark - UIScrollView delegate

/*
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    LOG_CURRENT_METHOD;
}
*/
// called when scroll view grinds to a halt
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    LOG_CURRENT_METHOD;

    // スライドショーを止める
    [self pauseButtonAction];

    // 現在位置更新
    _currentIndex = scrollView.contentOffset.x / self.view.frame.size.width;

    // ナビゲーションバーのタイトル更新
    [self updateNavigationbarTitle];
}


#pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == actionSheet.cancelButtonIndex)
    {
		LOG(@"pushed Cancel button.");
	}
    else if (buttonIndex == 0)
    {
        NSString *scheme = [NSString stringWithFormat:@"foursquare://venues/%@", vId_];
        BOOL isOK = NO;
        isOK = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:scheme]];
        LOG(@"isOK = %d", isOK);
        if (!isOK) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"foursquare app is not installed."
                                                            delegate:self
                                                   cancelButtonTitle:@"cancel"
                                                   otherButtonTitles:@"install", nil];
            [alert show];
        }
	}
    else if (buttonIndex == 1)
    {
        NSString *url = [NSString stringWithFormat:@"http://foursquare.com/venue/%@", vId_];
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:permalink_]];
	}
}


#pragma mark - UIAlertView delegate

// アラートのボタンが押された時に呼ばれる
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    LOG(@"buttonIndex = %ld", (long)buttonIndex);
    
    switch (buttonIndex)
    {
        case 0:
        {
            // キャンセルボタンが押されたとき
            break;
        }
        case 1:
        {
            // installボタンが押されたとき
            NSString *urlString = @"http://itunes.apple.com/jp/app/foursquare/id306934924?mt=8";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
            break;
        }
    }
    
}


@end
