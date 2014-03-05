//
//  OTRConversationCell.m
//  Off the Record
//
//  Created by David Chiles on 3/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRConversationCell.h"
#import "OTRManagedBuddy.h"
#import "OTRManagedAccount.h"
#import "OTRManagedMessage.h"

@interface OTRConversationCell ()

@property (nonatomic, strong) NSArray *verticalConstraints;
@property (nonatomic, strong) NSArray *accountHorizontalConstraints;
@property (nonatomic, strong) NSDate *displayDate;
@property (nonatomic, strong) NSTimer * dateUpdateTimer;

@end

@implementation OTRConversationCell

- (void)dealloc
{
    [_dateUpdateTimer invalidate];
    _dateUpdateTimer = nil;
}

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.showAccountLabel = NO;
        
        UIColor *darkGreyColor = [UIColor colorWithWhite:.45 alpha:1.0];
        UIColor *lightGreyColor = [UIColor colorWithWhite:.6 alpha:1.0];
        self.dateLabel = [[UILabel alloc] init];
        self.dateLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        self.dateLabel.textColor = darkGreyColor;
        self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]+2.0];
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.nameLabel.textColor = darkGreyColor;
        
        self.conversationLabel = [[UILabel alloc] init];
        self.conversationLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.conversationLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.conversationLabel.numberOfLines = 0;
        self.conversationLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        self.conversationLabel.textColor = lightGreyColor;
        
        self.accountLabel = [[UILabel alloc] init];
        self.accountLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        
        [self.contentView addSubview:self.dateLabel];
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.conversationLabel];
        
    }
    NSLog(@"Self init Cell: %@",self);
    return self;
}

- (void)setShowAccountLabel:(BOOL)showAccountLabel
{
    _showAccountLabel = showAccountLabel;
    
    if (!self.showAccountLabel) {
        [self.accountLabel removeFromSuperview];
    }
    else {
        [self.contentView addSubview:self.accountLabel];
    }
}

- (void)setBuddy:(OTRManagedBuddy *)buddy
{
    NSLog(@"Set Buddy: %@ - %@",buddy.displayName,buddy.accountName);
    NSLog(@"Self setBuddy Cell: %@",self);
    [super setBuddy:buddy];
    NSString * nameString = nil;
    if (buddy.displayName.length) {
        nameString = buddy.displayName;
    }
    else {
        nameString = buddy.accountName;
    }
    self.nameLabel.text = nameString;
    
    
    self.accountLabel.text = buddy.account.username;
    
    OTRManagedMessage * lastMessage = [[buddy.messages sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:OTRManagedMessageAndStatusAttributes.date ascending:YES]]] lastObject];
    
    UIFont *currentFont = self.conversationLabel.font;
    CGFloat fontSize = currentFont.pointSize;
    self.conversationLabel.text = lastMessage.message;
    if (!lastMessage.isReadValue) {
        //unread message
        self.nameLabel.font = [UIFont boldSystemFontOfSize:fontSize];
        self.nameLabel.textColor = [UIColor blackColor];
        
    }
    else {
        self.nameLabel.font = [UIFont systemFontOfSize:fontSize];
        self.nameLabel.textColor = [UIColor colorWithWhite:.45 alpha:1.0];
    }
    self.dateLabel.textColor = self.nameLabel.textColor;
    
    self.displayDate = lastMessage.date;
    [self.dateUpdateTimer invalidate];
    self.dateUpdateTimer = nil;
    [self updateDateString:self];
}

- (void)updateDateString:(id)sender
{
    NSLog(@"Update Timer For: %@",self.nameLabel.text);
    NSLog(@"Self updateDateString Cell: %@",self);
    NSTimeInterval timeInterval = fabs([self.displayDate timeIntervalSinceNow]);
    if (timeInterval <= 60*60*24 && !self.dateUpdateTimer) {
        //update every minute for the first 24 hours
        [self.dateUpdateTimer invalidate];
        self.dateUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateDateString:) userInfo:nil repeats:YES];
    }
    else if (timeInterval > 60*60*24 && self.dateUpdateTimer) {
        [self.dateUpdateTimer invalidate];
        self.dateUpdateTimer = nil;
    }
    self.dateLabel.text = [self dateString:self.displayDate];
}

- (NSString *)dateString:(NSDate *)messageDate
{
    NSTimeInterval timeInterval = fabs([messageDate timeIntervalSinceNow]);
    NSString * dateString = nil;
    if (timeInterval < 60){
        dateString = @"Now";
    }
    else if (timeInterval < 60*60) {
        int minsInt = timeInterval/60;
        NSString * minString = @"mins";
        if (minsInt == 1) {
            minString = @"min";
        }
        dateString = [NSString stringWithFormat:@"%d %@",minsInt,minString];
    }
    else if (timeInterval < 60*60*24){
        // show time in format 11:00 PM
        dateString = [NSDateFormatter localizedStringFromDate:messageDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    }
    else if (timeInterval < 60*60*24*7) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEE" options:0 locale:[NSLocale currentLocale]];
        dateString = [dateFormatter stringFromDate:messageDate];
        
    }
    else if (timeInterval < 60*60*25*365) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMM" options:0
                                                                   locale:[NSLocale currentLocale]];
        dateString = [dateFormatter stringFromDate:messageDate];
    }
    else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMMYYYY" options:0
                                                                    locale:[NSLocale currentLocale]];
        dateString = [dateFormatter stringFromDate:messageDate];
    }
    
    
    
    return dateString;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.dateUpdateTimer invalidate];
    self.dateUpdateTimer = nil;
    NSLog(@"Prepare For Reuse: %@ %@",self.nameLabel.text,self);
}

- (void)updateConstraints
{
    [super updateConstraints];
    NSDictionary *views = @{@"imageView": self.avatarImageView,
                            @"conversationLabel": self.conversationLabel,
                            @"dateLabel":self.dateLabel,
                            @"nameLabel":self.nameLabel,
                            @"conversationLabel":self.conversationLabel,
                            @"accountLabel":self.accountLabel};
    
    NSDictionary *metrics = @{@"margin":[NSNumber numberWithFloat:OTRBuddyImageCellPadding]};
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView]-margin-[nameLabel]->=0-[dateLabel]-margin-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView]-margin-[conversationLabel]-margin-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[dateLabel]" options:0 metrics:metrics
                                                                               views:views]];
    
    if([self.accountHorizontalConstraints count])
    {
        [self.contentView removeConstraints:self.accountHorizontalConstraints];
    }
    
    if([self.verticalConstraints count]) {
        [self.contentView removeConstraints:self.verticalConstraints];
    }

    if (self.showAccountLabel) {
        self.accountHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView]-margin-[accountLabel]|"
                                                                                    options:0
                                                                                    metrics:metrics
                                                                                      views:views];
        
        self.verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[nameLabel][conversationLabel][accountLabel]-margin-|"
                                                                           options:0
                                                                            metrics:metrics
                                                                            views:views];
        
    }
    else {
        self.accountHorizontalConstraints = @[];
        
        self.verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[nameLabel(<=15)][conversationLabel]-margin-|"
                                                                           options:0
                                                                           metrics:metrics
                                                                             views:views];
    }
    if([self.accountHorizontalConstraints count]) {
        [self.contentView addConstraints:self.accountHorizontalConstraints];
    }
    
    [self.contentView addConstraints:self.verticalConstraints];
    
    
    
}

@end
