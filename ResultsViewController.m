//
//  ResultsViewController.m
//  VAS002
//
//  Created by Melvin Manzano on 3/20/12.
//  Copyright (c) 2012 GDIT. All rights reserved.
//

#import "ResultsViewController.h"
#import "VAS002AppDelegate.h"
#import "Group.h"
#import "Result.h"
#import "Note.h"
#import "Scale.h"
#import "MailData.h"
#import "FlurryUtility.h"
#import "VASAnalytics.h"
#import "DateMath.h"
#import "Error.h"
#import "GroupResult.h"
#import "Constants.h"

#import "SavedResultsController.h"
#import "ViewSavedController.h"
#import "WebViewController.h"

#define kTextFieldWidth	260.0

static NSString *kSectionTitleKey = @"sectionTitleKey";
static NSString *kSourceKey = @"sourceKey";
static NSString *kViewKey = @"viewKey";

const NSInteger kViewTag = 1;
enExportType whichExport;
BOOL isPortrait;
@implementation ResultsViewController

@synthesize groupsDictionary;
@synthesize switchDictionary;
@synthesize chartYear;
@synthesize chartMonth;
@synthesize valuesArraysForMonth;
@synthesize groupsArray;
@synthesize fromField;
@synthesize toField;
@synthesize managedObjectContext;
@synthesize tableView;
@synthesize dataSourceArray;
@synthesize ledgendColorsDictionary, filterViewItems;
@synthesize textfieldArray, groupArray, savingScreen;
@synthesize datePicker;
@synthesize doneButton, dataArray, dateFormatter;
@synthesize curFileName, noteSwitch;


CGRect picker_ShownFrame;
CGRect picker_HiddenFrame;	
int pickerShow;



- (void)didReceiveMemoryWarning
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    [super viewDidLoad];
    tableView.backgroundView = nil;
    UIDeviceOrientation interfaceOrientation = [UIDevice currentDevice].orientation;

    if (UIDeviceOrientationIsValidInterfaceOrientation(interfaceOrientation) && (interfaceOrientation == UIDeviceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) 
    {
        isPortrait = YES;
        
    }
    else if (UIDeviceOrientationIsValidInterfaceOrientation(interfaceOrientation) && (interfaceOrientation == UIDeviceOrientationLandscapeLeft ||interfaceOrientation == UIDeviceOrientationLandscapeRight))  
    {
        isPortrait = NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    self.dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    // NSLog(@"stop 1");
    [self slideDownDidStop];
    
    curFileName = @"";
    whichExport = enExportTypeCSV;
    savingScreen.hidden = YES;
    pickerShow = 0;
    UIApplication *app = [UIApplication sharedApplication];
	VAS002AppDelegate *appDelegate = (VAS002AppDelegate*)[app delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    // NSLog(@"stop 2");
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(generateReport:)];
	self.navigationItem.rightBarButtonItem = nextButton;
    [nextButton release];
    self.dataSourceArray = [NSArray arrayWithObjects:@"Start Date", @"End Date", @"Notes", nil];
    
    self.title = NSLocalizedString(@"Create Reports", @"");
	
	// we aren't editing any fields yet, it will be in edit when the user touches an edit field
	self.editing = NO;
    
	[self fillGroupsDictionary];
	//[self fillColors];
	[self createSwitches];
    
    // Create custom table array
    //Initialize the array.
    filterViewItems = [[NSMutableArray alloc] init];
    
    
    NSDictionary *groupDict = [NSDictionary dictionaryWithObject:groupsDictionary forKey:@"Groups"];
    
    NSDictionary *fieldDict = [NSDictionary dictionaryWithObject:dataSourceArray forKey:@"Groups"];
    
    
    [filterViewItems addObject:fieldDict];
    [filterViewItems addObject:groupDict];
    
    //NSLog(@"filterViewItems: %@",filterViewItems);
    
    // Init array to hold date data
    textfieldArray = [[NSMutableArray alloc]init];
    for(int i=0; i<2; i++){
        [textfieldArray addObject: [self.dateFormatter stringFromDate:[NSDate date]]];
    }
    //NSLog(@"stop 6");
    // NSLog(@"switchDictionary: %@", switchDictionary);
}

- (void)viewDidUnload
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    [super viewDidUnload];
    self.dataSourceArray = nil;
    self.dateFormatter = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc
{	
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    [doneButton release];
	[dataArray release];
	[datePicker release];
	[dateFormatter release];
    [textfieldArray release];
	
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    [super viewDidDisappear:animated];
}

#pragma mark Orientation

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    // Return YES for supported orientations.
	BOOL shouldRotate = NO;	
	
	if (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) 
    {
		shouldRotate = YES;
	}
	
	if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight) 
    {
		shouldRotate = YES;
	}

	return shouldRotate;
}

- (void)deviceOrientationChanged:(NSNotification *)notification 
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
   // UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    UIDeviceOrientation interfaceOrientation = [UIDevice currentDevice].orientation;

    if (UIDeviceOrientationIsValidInterfaceOrientation(interfaceOrientation) && (interfaceOrientation == UIDeviceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)) 
    {
        NSLog(@"***** Orientation: Portrait");
        if (!isPortrait) {
            [tableView reloadData];
            [self resignPicker];
        }
        isPortrait = YES;

    }
    else if (UIDeviceOrientationIsValidInterfaceOrientation(interfaceOrientation) && (interfaceOrientation == UIDeviceOrientationLandscapeLeft ||interfaceOrientation == UIDeviceOrientationLandscapeRight))  
    {
        NSLog(@"***** Orientation: Landscape");

        if (isPortrait) {
            [tableView reloadData];
            [self resignPicker];
        }
        isPortrait = NO;

    }
    else if (interfaceOrientation == UIDeviceOrientationFaceUp || interfaceOrientation == UIDeviceOrientationFaceDown)
    {
        NSLog(@"***** Orientation: Other");
    
    }
    else {
        NSLog(@"***** Orientation: Unknown");

    }
    
    

}

#pragma mark Fill Groups

- (void)fillGroupsDictionary {
	if (self.groupsDictionary == nil) {
		NSMutableDictionary *groups = [NSMutableDictionary dictionary];
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Group" inManagedObjectContext:self.managedObjectContext];
		[fetchRequest setEntity:entity];
        
		NSPredicate *groupPredicate = [NSPredicate predicateWithFormat:@"(showGraph == YES)"];
		NSPredicate *visiblePredicate = [NSPredicate predicateWithFormat:@"(visible == YES)"];
		
		NSArray *finalPredicateArray = [NSArray arrayWithObjects:groupPredicate,visiblePredicate, nil];
		NSPredicate *finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:finalPredicateArray];
		[fetchRequest setPredicate:finalPredicate];
        
		NSError *error = nil;
		NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		if (error) {
			[Error showErrorByAppendingString:@"Unable to get Categories to graph" withError:error];
		}
		
		[fetchRequest release];
		
		for (Group *aGroup in objects) {
			[groups setObject:aGroup forKey:aGroup.title];
		}			
		self.groupsDictionary = [NSDictionary dictionaryWithDictionary:groups];
		
		NSArray *keys = [self.groupsDictionary allKeys];
		NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		
		NSMutableArray *grpArray = [NSMutableArray array];
		for (NSString *groupName in sortedKeys) {
			[grpArray addObject:[self.groupsDictionary objectForKey:groupName]];
		}
		self.groupsArray = [NSArray arrayWithArray:grpArray];
        // NSLog(@"grpArray: %@", grpArray);
	}
}

#pragma mark Switches

-(void)createSwitches {
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	if (self.switchDictionary == nil) {
		self.switchDictionary = [NSMutableDictionary dictionary];
		
		NSInteger switchWidth = 96;
		NSInteger height = 24;
		NSInteger xOff = 8;
		NSInteger yOff = 8;
		
		CGRect switchRect = CGRectMake(xOff, yOff , switchWidth, height);
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		BOOL storedVal;
		NSString *key;
		
		NSArray *grpArray = [[self.groupsDictionary allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		for (NSString *groupTitle in grpArray) {			
			UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:switchRect];
			key = [NSString stringWithFormat:@"SWITCH_STATE_%@",groupTitle];
			if (![defaults objectForKey:key]) {
				storedVal = YES;
			}
			else {
				storedVal = [defaults boolForKey:key];				
			}
            
			aSwitch.on = storedVal;
			aSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin + UIViewAutoresizingFlexibleBottomMargin; 
			[aSwitch addTarget:self action:@selector(switchFlipped:) forControlEvents:UIControlEventValueChanged];
			
			[self.switchDictionary setValue:aSwitch forKey:groupTitle];
			[aSwitch release];
		}
	}
}

-(void)switchFlipped:(id)sender {
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	NSEnumerator *enumerator = [self.switchDictionary keyEnumerator];
	id key;
	
	UISwitch *currentValue;
	NSString *switchTitle = @"";
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *defaultsKey;
	
	while ((key = [enumerator nextObject])) {
		currentValue = [self.switchDictionary objectForKey:key];
		if (currentValue == sender) {
			switchTitle = key;
			defaultsKey = [NSString stringWithFormat:@"SWITCH_STATE_%@",switchTitle];
			BOOL val = ((UISwitch *)currentValue).on;
			[defaults setBool:val forKey:defaultsKey];
			[defaults synchronize];
			NSDictionary *usrDict = [NSDictionary dictionaryWithObjectsAndKeys:switchTitle, [NSNumber numberWithBool:val],nil];
			[FlurryUtility report:EVENT_GRAPHRESULTS_SWITCHFLIPPED withData:usrDict];
		}
	}
	
	//[self monthChanged];
}

#pragma mark colors

-(UIColor *)UIColorForIndex:(NSInteger)index {
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	NSArray *colorsArray = [NSArray arrayWithObjects:[UIColor blueColor], [UIColor greenColor], [UIColor orangeColor], [UIColor redColor], [UIColor purpleColor], [UIColor grayColor], [UIColor brownColor],	[UIColor cyanColor],[UIColor magentaColor],  nil];
	
	UIColor *color = nil;
	
	if (index >=0 && index < [colorsArray count]) {
		color = [colorsArray objectAtIndex:index];
		[[color retain] autorelease];
	}
	return color;
}


- (void)fillColors {
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	if (self.ledgendColorsDictionary == nil) {
		self.ledgendColorsDictionary = [NSMutableDictionary dictionary];
		
		NSArray *objects = [self.groupsDictionary allKeys];
        // NSLog(@"groupDict: %@", groupsDictionary);
		NSInteger index = 0;
		
		for (NSString *groupTitle in objects) {
			UIColor *color = [self UIColorForIndex:index];
			[self.ledgendColorsDictionary setObject:color forKey:groupTitle];
			index++;
		}
	}
    
    // NSLog(@"colorDict: %@", ledgendColorsDictionary);
}

#pragma mark Show filter view for Email Results
- (void)emailResults
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    
    // Fetch filtered data
    //   NSLog(@"Fetching data...");
    
    // Open mail view
    MailData *data = [[MailData alloc] init];
    data.mailRecipients = nil;
    NSString *subjectString = @"T2 Mood Tracker App Results";
    data.mailSubject = subjectString;
    NSString *filteredResults = @"";
    NSString *bodyString = @"T2 Mood Tracker App Results:<p>";
    
    data.mailBody = [NSString stringWithFormat:@"%@%@", bodyString, filteredResults];
    
    [FlurryUtility report:EVENT_EMAIL_RESULTS_PRESSED];
    
    [self sendMail:data];
    [data release];
    
    
    
}


#pragma mark Fetch Result Data

- (NSDictionary *)getValueDictionaryForMonth {
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
    
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"GroupResult" inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
    
    /*
     NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
     
     for (NSManagedObject *info in fetchedObjects) {
     
     // Group Result
     NSLog(@"day: %@", [info valueForKey:@"day"]);
     NSLog(@"month: %@", [info valueForKey:@"month"]);
     NSLog(@"value: %@", [info valueForKey:@"value"]);
     NSLog(@"year: %@", [info valueForKey:@"year"]);
     
     NSLog(@"-----------------");     
     }
     */
    
	// Create the sort descriptors array.
	NSSortDescriptor *yearDescriptor = [[NSSortDescriptor alloc] initWithKey:@"year" ascending:YES];
	NSSortDescriptor *monthDescriptor = [[NSSortDescriptor alloc] initWithKey:@"month" ascending:YES];
	NSSortDescriptor *dayDescriptor = [[NSSortDescriptor alloc] initWithKey:@"day" ascending:YES];
	NSSortDescriptor *groupTitleDescriptor = [[NSSortDescriptor alloc] initWithKey:@"group.title" ascending:YES];
	
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:yearDescriptor, monthDescriptor,dayDescriptor, groupTitleDescriptor, nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	NSString *groupPredicateString = @"";
	
	NSArray *results;
	NSPredicate *titlePredicate;
	NSString *timePredicateString;
	NSPredicate *timePredicate;
	NSPredicate *visiblePredicate;
	NSArray *finalPredicateArray;
	NSPredicate *finalPredicate;
    
    
	for (NSString *groupTitle in self.groupsDictionary) 
    {
		Group *currentGroup = [self.groupsDictionary objectForKey:groupTitle];
		UISwitch *currentSwitch = [switchDictionary objectForKey:groupTitle];
        // NSLog(@"currentSwitch: %@", currentSwitch);
        
		if (currentSwitch.on == YES) 
        {
            
			groupPredicateString = [NSString stringWithFormat:@"group.title like %%@"];
			titlePredicate = [NSPredicate predicateWithFormat:groupPredicateString, groupTitle];
			timePredicateString = [NSString stringWithFormat:@"(year == %%@) && (month == %%@)"];
			timePredicate = [NSPredicate predicateWithFormat:timePredicateString, [ NSNumber numberWithInt:self.chartYear], [NSNumber numberWithInt:self.chartMonth]];
			visiblePredicate = [NSPredicate predicateWithFormat:@"group.visible == TRUE"];
            
			finalPredicateArray = [NSArray arrayWithObjects:titlePredicate, timePredicate,visiblePredicate, nil];
		    
			finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:finalPredicateArray];
            
			[fetchRequest setPredicate:finalPredicate];
            
			[fetchRequest setFetchBatchSize:31];
			
			NSError *error = nil;
			results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
            
            // NSLog(@"result: %@", results);
            
            
            
			if (error) 
            {
				[Error showErrorByAppendingString:@"could not get result data to email" withError:error];
			} 
			else 
            {
                
				NSMutableArray *tempTotalArray = [NSMutableArray arrayWithCapacity:31];
				NSMutableArray *tempCountArray = [NSMutableArray arrayWithCapacity:31];
                
				for (NSInteger i=0; i<31; i++) 
                {
					[tempTotalArray addObject:[NSNumber numberWithInt:0]];
					[tempCountArray addObject:[NSNumber numberWithInt:0]];
				}
				
				for (GroupResult *groupResult in results) 
                {
					double value = [groupResult.value doubleValue];
					double day = [groupResult.day doubleValue] - 1;
					double totalValue = [[tempTotalArray objectAtIndex:day] doubleValue] + value;
					double count = [[tempCountArray objectAtIndex:day] doubleValue] + 1;
					[tempTotalArray replaceObjectAtIndex:day withObject:[NSNumber numberWithDouble:totalValue]];
					[tempCountArray replaceObjectAtIndex:day withObject:[NSNumber numberWithDouble:count]];
				}
				
				NSMutableArray *summaryArray = [NSMutableArray arrayWithCapacity:31];
				for (NSInteger i = 0; i<31; i++) 
                {
					double value = [[tempTotalArray objectAtIndex:i] doubleValue];
					double count = [[tempCountArray objectAtIndex:i] doubleValue];
					double averageValue = -1;
					if(count > 0) 
                    {
						averageValue = value/count;
						if (![currentGroup.positiveDescription boolValue] == NO) 
                        {
							averageValue = 100 - averageValue;
                        }
                    }
                    
					[summaryArray addObject:[NSNumber numberWithDouble:averageValue]];
				}
                
				[tempDict setObject:summaryArray forKey:groupTitle];
			}
		}
	}
	
	NSDictionary *valueDictionary = [NSDictionary dictionaryWithDictionary:tempDict];
    
	[yearDescriptor release];
	[monthDescriptor release];
	[dayDescriptor release];
	[groupTitleDescriptor release];
	[sortDescriptors release];
	[fetchRequest release];
    
    
    
	return valueDictionary;
}

#pragma mark Mail Delegate Methods

-(void)sendMail:(MailData *)data {
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	if (mailClass != nil) {
		if ([mailClass canSendMail]) {
			[self displayComposerSheetWithMailData:data];
		}
		else {
			[self launchMailAppOnDeviceWithMailData:data];
		}		
	}
	else {
		[self launchMailAppOnDeviceWithMailData:data];
	}
    
}

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	if (result  == MFMailComposeResultCancelled) {
		[FlurryUtility report:EVENT_MAIL_CANCELED];
	}
	else if(result == MFMailComposeResultSaved) {
		[FlurryUtility report:EVENT_MAIL_SAVED];
	}
	else if(result == MFMailComposeResultSent) {
		[FlurryUtility report:EVENT_MAIL_SENT];
	}
	else if(result == MFMailComposeResultFailed) {
		[FlurryUtility report:EVENT_MAIL_ERROR];
	}
	[self dismissModalViewControllerAnimated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

// Displays an email composition interface inside the application. Populates all the Mail fields. 
-(void)displayComposerSheetWithMailData:(MailData *)data
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
	if (data.mailSubject != nil) {
		[picker setSubject:data.mailSubject];
	}
	
	// Set up recipients
	if (data.mailRecipients != nil) {
		[picker setToRecipients:data.mailRecipients];
	}
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES); 
    NSString *documentsDir = [paths objectAtIndex:0];
    
    NSString *Path = [documentsDir stringByAppendingString:[NSString stringWithFormat:@"/%@", curFileName]];
    
    NSData *myData = [NSData dataWithContentsOfFile:Path];
	[picker addAttachmentData:myData mimeType:@"text/plain" fileName:curFileName];
    //  NSLog(@"Path: %@", Path);
	//NSLog(@"myData: %@", myData);
    
	if (data.mailBody != nil) {
		[picker setMessageBody:data.mailBody isHTML:YES];
	}
	
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

// Launches the Mail application on the device.
-(void)launchMailAppOnDeviceWithMailData:(MailData *)data {
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	NSString *body = @"&body=";
	if (data.mailBody != nil) {
		body = [NSString stringWithFormat:@"%@%@",body,data.mailBody];
	}
	
	//TODO: Test on 3.1.2 device
	NSString *recipients = @"";
	if (data.mailRecipients != nil) {
		for (NSString *recipient in data.mailRecipients) {
			if (![recipients isEqual:@""]) {
				recipients = [NSString stringWithFormat:@"%@,%@",recipients,recipient];
			}
			else {
				recipients = [NSString stringWithFormat:@"%@%@",recipients,recipient];	  
			}
		}
	}
	
	recipients = [NSString stringWithFormat:@"mailto:%@",recipients];
	
	NSString *subject = @"&subject=";
	if (data.mailSubject != nil) {
		data.mailSubject = [NSString stringWithFormat:@"%@%@",subject,data.mailSubject];
	}
	
	NSString *email = [NSString stringWithFormat:@"%@%@%@", recipients, subject, body];
	email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}






#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	return [filterViewItems count];
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    
    NSDictionary *dictionary = [filterViewItems objectAtIndex:section];
    NSArray *array = [dictionary objectForKey:@"Groups"];
     NSLog(@"arraycount: %i", [array count]);
    return [array count];
    
}


-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    
    // create the parent view that will hold header Label
	UIView* customView = [[[UIView alloc] initWithFrame:CGRectMake(10.0, 0.0, 300.0, 44.0)] autorelease];
	
	// create the button object
	UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.opaque = NO;
	headerLabel.textColor = [UIColor whiteColor];
	headerLabel.highlightedTextColor = [UIColor whiteColor];
	headerLabel.font = [UIFont boldSystemFontOfSize:20];
	headerLabel.frame = CGRectMake(10.0, 0.0, 300.0, 44.0);
    
	// If you want to align the header text as centered
	// headerLabel.frame = CGRectMake(150.0, 0.0, 300.0, 44.0);
    
    NSString *sectionName = @"";
    if (section == 1) 
    {
        sectionName = @"Categories";
    }
    else
    {
        sectionName = @"Date Range";
    }
    
    headerLabel.text = sectionName;
    
	[customView addSubview:headerLabel];
    [headerLabel release];
	return customView;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	return 44.0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	static NSString *cellIdentifier = @"Cell";
	
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier] autorelease];
    }
    
	// Configure the cell.
	[self configureCell:cell atIndexPath:indexPath];
	
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath 
{	
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	// Configure the cell to show the Categories title
    NSInteger row = [indexPath indexAtPosition:1];
	
    // Fetch categories
	Group *group = [self.groupsArray objectAtIndex:row];
	NSString *groupName = group.title;
    NSString *cellName = @"";
    NSString *cellDate = @"";
    
    if (indexPath.section == 0) 
    {
        
        cellName = [self.dataSourceArray objectAtIndex: indexPath.row];
        
        if ([cellName isEqualToString:@"Notes"]) 
        {
            UISwitch *aSwitch = [[UISwitch alloc] init];
            aSwitch.on = YES;
            noteSwitch = aSwitch;
            cell.accessoryView = noteSwitch;
            [aSwitch release];
        }
        else 
        {
            cellDate = [self.textfieldArray objectAtIndex: indexPath.row];

            cell.accessoryView = nil;
        }
    }
    else
    {
        // groups
        cellName = groupName;
        UISwitch *aSwitch = [self.switchDictionary objectForKey:groupName];
        aSwitch.tag = indexPath.row;
        cell.accessoryView = aSwitch;
        
        
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.textLabel.text = cellName;
    cell.detailTextLabel.text = cellDate;
	cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
	cell.textLabel.textAlignment  = UITextAlignmentLeft;
	cell.backgroundColor = [UIColor whiteColor];
	//cell.accessoryView.backgroundColor = [UIColor clearColor];
	cell.contentView.backgroundColor = [UIColor clearColor];
	cell.backgroundView.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.textAlignment = UITextAlignmentRight;
    [cell setNeedsLayout]; 
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    return UITableViewCellEditingStyleNone;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{		
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    if (indexPath.section == 0) 
    {
        int startHeight = 0;
        int startWeight = 0;
        int offSet = 44;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) 
        {
            //iPad
            UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            if (interfaceOrientation == UIDeviceOrientationPortrait || interfaceOrientation == UIDeviceOrientationPortraitUpsideDown) 
            {
                startHeight = 280;
                startWeight = 780;
                offSet = 43;

            }
            else if(interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight)
            {
                startHeight = 535;
                startWeight = 1024;
                offSet = 320;
    
            }
        }
        else 
        {
            //iPhone
            UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            if (interfaceOrientation == UIDeviceOrientationPortrait || interfaceOrientation == UIDeviceOrientationPortraitUpsideDown) 
            {
                startHeight = 480;
                startWeight = 320;
                
            }
            else if(interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight)
            {
                startHeight = 480;
                startWeight = 480;
                offSet = 210;

            }
        }
        
        
        UITableViewCell *targetCell = [self.tableView cellForRowAtIndexPath:indexPath];
        self.datePicker.date = [self.dateFormatter dateFromString:targetCell.detailTextLabel.text];
        // check if our date picker is already on screen
        if (self.datePicker.superview == nil)
        {
            
            [self.view addSubview: self.datePicker];
            // size up the picker view to our screen and compute the start/end frame origin for our slide up animation
            //
            // compute the start frame
            CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
            CGSize pickerSize = [self.datePicker sizeThatFits:CGSizeZero];
            CGRect startRect = CGRectMake(0.0,
                                          screenRect.origin.y + screenRect.size.height,
                                          startWeight, pickerSize.height);
            self.datePicker.frame = startRect;
            // NSLog(@"startheight: %i", startHeight);
            // compute the end frame
            CGRect pickerRect = CGRectMake(0.0,
                                           screenRect.size.height - (pickerSize.height + offSet),
                                           startWeight,
                                           pickerSize.height);
            // start the slide up animation
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.3];
            
            // we need to perform some post operations after the animation is complete
            [UIView setAnimationDelegate:self];
            
            self.datePicker.frame = pickerRect;
            
            // shrink the table vertical size to make room for the date picker
            CGRect newFrame = self.tableView.frame;
            newFrame.size.height -= self.datePicker.frame.size.height;
            self.tableView.frame = newFrame;
            [UIView commitAnimations];
            
            // add the "Done" button to the nav bar
            self.navigationItem.rightBarButtonItem = self.doneButton;
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath 
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    // The table view should not be re-orderable.
    return NO;
}

#pragma mark Email/Save
-(void)generateReport:(id)sender 
{
    
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    UIActionSheet *actionSheet = [[[UIActionSheet alloc]
                                   initWithTitle:@"" 
                                   delegate:self 
                                   cancelButtonTitle:@"Cancel" 
                                   destructiveButtonTitle:nil 
                                   otherButtonTitles:@"Save as CSV", @"Save as PDF", nil] autorelease];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];  
     
}

- (void)saveResults
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    [self.view bringSubviewToFront:savingScreen];
    [self fetchFilteredResults];
}

- (void)fetchFilteredResults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    // Get raw data
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Result" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    
    
    NSString *rawFromDate = [textfieldArray objectAtIndex:0];
    NSString *rawToDate = [textfieldArray objectAtIndex:1];

    
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy"];
    NSDate *myFromDate = [df dateFromString: rawFromDate];
    NSDate *myToDate = [df dateFromString: rawToDate];
    [df release];
    
    [defaults setObject:myFromDate forKey:@"PDF_FromDate"];
    [defaults setObject:myToDate forKey:@"PDF_ToDate"];

    NSLog(@"from: %@ - to: %@", myFromDate, myToDate);

    
    
    NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"(timestamp >= %@) AND (timestamp <= %@)", myFromDate, myToDate];
    
    NSString *categoryString = @"";
    int counter = 0;
    for (NSString *groupTitle in self.groupsDictionary) 
    {
		Group *currentGroup = [self.groupsDictionary objectForKey:groupTitle];
		UISwitch *currentSwitch = [switchDictionary objectForKey:groupTitle];
        // NSLog(@"switch: %@", currentSwitch);
        NSString *tString = currentGroup.title;
        
        if (!currentSwitch.on) 
        {
            if (counter == 0) 
            {
                categoryString = [NSString stringWithFormat:@"(group.title != '%@' )", tString];
                counter++;
            }
            else
            {
                categoryString = [NSString stringWithFormat:@"%@ AND (group.title != '%@' )",categoryString, tString];
            }
            
        }
    }
    //  NSLog(@"tstring: %@", categoryString);
    
    if (counter != 0) 
    {
        NSPredicate *catPredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@", categoryString]];
        
        NSArray *finalPredicateArray = [NSArray arrayWithObjects:datePredicate, catPredicate, nil];
        NSPredicate *finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:finalPredicateArray];
        [fetchRequest setPredicate:finalPredicate];
    }
    else
    {
        NSArray *finalPredicateArray = [NSArray arrayWithObjects:datePredicate, nil];
        NSPredicate *finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:finalPredicateArray];
        [fetchRequest setPredicate:finalPredicate];
    }
    
    
    NSError *error = nil;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        [Error showErrorByAppendingString:@"Unable to get data" withError:error];
    }
    
    [fetchRequest release];
    
    
    NSArray *noteArray = [NSArray arrayWithArray:[self fetchNotes]];

    switch (whichExport) {
        case enExportTypeCSV:
            [self convertArrayToCSV:objects :noteArray];
            break;
        case enExportTypePDF:
            [self convertArrayToCSV:objects :noteArray];
            break;
        default:
            break;
    }
}

- (NSArray *)fetchNotes
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSString *rawFromDate = [textfieldArray objectAtIndex:0];
    NSString *rawToDate = [textfieldArray objectAtIndex:1];
    
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy"];
    NSDate *myFromDate = [df dateFromString: rawFromDate];
    NSDate *myToDate = [df dateFromString: rawToDate];
    [df release];
    NSLog(@"from: %@ - to: %@", myFromDate, myToDate);

    
    NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"(timestamp >= %@) AND (timestamp <= %@)", myFromDate, myToDate];
    
    NSArray *finalPredicateArray = [NSArray arrayWithObjects:datePredicate, nil];
    NSPredicate *finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:finalPredicateArray];
    [fetchRequest setPredicate:finalPredicate];
    
    
    NSError *error = nil;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        [Error showErrorByAppendingString:@"Unable to get data" withError:error];
    }
    
    [fetchRequest release];
    
    return objects;
    
}

- (NSArray *)fetchScales:(NSString *)groupTitle
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Scale" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *groupPredicate = [NSPredicate predicateWithFormat:@"(group.title= %@)", groupTitle];
    
    NSArray *finalPredicateArray = [NSArray arrayWithObjects:groupPredicate, nil];
    NSPredicate *finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:finalPredicateArray];
    [fetchRequest setPredicate:finalPredicate];
    
    
    NSError *error = nil;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        [Error showErrorByAppendingString:@"Unable to get data" withError:error];
    }
    NSMutableArray *scaleArray = [[[NSMutableArray alloc] init] autorelease];
    
    for (Scale *aScale in objects) 
    {
        NSString *scaleLabel = [NSString stringWithFormat:@"%@/%@",aScale.minLabel, aScale.maxLabel];
        [scaleArray addObject:scaleLabel];
    }	
    
    
    
    [fetchRequest release];
    return scaleArray;
    
}

#pragma mark -
#pragma mark PDFService delegate method


- (void)service:(PDFService *)service
didFailedCreatingPDFFile:(NSString *)filePath
        errorNo:(HPDF_STATUS)errorNo
       detailNo:(HPDF_STATUS)detailNo
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    NSString *message = [NSString stringWithFormat:@"Couldn't create a PDF file at %@\n errorNo:0x%04x detalNo:0x%04x",
                         filePath,
                         errorNo,
                         detailNo];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"PDF creation error"
                                                     message:message
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil] autorelease];
    [alert show];
}

- (void)service:(PDFService *)service 
didFinishCreatingPDFFile:(NSString *)filePath 
       detailNo:(HPDF_STATUS)detailNo
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    NSLog(@"finished creating PDF");
    savingScreen.hidden = YES;
    /*
    WebViewController *webViewController = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
    webViewController.filePath = filePath;
    [self.navigationController pushViewController:webViewController animated:YES];
    [WebViewController release];
    */
}

#pragma mark - Array Converters

- (void)convertArrayToCSV:(NSArray *)valueArray:(NSArray *)withNotes;
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Create CSV
    NSArray * data = [NSArray arrayWithArray:valueArray];
    NSArray * notes = [NSArray arrayWithArray:withNotes];
    
    NSMutableString * csv = [NSMutableString string];
    
    for (Result *aResult in data) {
        //NSLog(@"resulttest: %@,%@,%@/%@,%@",aResult.timestamp, aResult.group.title, aResult.scale.minLabel, aResult.scale.maxLabel, aResult.value);
        NSString * combinedLine = [NSString stringWithFormat:@"%@,%@,%@/%@,%@,%@",aResult.timestamp, aResult.group.title, aResult.scale.minLabel, aResult.scale.maxLabel, aResult.value, aResult.group.positiveDescription];
        [csv appendFormat:@"%@\n", combinedLine];
        
    }
    [csv appendFormat:@"NOTES,-,-,-\n"];
    // Fetch Notes and add CSV
    if (noteSwitch.on) 
    {
        //NSMutableArray *notesArray = [[NSMutableArray alloc] init];
        for (Note *aNote in notes) 
        {
            NSString * combinedLine = [NSString stringWithFormat:@"NOTES||%@||\"%@\"||",aNote.timestamp, aNote.note];
            
            [csv appendFormat:@"%@\n", combinedLine];
          //  [notesArray addObject:[NSString stringWithFormat:@"%@|||%@",aNote.timestamp, aNote.note]];
            
        }	
        [defaults setValue:@"YES" forKey:@"PDF_Notes_On"];
     //   [defaults setValue:notesArray forKey:@"PDF_Notes"];
    }
    else 
    {
        [defaults setValue:@"NO" forKey:@"PDF_Notes_On"];
    }
  //  NSLog(@"csv: %@", csv);
    
    
    
    // Save file to disk
    //UIApplication *app = [UIApplication sharedApplication];
	//VAS002AppDelegate *appDelegate = (VAS002AppDelegate*)[app delegate];	 
    
    NSString *rawFromDate = [textfieldArray objectAtIndex:0];
    NSString *rawToDate = [textfieldArray objectAtIndex:1];
    NSArray *fromDateArray = [rawFromDate componentsSeparatedByString:@"/"];
    NSArray *toDateArray = [rawToDate componentsSeparatedByString:@"/"];
    
    int fromDay = [[fromDateArray objectAtIndex:1] intValue];
    int fromMonth = [[fromDateArray objectAtIndex:0] intValue];
    int fromYear = [[fromDateArray objectAtIndex:2] intValue];
    
    int toDay = [[toDateArray objectAtIndex:1] intValue];
    int toMonth = [[toDateArray objectAtIndex:0] intValue];
    int toYear = [[toDateArray objectAtIndex:2] intValue];  
    
    
    int r = arc4random() % 1000;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init]; 
    [dateFormat setDateFormat:@"MM/dd/yy"];
    NSDate *fromTempDate = [dateFormat dateFromString:rawFromDate];
    NSDate *toTempDate = [dateFormat dateFromString:rawToDate];
    [dateFormat setDateFormat:@"MM/dd/yy"];
    NSString *fromDate = [dateFormat stringFromDate:fromTempDate];
    NSString *toDate = [dateFormat stringFromDate:toTempDate];
    [dateFormat release];
    NSString *fileName = [NSString stringWithFormat:@"/%i%i%i_%i%i%i_%i.csv", fromDay, fromMonth, fromYear, toDay, toMonth, toYear, r];  
    NSString *rawFileName = [NSString stringWithFormat:@"%i%i%i_%i%i%i_%i.csv", fromDay, fromMonth, fromYear, toDay, toMonth, toYear, r];
    
    NSString *reportType = @"";
    if (whichExport == enExportTypeCSV) 
    {
        reportType = @"CSV";
    }
    else 
    {
        reportType = @"PDF";
    }
    NSString *titleText = [NSString stringWithFormat:@"Moodtracker(%@) %@ - %@",reportType, fromDate, toDate];
    NSDate *today = [NSDate date];
    curFileName = rawFileName;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES); 
    NSString *documentsDir = [paths objectAtIndex:0];
    NSString *finalPath = [NSString stringWithFormat:@"%@%@",documentsDir, fileName];
    [csv writeToFile:finalPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    [self.view sendSubviewToBack:savingScreen];
    
    // Save file info in Core Data
    NSManagedObject *savedResult = nil;
    
    savedResult = [NSEntityDescription insertNewObjectForEntityForName:@"SavedResults" inManagedObjectContext:self.managedObjectContext];
    
    [savedResult setValue:titleText forKey: @"title"];
    [savedResult setValue:fileName forKey: @"filename"];
    [savedResult setValue:today forKey: @"timestamp"];

    
    
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        [Error showErrorByAppendingString:@"Unable to save result" withError:error];
    } 	
    
    
    // Create PDF
    /*
    if (whichExport == enExportTypePDF) 
    {
        PDFService *service = [PDFService instance];
        service.delegate = self;
        [service createPDFFile]; 
    }
     */
    // Send to SavedResults View
    
    savingScreen.hidden = YES;
    
   // [self.navigationController popViewControllerAnimated:YES];

    switch (whichExport) {
        case enExportTypePDF:
            // PDF

            
            // Send to SavedResults View
            savingScreen.hidden = YES;
            ViewSavedController *viewSavedController = [[ViewSavedController alloc] initWithNibName:@"ViewSavedController" bundle:nil];
            viewSavedController.finalPath = [NSString stringWithFormat:@"%@", fileName];
            viewSavedController.fileName = titleText;
            NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
            
            
            
            for (NSString *groupTitle in self.groupsDictionary) 
            {
                Group *currentGroup = [self.groupsDictionary objectForKey:groupTitle];
                UISwitch *currentSwitch = [switchDictionary objectForKey:groupTitle];
                NSString *tString = currentGroup.title;
                
                NSArray *scaleArray = [self fetchScales:tString];
                
                if (currentSwitch.on) 
                {
                    // Add to tempDict
                    [tempDictionary setObject:scaleArray forKey:tString];
                }
            }
            NSDictionary *groupScalesDictionary = [NSDictionary dictionaryWithDictionary:tempDictionary];
            
            viewSavedController.groupsScalesDictionary = groupScalesDictionary;
            viewSavedController.fileType = @"PDF";
            
            viewSavedController.fileAction = @"create";
            [self.navigationController pushViewController:viewSavedController animated:YES];   
            [viewSavedController release];
            [tempDictionary release];
            
            
            break;
        case enExportTypeCSV:
            // CSV
            [defaults setValue:@"csvSaved" forKey:@"csvSaved"];
            [self.navigationController popViewControllerAnimated:YES];
            break;
        default:
            break;
    }
}


#pragma mark ActionSheet
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    if (buttonIndex == actionSheet.firstOtherButtonIndex + 0) 
    {
        //    NSLog(@"Ummm.");
        
    } 
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    
    //   NSLog(@"button press: %i", buttonIndex);
    
    if (buttonIndex == actionSheet.firstOtherButtonIndex + enExportTypeCSV) 
    {
        // Export CSV
        // NSLog(@"Export CSV");
        whichExport = enExportTypeCSV;
        savingScreen.hidden = NO;
        [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(saveResults) userInfo:nil repeats:NO];
        
    } 
    else if (buttonIndex == actionSheet.firstOtherButtonIndex + enExportTypePDF) 
    {
        // Export PDF
        //  NSLog(@"Export PDF");
        whichExport = enExportTypePDF;
        savingScreen.hidden = NO;
        [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(saveResults) userInfo:nil repeats:NO];
        //[self emailResults];
    }
    /*
    else if (buttonIndex == actionSheet.firstOtherButtonIndex + 2) 
    {
        // Export CSV
        //  NSLog(@"Email CSV");
        whichExport = 1;
        savingScreen.hidden = NO;
      //  [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(saveResults) userInfo:nil repeats:NO];
        
        //[self emailResults];
    }
     else if (buttonIndex == actionSheet.firstOtherButtonIndex + 2) 
     {
     // Export PNG
     NSLog(@"Email PNG");
     [self emailResults];
     }
     */
}


#pragma mark Date Picker
- (void)slideDownDidStop
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	// the date picker has finished sliding downwards, so remove it
	[self.datePicker removeFromSuperview];
}

- (IBAction)dateAction:(id)sender
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	cell.detailTextLabel.text = [self.dateFormatter stringFromDate:self.datePicker.date];
    if ([cell.textLabel.text isEqualToString:@"Start Date"])
    {
        [textfieldArray replaceObjectAtIndex:0 withObject:cell.detailTextLabel.text];
    }
    else
    {
        [textfieldArray replaceObjectAtIndex:1 withObject:cell.detailTextLabel.text];
    }
    //NSLog(@"textfieldArray: %@", textfieldArray);   
    
}

- (void)resignPicker
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGRect endFrame = self.datePicker.frame;
	endFrame.origin.y = screenRect.origin.y + screenRect.size.height;
	
	// start the slide down animation
	[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
	
    // we need to perform some post operations after the animation is complete
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(slideDownDidStop)];
	
    self.datePicker.frame = endFrame;
	[UIView commitAnimations];
	
	// grow the table back again in vertical size to make room for the date picker
	CGRect newFrame = self.tableView.frame;
	newFrame.size.height += self.datePicker.frame.size.height;
	self.tableView.frame = newFrame;
	
	// remove the "Done" button in the nav bar
	self.navigationItem.rightBarButtonItem = nil;
	
	// deselect the current table row
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(generateReport:)];
	self.navigationItem.rightBarButtonItem = nextButton;    
    [nextButton release];
}

- (IBAction)doneAction:(id)sender
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    [self resignPicker];
}

- (void) showPDF
{
    NSLog(@"***** FUNCTION %s *****", __FUNCTION__);
    NSString *nibName = @"WebViewController";
    WebViewController *controller = [[WebViewController alloc] initWithNibName:nibName bundle:nil];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}
#pragma mark Fetched results controller
@end
