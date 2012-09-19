//
//  GraphDataSource.m
//  VAS002
//
//  Created by Melvin Manzano on 5/2/12.
//  Copyright (c) 2012 GDIT. All rights reserved.
//

#import "SGraphDataSource.h"
#import "VAS002AppDelegate.h"
#import "Result.h"
#import "FlurryUtility.h"
#import "VASAnalytics.h"
#import "ViewNotesViewController.h"
#import "Error.h"
#import "Note.h"
#import "Group.h"
#import "Scale.h"
#import "GroupResult.h"
#import "DateMath.h"

@implementation SGraphDataSource

@synthesize seriesData, seriesDates, dataDict;
@synthesize managedObjectContext;
@synthesize chartMonth;
@synthesize chartYear;
@synthesize dateSet;
@synthesize groupsDictionary;
@synthesize groupsArray;
@synthesize gregorian;
@synthesize notesForMonth;
@synthesize valuesArraysForMonth;
@synthesize switchDictionary, ledgendColorsDictionary, tempDict, symbolsDictionary;
@synthesize dataDictCopy, scalesArray, scalesDictionary, groupName, scalesUpdateDict;

int mySeriesCount;
bool gradientOn;
bool symbolOn;
bool isToggle;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialize the calendar
        cal = [[NSCalendar currentCalendar] retain];
        stepLineMode = NO;
        gradientMode = NO;
        gradientOn = NO;
        symbolOn = NO;
        
        UIApplication *app = [UIApplication sharedApplication];
        VAS002AppDelegate *appDelegate = (VAS002AppDelegate *)[app delegate];
        self.managedObjectContext = appDelegate.managedObjectContext;
        
        // Setup Data
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.groupName = [defaults objectForKey:@"subGraphSelected"];
        [self fillScalesDictionary];
        [self fillColors];
        [self fillSymbols];
        [self createSwitches];
        seriesData = [[NSMutableArray alloc] init];
        seriesDates = [[NSMutableArray alloc] init];
        
        
        // Pull all data; Initial
        if (self.dataDict == nil) 
        {
            self.dataDict = [NSMutableDictionary dictionaryWithDictionary:[self getChartDictionary]];
          //  NSLog(@"dataDict: %@", dataDict);        
        }
        
        // Make backup copy of data
        if (self.dataDictCopy == nil) 
        {
            self.dataDictCopy = [NSMutableDictionary dictionaryWithDictionary:dataDict];
        }
        
        mySeriesCount = [[dataDictCopy allKeys] count];
        isToggle = NO;
        [self printData];
        
    }
    return self;
}

- (void)toggleSeries;
{
    
    [self createSwitches];
    
}

- (void)toggleGradient
{
    gradientMode = !gradientMode;
    isToggle = YES;
}

- (void)toggleSymbol
{
    symbolMode = !symbolMode;
    isToggle = YES;

}


- (void) printData
{
    //   NSLog(@"dataDict: %@", dataDict);
}

- (NSDate *)dateFromString:(NSString *)str
{
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd-MMM-yyyy HH:mm:ss ZZZ"];
    NSDate *myDate = [df dateFromString: str];
    [df release];
    
    
    return myDate;
}
#pragma mark Data


#pragma mark Groups
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
		for (NSString *gName in sortedKeys) {
			[grpArray addObject:[self.groupsDictionary objectForKey:gName]];
		}
		self.groupsArray = [NSArray arrayWithArray:grpArray];
        // NSLog(@"grpArray: %@", grpArray);
	}
}


#pragma mark fill symbols
- (void)fillSymbols
{
	if (self.symbolsDictionary == nil) {
		self.symbolsDictionary = [NSMutableDictionary dictionary];
		
		NSArray *objects = [self.scalesDictionary allKeys];
		NSInteger index = 0;
		
		for (NSString *groupTitle in objects) {
            
			UIImage *image = [self UIImageForIndex:index];
            
			[self.symbolsDictionary setObject:image forKey:groupTitle];
			index++;
		}
	}    
    // NSLog(@"symbolsDictionary: %@", symbolsDictionary);
}

-(UIImage *)UIImageForIndex:(NSInteger)index {
	NSArray *imageArray = [NSArray arrayWithObjects:[UIImage imageNamed:@"Symbol_Clover.png"], [UIImage imageNamed:@"Symbol_Club.png"], [UIImage imageNamed:@"Symbol_Cross.png"], [UIImage imageNamed:@"Symbol_Davidstar.png"], [UIImage imageNamed:@"Symbol_Diamondclassic.png"], [UIImage imageNamed:@"Symbol_Diamondring.png"], [UIImage imageNamed:@"Symbol_Doublehook.png"], [UIImage imageNamed:@"Symbol_Fivestar.png"], [UIImage imageNamed:@"Symbol_Heart.png"], [UIImage imageNamed:@"Symbol_Triangle.png"], [UIImage imageNamed:@"Symbol_Circle.png"], [UIImage imageNamed:@"Symbol_Hourglass.png"], [UIImage imageNamed:@"Symbol_Moon.png"], [UIImage imageNamed:@"Symbol_Skew.png"], [UIImage imageNamed:@"Symbol_Pentagon.png"], [UIImage imageNamed:@"Symbol_Spade.png"], nil];
	
	UIImage *image = nil;
	///NSLog(@"imageArray: %@", imageArray);
    // Perm fix for color bug from v2.0; 5/17/2012 Mel Manzano
	if (index >=0 && index < [imageArray count]) {
		image = [imageArray objectAtIndex:index];
		[[image retain] autorelease];
	}
    else // If index is > color array count, then start over.
    {
        // Split index into digits via array
        NSString *stringNumber = [NSString stringWithFormat:@"%i", index];
        NSMutableArray *digits = [NSMutableArray arrayWithCapacity:[stringNumber length]];
        const char *cstring = [stringNumber cStringUsingEncoding:NSASCIIStringEncoding];
        while (*cstring) {
            if (isdigit(*cstring)) {
                [digits addObject:[NSString stringWithFormat:@"%c", *cstring]];
            }
            cstring++;
        }
        
        // Take last digit in array and use for color selection
        int lastDigit = [digits count] - 1;
        int overCount = [[digits objectAtIndex:lastDigit] intValue];
        image = [imageArray objectAtIndex:overCount];
    }
    
	return image;
}

#pragma mark fill scales

- (void)fillScalesDictionary {
	if (self.scalesDictionary == nil) {
      //  NSLog(@"groupname: (%@)", self.groupName);
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSPredicate *groupPredicate = [NSPredicate predicateWithFormat:@"group.title like %@",self.groupName];
		NSArray *predicateArray = [NSArray arrayWithObjects:groupPredicate, nil];
		NSPredicate *finalPredicate = [NSCompoundPredicate	andPredicateWithSubpredicates:predicateArray];
		[fetchRequest setPredicate:finalPredicate];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Scale" inManagedObjectContext:self.managedObjectContext];
		[fetchRequest setEntity:entity];
		
		NSMutableDictionary *scales = [NSMutableDictionary dictionary];
		NSError *error = nil;
		NSArray *objects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		if (!error) {
			for (Scale *aScale in objects) {
				[scales setObject:aScale forKey:aScale.minLabel];
			}
			self.scalesDictionary = [NSDictionary dictionaryWithDictionary:scales];
			
			NSArray *keys = [self.scalesDictionary allKeys];
			NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
			
			NSMutableArray *sclArray = [NSMutableArray array];
			for (NSString *minLabel in sortedKeys) {
                if ([minLabel isEqualToString:@""]) 
                {
                    
                }
                else 
                {
                    [sclArray addObject:[self.scalesDictionary objectForKey:minLabel]];
                    
                }
			}
			self.scalesArray = [NSArray arrayWithArray:sclArray];
		}
		else {
			[Error showErrorByAppendingString:@"Unable to fetch scale data" withError:error];
		}
		
		[fetchRequest release];
	}
    
   // NSLog(@"scalesDictionary: %@", scalesDictionary);

    
}

#pragma mark colors

-(UIColor *)UIColorForIndex:(NSInteger)index {
	NSArray *colorsArray = [NSArray arrayWithObjects:[UIColor blueColor], [UIColor greenColor], [UIColor orangeColor], [UIColor redColor], [UIColor purpleColor], [UIColor grayColor], [UIColor brownColor], [UIColor cyanColor], [UIColor magentaColor], [UIColor lightGrayColor], nil];
	
	UIColor *color = nil;
	
    // Perm fix for color bug from v2.0; 5/17/2012 Mel Manzano
	if (index >=0 && index < [colorsArray count]) {
		color = [colorsArray objectAtIndex:index];
		[[color retain] autorelease];
	}
    else // If index is > color array count, then start over.
    {
        // Split index into digits via array
        NSString *stringNumber = [NSString stringWithFormat:@"%i", index];
        NSMutableArray *digits = [NSMutableArray arrayWithCapacity:[stringNumber length]];
        const char *cstring = [stringNumber cStringUsingEncoding:NSASCIIStringEncoding];
        while (*cstring) {
            if (isdigit(*cstring)) {
                [digits addObject:[NSString stringWithFormat:@"%c", *cstring]];
            }
            cstring++;
        }
        
        // Take last digit in array and use for color selection
        int lastDigit = [digits count] - 1;
        int overCount = [[digits objectAtIndex:lastDigit] intValue];
        color = [colorsArray objectAtIndex:overCount];
    }
    
	return color;
}

- (void)fillColors {
	if (self.ledgendColorsDictionary == nil) {
		self.ledgendColorsDictionary = [NSMutableDictionary dictionary];
		
		NSArray *objects = [self.scalesDictionary allKeys];
		NSInteger index = 0;
		
		for (NSString *groupTitle in objects) {
			UIColor *color = [self UIColorForIndex:index];
			[self.ledgendColorsDictionary setObject:color forKey:groupTitle];
			index++;
		}
	}
    
    // NSLog(@"colorDict: %@", ledgendColorsDictionary);
}

-(void)createSwitches {
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
		
		NSArray *grpArray = [[self.scalesDictionary allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
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

#pragma mark Get Chart Dictionary
- (NSDictionary *)getChartDictionary
{
    // Get data range
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *defaultsKey;
    
    defaultsKey = [NSString stringWithFormat:@"SWITCH_OPTION_STATE_RANGE"];
    NSString *theRange = [defaults objectForKey:defaultsKey];
    NSDate *theFromDate = [[NSDate alloc] init];
    
    NSDateComponents *components = [cal components:( NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ) fromDate:theFromDate];
    
    // Today's Date
    [components setHour:-[components hour]];
    [components setMinute:-[components minute]];
    [components setSecond:-[components second]];
    NSDate *today;
    NSDate *fromDate;
    
    
    components = [cal components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:theFromDate];
    [components setDay:([components day] + 1)]; 
    today = [cal dateFromComponents:components];
    
    
    if ([theRange isEqualToString:@"30 days"]) 
    {
        components = [cal components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:theFromDate];
        [components setMonth:([components month] - 1)]; 
        fromDate = [cal dateFromComponents:components];
    }
    else if ([theRange isEqualToString:@"90 days"]) 
    {
        components = [cal components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:theFromDate];
        [components setMonth:([components month] - 3)]; 
        fromDate = [cal dateFromComponents:components];
    }
    else if ([theRange isEqualToString:@"180 days"]) 
    {
        components = [cal components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:theFromDate];
        [components setMonth:([components month] - 6)]; 
        fromDate = [cal dateFromComponents:components];
    }
    else if ([theRange isEqualToString:@"1 year"]) 
    {
        components = [cal components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:theFromDate];
        [components setYear:([components year] - 1)]; 
        fromDate = [cal dateFromComponents:components];
    }
    else // All and anything else
    {
        components = [cal components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:theFromDate];
        [components setMonth:([components month] - 1)]; 
        fromDate = [cal dateFromComponents:components];
    }
    [theFromDate release];
    
    NSMutableArray *arrayByDate = [[NSMutableArray alloc] init];
    [arrayByDate addObject:@"0"];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Result" inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
	
	// Create the sort descriptors array.
	NSSortDescriptor *yearDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"year" ascending:YES] autorelease];
	NSSortDescriptor *monthDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"month" ascending:YES] autorelease];
	NSSortDescriptor *dayDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"day" ascending:YES] autorelease];
	NSSortDescriptor *scaleDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"scale" ascending:YES] autorelease];
	
	NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:yearDescriptor, monthDescriptor,dayDescriptor, scaleDescriptor, nil] autorelease];
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	NSString *scalePredicateString = @"";
	
	NSArray *results;
	NSString *groupPredicateString;
	NSPredicate *groupPredicate;
	NSPredicate *scalePredicate;
	NSString *timePredicateString;
	NSPredicate *timePredicate;
	NSArray *finalPredicateArray;
	NSPredicate *finalPredicate;
    
    //NSLog(@"1");
	for (NSString *scaleMinLabel in self.scalesDictionary) 
    {
        groupPredicateString = [NSString stringWithFormat:@"group.title like %%@"];
        groupPredicate = [NSPredicate predicateWithFormat:groupPredicateString, groupName];
        scalePredicateString = [NSString stringWithFormat:@"scale.minLabel like %%@"];
        scalePredicate = [NSPredicate predicateWithFormat:scalePredicateString, scaleMinLabel];

        

        timePredicateString = [NSString stringWithFormat:@"(timestamp >= %%@) && (timestamp <= %%@)"];
        timePredicate = [NSPredicate predicateWithFormat:timePredicateString, fromDate, today];
        finalPredicateArray = [NSArray arrayWithObjects:groupPredicate,timePredicate, scalePredicate, nil];
        
			
        finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:finalPredicateArray];
        
        [fetchRequest setPredicate:finalPredicate];
        [fetchRequest setFetchBatchSize:0];
        
        NSError *error = nil;
        results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if (error) 
        {
            [Error showErrorByAppendingString:@"could not get result data for graph" withError:error];
        } 
        else 
        {
            NSMutableArray *tempTotalArray = [[[NSMutableArray alloc] init] autorelease];
            NSMutableArray *tempCountArray = [[[NSMutableArray alloc] init] autorelease];
            
            if (results.count > 0) 
            { 
                int value = 0;
                //int day = 0;
                //int month = 0;
               // int year = 0; 
                NSString *nn = @"";
               // NSString *monthStr = @"";
               // NSString *dayStr = @"";
                NSString *timeStamp = @"";

                // Set up temp arrays for averaging
                for (Result *groupResult in results) 
                {
                    timeStamp = [NSString stringWithFormat:@"%@",groupResult.timestamp];

                    value = [groupResult.value intValue];
                  //  day = [groupResult.day intValue] - 1;
                   // month = [groupResult.month intValue];
                   // year = [groupResult.year intValue]; 
                    nn = scaleMinLabel;
                    
                    //  NSLog(@"name: %@ value:%i day:%i month:%i year:%i", nn, value, day, month, year);
                    // Yah yah, dateformatter would have been better....
                    /*
                    if (month == 1) {monthStr = @"Jan";}
                    if (month == 2) {monthStr = @"Feb";}
                    if (month == 3) {monthStr = @"Mar";}
                    if (month == 4) {monthStr = @"Apr";}
                    if (month == 5) {monthStr = @"May";}
                    if (month == 6) {monthStr = @"Jun";}
                    if (month == 7) {monthStr = @"Jul";}
                    if (month == 8) {monthStr = @"Aug";}
                    if (month == 9) {monthStr = @"Sep";}
                    if (month == 10) {monthStr = @"Oct";}
                    if (month == 11) {monthStr = @"Nov";}
                    if (month == 12) {monthStr = @"Dec";}
                    
                    if ([[NSString stringWithFormat:@"%i",day] length] < 2) 
                    {
                        dayStr = [NSString stringWithFormat:@"0%i",day];
                    }
                    else 
                    {
                        dayStr = [NSString stringWithFormat:@"%i",day];
                    }
                    
                    // Convert Date 
                    NSString *dateString = [NSString stringWithFormat:@"%@-%@-%i", dayStr, monthStr, year];
                    */
                    
                    
                    // Format DateTime
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
                    NSDate *date  = [dateFormatter dateFromString:timeStamp];
                    
                    // Convert Date 
                    [dateFormatter setDateFormat:@"dd-MMM-yyyy HH:mm:ss ZZZ"];
                    NSString *newDate = [dateFormatter stringFromDate:date];
                    [dateFormatter release];
                    [tempTotalArray addObject:[NSString stringWithFormat:@"%@",newDate]];
                    [tempTotalArray addObject:[NSString stringWithFormat:@"%i",value]];
                    [tempTotalArray addObject:[NSString stringWithFormat:@"%@",nn]];
                    
                    [tempCountArray addObject:[NSString stringWithFormat:@"%@",newDate]];
                    [tempCountArray addObject:[NSString stringWithFormat:@"%i",value]];
                    [tempCountArray addObject:[NSString stringWithFormat:@"%@",nn]];
                    
                }
                
                bool doesExist = NO;
                
                for (int i = 0; i < tempTotalArray.count; i+=3) 
                {
                    doesExist = NO;
                    
                    for (int a = 0; a < arrayByDate.count; a++) 
                    {
                        //NSLog(@"arrayByDate:%@ count:%i",[arrayByDate objectAtIndex:a], a);
                        //NSLog(@"tempTotalArray:%@ count:%i",[tempTotalArray objectAtIndex:i], i);
                        
                        
                        
                        if ([[arrayByDate objectAtIndex:a] isEqualToString:[tempTotalArray objectAtIndex:i]] && [[arrayByDate objectAtIndex:a + 3] isEqualToString:[tempTotalArray objectAtIndex:i + 2]])
                        {
                            doesExist = YES;
                            
                            // Update array; Add value to total; 
                            [arrayByDate replaceObjectAtIndex:a + 1 withObject:[NSString stringWithFormat:@"%i",[[arrayByDate objectAtIndex:a + 1] intValue] + [[tempTotalArray objectAtIndex:i + 1] intValue]]];
                            // +1 to value count
                            [arrayByDate replaceObjectAtIndex:a + 2 withObject:[NSString stringWithFormat:@"%i",[[arrayByDate objectAtIndex:a + 2] intValue] + 1]];
                            
                        }
                    }
                    
                    if (!doesExist) 
                    {
                        // Add to array
                        [arrayByDate addObject:[tempTotalArray objectAtIndex:i]];
                        [arrayByDate addObject:[tempTotalArray objectAtIndex:i + 1]];
                        [arrayByDate addObject:@"1"];
                        [arrayByDate addObject:[NSString stringWithFormat:@"%@",nn]];
                    }
                }
                
                
                
            } // Results    
            
        }			
		
	}
	
    
    // Raw Data rawValuesArray
    //NSLog(@"arrayByDate: %@", arrayByDate);

    NSArray *objects = [self.scalesDictionary allKeys];
    NSMutableDictionary *chartDictionary = [[[NSMutableDictionary alloc] init] autorelease];
    
    
    for (NSString *groupTitle in objects)
    {
        NSMutableArray *rawValuesArray = [[[NSMutableArray alloc] init] autorelease];
        NSMutableArray *dataArray = [[[NSMutableArray alloc] init] autorelease];
        NSMutableArray *dateArray = [[[NSMutableArray alloc] init] autorelease];
        NSMutableDictionary *valueDict = [[[NSMutableDictionary alloc] init] autorelease];
        int averageValue = 0;
      //  NSString *tempDate = @"";
        
        for (int i = 1; i < [arrayByDate count]; i+=4) 
        {
            // Average
            averageValue = [[arrayByDate objectAtIndex:i + 1] intValue] / [[arrayByDate objectAtIndex:i + 2] intValue];
           // tempDate = [arrayByDate objectAtIndex:i];
            [rawValuesArray addObject:[arrayByDate objectAtIndex:i + 3]];
            [rawValuesArray addObject:[arrayByDate objectAtIndex:i]];
            [rawValuesArray addObject:[NSString stringWithFormat:@"%i", averageValue]];
        }
        
        // Build components of final dictionary
        
        // Make arrays
        for (int i = 0; i < [rawValuesArray count]; i+=3) 
        {
            if ([[rawValuesArray objectAtIndex:i] isEqualToString:groupTitle]) 
            {
                [dataArray addObject:[rawValuesArray objectAtIndex:i + 2]];
                [dateArray addObject:[rawValuesArray objectAtIndex:i + 1]];
            }
        }
        
        [valueDict setObject:dataArray forKey:@"data"];
        [valueDict setObject:dateArray forKey:@"date"];
        if ([groupTitle isEqualToString:@""]) 
        {
            
        }
        else 
        {
            [chartDictionary setObject:valueDict forKey:groupTitle];

        }
        
    }    
    
    
	//[yearDescriptor release];
	//[monthDescriptor release];
	//[dayDescriptor release];
	//[groupTitleDescriptor release];
	//[sortDescriptors release];
	[fetchRequest release];
    [arrayByDate release];
    
    //NSLog(@"chartDictionary:%@",chartDictionary);
    
    return chartDictionary;
}


#pragma mark helpers

- (void) dealloc {
	[cal release];
	[super dealloc];
}

-(void)toggleSeriesType {
    stepLineMode = !stepLineMode;
}

- (int) getSeriesDataCount:(int) seriesIndex
{
    int seriesDataCount = 1;
    NSString *grpName = [[scalesArray objectAtIndex:seriesIndex] minLabel];
    
    NSDictionary *tempGrpDict = [NSDictionary dictionaryWithDictionary:[dataDictCopy objectForKey:grpName]];
    
    NSArray *tempGrpArray = [NSArray arrayWithArray:[tempGrpDict objectForKey:@"data"]]; 
    
    seriesDataCount = [tempGrpArray count];
    
    // NSLog(@"seriesDataCount: %i", seriesDataCount);
    return seriesDataCount;
}

#pragma mark -
#pragma mark Datasource Protocol Functions

// Returns the number of points for a specific series in the specified chart
- (int)sChart:(ShinobiChart *)chart numberOfDataPointsForSeriesAtIndex:(int)seriesIndex {
    //In our example, all series have the same number of points
    int numPoints = 0;  
    
    
    // Limit the points to 500/group
    numPoints = [self getSeriesDataCount:seriesIndex];
    
    return numPoints;
}

// Returns the series at the specified index for a given chart
-(SChartSeries *)sChart:(ShinobiChart *)chart seriesAtIndex:(int)index 
{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *tSymbolDict = [NSDictionary dictionaryWithDictionary:[defaults objectForKey:@"LEGEND_SUB_SYMBOL_DICTIONARY"]];
    NSDictionary *tColorDict = [NSDictionary dictionaryWithDictionary:[defaults objectForKey:@"LEGEND_SUB_COLOR_DICTIONARY"]];
    
    // Our series are either of type SChartLineSeries or SChartStepLineSeries depending on stepLineMode.
    SChartLineSeries *lineSeries = stepLineMode? 
    [[[SChartStepLineSeries alloc] init] autorelease]:
    [[[SChartLineSeries alloc] init] autorelease];
    
    lineSeries.style.lineWidth = [NSNumber numberWithInt: 2];
    
    // Symbol size depending on device
    NSNumber *symbolSize = [NSNumber numberWithInt:5];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        symbolSize = [NSNumber numberWithInt:8];
    } 
    
    NSDictionary *symbolDictionary = [tSymbolDict objectForKey:self.groupName];
    NSDictionary *colorDictionary = [tColorDict objectForKey:self.groupName];
    NSString *grpName = [[scalesArray objectAtIndex:index] minLabel];
    
    
    NSData *data = [colorDictionary objectForKey:grpName];
    UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    UIImage *image = [self UIImageForIndex:[[symbolDictionary objectForKey:grpName] intValue]];
    
    if (!isToggle)
    {
        if (![defaults objectForKey:@"SWITCH_OPTION_STATE_SYMBOL"]) {
            symbolMode = NO;
        }
        else 
        {
            symbolMode = YES;				
        }
        
        if (![defaults objectForKey:@"SWITCH_OPTION_STATE_GRADIENT"]) {
            gradientMode = NO;
        }
        else 
        {
            gradientMode = YES;				
        }
        
    }

    // Symbol
    lineSeries.style.pointStyle.texture = image;
    lineSeries.style.pointStyle.radius = symbolSize;
    lineSeries.style.pointStyle.showPoints = symbolMode?YES:NO;
    [lineSeries setTitle:grpName];
    lineSeries.baseline = [NSNumber numberWithInt:0];
    
    // Gradient
    lineSeries.style.showFill = gradientMode?YES:NO;
    lineSeries.crosshairEnabled = NO;  
    
    // Series On/Off
    NSString *myKey = [NSString stringWithFormat:@"SWITCH_STATE_%@",grpName];
    NSNumber *mySwitch = [defaults objectForKey:myKey];
    BOOL myBoolSwitch = [defaults boolForKey:myKey];
    if (mySwitch == nil) 
    {
        lineSeries.style.lineColor = color;
        lineSeries.style.pointStyle.color = color;
        lineSeries.style.areaColor = color;
        
    }
    else 
    {
        if (!myBoolSwitch) // is Off
        {
            lineSeries.style.pointStyle.color = [UIColor clearColor];
            lineSeries.style.lineColor = [UIColor clearColor];
            lineSeries.style.areaColor = [UIColor clearColor];
            
        }
        else 
        {
            lineSeries.style.lineColor = color;
            lineSeries.style.pointStyle.color = color;
            lineSeries.style.areaColor = color;
        }
    }
    
    
    return lineSeries;
}

// Returns the number of series in the specified chart
- (int)numberOfSeriesInSChart:(ShinobiChart *)chart 
{
    return mySeriesCount;
}

// Returns the data point at the specified index for the given series/chart.
- (id<SChartData>)sChart:(ShinobiChart *)chart dataPointAtIndex:(int)dataIndex forSeriesAtIndex:(int)seriesIndex {
    
    
    NSString *grpName = [[scalesArray objectAtIndex:seriesIndex] minLabel];
    NSDictionary *tempGrpDict = [NSDictionary dictionaryWithDictionary:[dataDictCopy objectForKey:grpName]];
    seriesData = [NSArray arrayWithArray:[tempGrpDict objectForKey:@"data"]]; 
    seriesDates = [NSArray arrayWithArray:[tempGrpDict objectForKey:@"date"]]; 
    
   // NSLog(@"tempGrpDict: %@", tempGrpDict);
    
    // Construct a data point to return
    SChartDataPoint *datapoint = [[[SChartDataPoint alloc] init] autorelease];
    
    // For this example, we simply move one day forward for each dataIndex
    NSString * dateString = [seriesDates objectAtIndex:dataIndex];
    NSDate *date = [self dateFromString:dateString];
    
    datapoint.xValue = date;
    // datapoint.xValue = [series2Dates objectAtIndex:dataIndex];
    
    // Construct an NSNumber for the yValue of the data point
    datapoint.yValue = [NSNumber numberWithFloat:[[seriesData objectAtIndex:dataIndex] floatValue]];
    // datapoint.yValue = [NSNumber numberWithFloat:[[series2Data objectAtIndex:dataIndex] floatValue] - 10000.f];
    
    // NSLog(@"series: %i", seriesIndex);
    //NSLog(@"xPlot: %@", date);
    //NSLog(@"yPlot: %@", [NSNumber numberWithFloat:[[seriesData objectAtIndex:dataIndex] floatValue]]);
    
    return datapoint;
}

/*
 - (UIImage *)sChartTextureForPoint:(ShinobiChart *)chart dataPointAtIndex:(int)dataIndex forSeriesAtIndex:(int)seriesIndex
 {
 UIImage *plotImage = [UIImage imageNamed:@"sliderknob.png"];
 
 return plotImage;  
 }
 */
@end
