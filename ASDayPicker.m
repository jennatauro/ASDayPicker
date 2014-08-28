//
// ASDayPicker
// http://github.com/appscape/ASDayPicker
//
// Copyright (c) 2014 appscape. All rights reserved.
//

#import "ASDayPicker.h"

static const UIEdgeInsets kDefaultInsets = {0,6.0f,0,6.0f};
static const CGFloat kWeekdayLabelHeight = 20.0f;

@interface ASDayPicker()<UIScrollViewDelegate> {
    NSCalendar *_calendar;

    NSArray *_weekdayTitles;
    NSMutableArray *_weekdayLabels;

    UIScrollView *_daysScrollView;

    CGFloat _dx, _dh;
    CGFloat _scrollStartOffsetX;

    NSMutableArray *_days;
    UIButton *_lastSelectedButton;
}
@property (nonatomic, strong) NSDate *selectedDate;
@end

@implementation ASDayPicker

- (void)setup {
    _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

    _edgeInsets = kDefaultInsets;

    _daysScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _daysScrollView.showsHorizontalScrollIndicator = NO;
    _daysScrollView.pagingEnabled = YES;
    _daysScrollView.delegate = self;

    [self addSubview:_daysScrollView];

    _weekdayLabels = [NSMutableArray array];
    for (NSUInteger i = 0;i<7;i++) {
        UILabel *l = [[UILabel alloc] initWithFrame:CGRectZero];
        l.textAlignment = NSTextAlignmentCenter;
        [_weekdayLabels addObject:l];
        [self addSubview:l];
    }

    _selectedDate = [self dateWithoutTimeFromDate:[NSDate date]];

    self.weekdayTitles = [ASDayPicker weekdayTitlesWithLocaleIdentifier:nil
                                                                 length:1
                                                              uppercase:YES];

    self.selectedDateBackgroundImage = [ASDayPicker imageWithColor:self.tintColor];
    self.selectedDateTextColor = [UIColor whiteColor];
    self.dateTextColor = [UIColor blackColor];
    self.outOfRangeDateTextColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
    self.dateFont = [UIFont systemFontOfSize:17.0f];
    self.weekdayFont = [UIFont systemFontOfSize:12.0f];
    self.weekdayTextColor = [UIColor blackColor];
}

- (void)setSelectedDateBackgroundColor:(UIColor *)selectedDateBackgroundColor {
    _selectedDateBackgroundColor = selectedDateBackgroundColor;
    self.selectedDateBackgroundImage = [ASDayPicker imageWithColor:selectedDateBackgroundColor];
}

- (void)setSelectedDateBackgroundImage:(UIImage *)selectedDateBackgroundImage {
    _selectedDateBackgroundImage = selectedDateBackgroundImage;
    [self setNeedsLayout];
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets {
    _edgeInsets = edgeInsets;
    [self setNeedsLayout];
}

- (void)setWeekdayColor:(UIColor *)color {
    _weekdayTextColor = color;
    for (UILabel *l in _weekdayLabels) {
        l.textColor = color;
    }
}

- (void)setWeekdayTitles:(NSArray *)weekdayTitles {
    NSParameterAssert(weekdayTitles.count == 7);
    _weekdayTitles = weekdayTitles;
    for (int i=0;i<7;i++) {
        ((UILabel*)_weekdayLabels[i]).text = _weekdayTitles[i];
    }
}

- (void)setWeekdayTextColor:(UIColor *)weekdayTextColor {
    _weekdayTextColor = weekdayTextColor;
    for (int i=0;i<7;i++) {
        ((UILabel*)_weekdayLabels[i]).textColor = _weekdayTextColor;
    }
}

- (void)setWeekdayFont:(UIFont *)font {
    _weekdayFont = font;
    for (int i=0;i<7;i++) {
        ((UILabel*)_weekdayLabels[i]).font = _weekdayFont;
    }
}


- (void)awakeFromNib {
    [self setup];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)layoutSubviews {
    _dh = self.frame.size.height - kWeekdayLabelHeight;
    _daysScrollView.frame = CGRectMake(0,0,self.frame.size.width,self.frame.size.height);

    _dx = (self.frame.size.width - (_edgeInsets.left + _edgeInsets.right)) / 7.0f;
    for (NSUInteger i=0;i<7;i++) {
        UILabel *l = _weekdayLabels[i];
        l.frame = CGRectMake(_edgeInsets.left + _dx * i, 0, _dx, kWeekdayLabelHeight);
    }

    [self recenter];
}

- (UIButton*)buttonForDate:(NSDate*)date index:(NSUInteger)index {
    UIButton *b = [[UIButton alloc] init];
    [b setTitleColor:self.outOfRangeDateTextColor forState:UIControlStateDisabled];
    [b setTitleColor:self.dateTextColor forState:UIControlStateNormal];
    [b setTitleColor:self.selectedDateTextColor forState:UIControlStateSelected];
    [b setBackgroundImage:self.selectedDateBackgroundImage forState:UIControlStateSelected];
    [b.titleLabel setFont:self.dateFont];
    [b.titleLabel setTextAlignment:NSTextAlignmentCenter];

    b.selected = [date isEqualToDate:_selectedDate];

    if ((_startDate && [date compare:_startDate] == NSOrderedAscending) ||
        (_endDate && [date compare:_endDate] == NSOrderedDescending)) {
        b.enabled = NO;
    }

    b.tag = index;

//    b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
//    b.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    NSDateComponents *components = [_calendar components:NSDayCalendarUnit fromDate:date];
    [b setTitle:[NSString stringWithFormat:@"%ld", (long)components.day] forState:UIControlStateNormal];

    [b addTarget:self action:@selector(dayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    return b;
}

- (void)dayButtonPressed:(UIButton*)sender {
    _lastSelectedButton.selected = NO;
    sender.selected = YES;
    _lastSelectedButton = sender;
    self.selectedDate = _days[sender.tag];
}

- (void)recenter {
    for (UIView *v in _daysScrollView.subviews) {
        [v removeFromSuperview];
    }

    _days = [NSMutableArray array];

    NSInteger fromIndex = -1;
    NSInteger toIndex = 1;

    if (_startDate) {
        NSDateComponents *weeks = [[NSDateComponents alloc] init];
        weeks.week = -1;
        NSDate *prevDate = [_calendar dateByAddingComponents:weeks toDate:_selectedDate options:0];
        if ([prevDate compare:_startDate] == NSOrderedAscending) {
            fromIndex = 0;
        }

    }
    
    if (_endDate) {
        NSDateComponents *weeks = [[NSDateComponents alloc] init];
        weeks.week = 1;
        NSDate *nextDate = [_calendar dateByAddingComponents:weeks toDate:_selectedDate options:0];
        if ([nextDate compare:_endDate] == NSOrderedDescending) {
            toIndex = 0;
        }
    }

    for (NSInteger i=fromIndex;i<=toIndex;i++) {
        NSArray *days = [self daysForWeekAtIndex:i];
        for (NSUInteger j=0;j<days.count;j++) {
            UIButton *b = [self buttonForDate:days[j] index:_days.count];
            [_days addObject:days[j]];
            b.frame = CGRectMake(_edgeInsets.left+(i-fromIndex)*self.frame.size.width+j*_dx,kWeekdayLabelHeight,_dx,_dh);
            if (b.selected) {
                _lastSelectedButton = b;
            }
            [_daysScrollView addSubview:b];
        }
    }

    NSInteger pages = (toIndex - fromIndex) + 1;

    _daysScrollView.contentSize = CGSizeMake(pages * self.frame.size.width, self.frame.size.height);

    _daysScrollView.contentOffset = CGPointMake(fromIndex != 0 ? self.frame.size.width : 0, 0);
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    scrollView.userInteractionEnabled = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger dir = 0;
    CGFloat dx = scrollView.contentOffset.x - _scrollStartOffsetX;
    if (dx > 0) {
        dir = 1;
    } else if (dx < 0 ){
        dir = -1;
    }

    if (dir != 0) {
        NSDateComponents *weeks = [[NSDateComponents alloc] init];
        weeks.week = dir;
        NSDate *date = [_calendar dateByAddingComponents:weeks toDate:_selectedDate options:0];

        // Clip to range
        if ((_startDate && [date compare:_startDate] == NSOrderedAscending)) {
            date = _startDate;
        } else if (_endDate && [date compare:_endDate] == NSOrderedDescending) {
            date = _endDate;
        }

        self.selectedDate = date;

        [self recenter];
    }

    scrollView.userInteractionEnabled = YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _scrollStartOffsetX = scrollView.contentOffset.x;
}

- (void)setStartDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    NSParameterAssert(!startDate || !endDate || [endDate compare:startDate] != NSOrderedAscending);
    _startDate = [self dateWithoutTimeFromDate:startDate];
    _endDate = [self dateWithoutTimeFromDate:endDate];
    [self setNeedsLayout];
}

// i=0: week containing _selectedDate, i=-1: week before, i=1 week after etc.
- (NSArray*)daysForWeekAtIndex:(NSInteger)i {
    NSDateComponents *weeks = [[NSDateComponents alloc] init];
    weeks.week = i;

    NSDate *d = [_calendar dateByAddingComponents:weeks toDate:_selectedDate options:0];

    NSDateComponents *components = [_calendar components:NSWeekdayCalendarUnit fromDate:d];
    NSInteger before = components.weekday - 2;
    if (before < 0) before = 7 + before;
    NSInteger after = 6 - before;

    NSMutableArray *result = [NSMutableArray array];

    for (NSUInteger i = before;i>0;i--) {
        NSDateComponents *days = [[NSDateComponents alloc] init];
        days.day = -1 * i;
        [result addObject:[_calendar dateByAddingComponents:days toDate:d options:0]];
    }

    [result addObject:d];

    for (NSUInteger i = 0;i<after;i++) {
        NSDateComponents *days = [[NSDateComponents alloc] init];
        days.day = i+1;
        [result addObject:[_calendar dateByAddingComponents:days toDate:d options:0]];
    }

    return result;
}

#pragma mark - Helpers

- (NSDate*)dateWithoutTimeFromDate:(NSDate*)date {
    if (!date) return nil;
    NSDateComponents* components = [_calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
    return [_calendar dateFromComponents:components];
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (NSArray*)weekdayTitlesWithLocaleIdentifier:(NSString*)localeIdentifier length:(NSUInteger)length uppercase:(BOOL)uppercase {
    // Get weekday titles from current calendar + locale:
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier ? localeIdentifier :[[NSLocale preferredLanguages] firstObject]];
    NSMutableArray *wds = [NSMutableArray array];
    for (NSString *s in df.shortWeekdaySymbols) {
        NSString *clipped = [s substringWithRange:NSMakeRange(0, MIN(length,s.length))];
        if (uppercase) {
            clipped = [clipped uppercaseStringWithLocale:df.locale];
        }
        [wds addObject:clipped];
    }

    // ..finally, normalize so monday is at index 0
    return [[wds subarrayWithRange:NSMakeRange(1, 6)]
                          arrayByAddingObjectsFromArray:[wds subarrayWithRange:NSMakeRange(0,1)]];
}
@end
