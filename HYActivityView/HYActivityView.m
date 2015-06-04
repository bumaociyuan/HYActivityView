//
//  HYActivityView.m
//  Test
//
//  Created by crte on 13-11-6.
//  Copyright (c) 2013年 crte. All rights reserved.
//

#import "HYActivityView.h"

#define BUTTON_VIEW_SIDE      75.f
#define BUTTON_VIEW_FONT_SIZE 11.f

#pragma mark - ButtonView

@interface ButtonView ()

@property (nonatomic, copy) NSString *text;

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, copy) ButtonViewHandler handler;

@end

@implementation ButtonView

- (id)initWithText:(NSString *)text image:(UIImage *)image handler:(ButtonViewHandler)handler {
    self = [super init];

    if (self) {
        self.text = text;
        self.image = image;

        if (handler) {
            self.handler = handler;
        }

        [self setup];
    }

    return self;
}

- (void)setup {
    self.textLabel = [[UILabel alloc]init];
    self.textLabel.text = self.text;
    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.font = [UIFont systemFontOfSize:BUTTON_VIEW_FONT_SIZE];
    self.textLabel.textColor = [UIColor colorWithWhite:0.314 alpha:1.000];
    self.textLabel.textAlignment = NSTextAlignmentCenter;

    self.imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.imageButton setImage:self.image forState:UIControlStateNormal];
    [self.imageButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.textLabel];
    [self addSubview:self.imageButton];

    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageButton.translatesAutoresizingMaskIntoConstraints = NO;

    NSLayoutConstraint *constraint = nil;
    NSDictionary *views = @{ @"textLabel": self.textLabel, @"imageButton": self.imageButton };
    NSArray *constraints = nil;


    
    constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:85];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:75];
    [self addConstraint:constraint];

    //label紧贴view的左右
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textLabel]|" options:0 metrics:nil views:views];
    [self addConstraints:constraints];

    //imageView距离view左右各10, imageView的宽为55
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[imageButton(55)]-10-|" options:0 metrics:nil views:views];
    [self addConstraints:constraints];

    //竖直方向imageView和textLabel在一条直线上, 距离10, imageView的高为55
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageButton(55)]-10-[textLabel]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views];
    [self addConstraints:constraints];
}

- (void)buttonClicked:(UIButton *)button {
    if (self.handler) {
        self.handler(self);
    }

    if (self.activityView) {
        [self.activityView hide];
    }
}

@end

#define ICON_VIEW_HEIGHT_SPACE 8

#pragma mark - HYActivityView

@interface HYActivityView ()

@property (nonatomic, copy) NSString *title;

//将要显示在该视图上
@property (nonatomic, weak) UIView *referView;

//内容窗口
@property (nonatomic, strong) UIView *contentView;

//透明的关闭按钮
@property (nonatomic, strong) UIButton *closeButton;

//按钮加载的view
@property (nonatomic, strong) UIView *iconView;

//button数组
@property (nonatomic, strong) NSMutableArray *buttonArray;

//行数
@property (nonatomic, assign) NSInteger lines;

//目前正在生效的numberOfButtonPerLine
@property (nonatomic, assign) NSInteger workingNumberOfButtonPerLine;

//按钮间的间隔大小
@property (nonatomic, assign) CGFloat buttonSpace;

//消失的时候移除
@property (nonatomic, strong) NSLayoutConstraint *contentViewAndViewConstraint;

//iconView高度的constraint
@property (nonatomic, strong) NSLayoutConstraint *iconViewHeightConstraint;

//buttonView的constraints
@property (nonatomic, strong) NSMutableArray *buttonConstraintsArray;

@end

@implementation HYActivityView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (id)initWithTitle:(NSString *)title referView:(UIView *)referView {
    self = [super init];

    if (self) {
        self.title = title;

        if (referView) {
            self.referView = referView;
        }

        [self setup];

        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(deviceRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }

    return self;
}

- (void)calculateButtonSpaceWithNumberOfButtonPerLine:(NSInteger)number {
    self.buttonSpace = (self.referView.bounds.size.width - BUTTON_VIEW_SIDE * number) / (number + 1);

    if (self.buttonSpace < 0) {
        [self calculateButtonSpaceWithNumberOfButtonPerLine:4];
    } else {
        self.workingNumberOfButtonPerLine = number;
    }
}

- (void)setup {
    self.buttonArray = [NSMutableArray array];
    self.buttonConstraintsArray = [NSMutableArray array];
    self.lines = 0;
    self.numberOfButtonPerLine = 4;

    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3f];

    self.contentView = [[UIView alloc]init];
    self.bgColor = [UIColor whiteColor];
    [self addSubview:self.contentView];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeButton addTarget:self action:@selector(closeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeButton];

    self.titleLabel = [[UILabel alloc]init];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textColor = [UIColor colorWithWhite:0.314 alpha:1.000];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:BUTTON_VIEW_FONT_SIZE];
    self.titleLabel.text = self.title;
    [self.contentView addSubview:self.titleLabel];

    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton setTitle:@"取 消" forState:UIControlStateNormal];
    [self.cancelButton setBackgroundColor:[UIColor colorWithWhite:0.965 alpha:1.000]];
    [self.cancelButton setTitleColor:[UIColor colorWithWhite:0.314 alpha:1.000] forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.cancelButton addTarget:self action:@selector(closeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.cancelButton];

    self.iconView = [[UIView alloc]init];
    [self.contentView addSubview:self.iconView];

    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;

    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints {
    [super updateConstraints];

    NSArray *constraints = nil;
    NSLayoutConstraint *constraint = nil;
    NSDictionary *views = @{ @"contentView": self.contentView, @"closeButton": self.closeButton, @"titleLabel": self.titleLabel, @"cancelButton": self.cancelButton, @"iconView": self.iconView, @"view": self, @"referView": self.referView };

    //view跟referView的宽高相等
    constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.referView attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    [self.referView addConstraint:constraint];

    constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.referView attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    [self.referView addConstraint:constraint];

    constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.referView attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
    [self.referView addConstraint:constraint];

    constraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.referView attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [self.referView addConstraint:constraint];

    //closeButton跟view的左右挨着
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[closeButton]|" options:0 metrics:nil views:views];
    [self addConstraints:constraints];

    //contentView跟view的左右挨着
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:nil views:views];
    [self addConstraints:constraints];

    //垂直方向closeButton挨着contentView
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[closeButton(==view@999)][contentView]" options:0 metrics:nil views:views];
    [self addConstraints:constraints];

    //titleLabel跟contentView左右挨着
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[titleLabel]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:constraints];

    //cancelButton跟contentView左右挨着
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cancelButton]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:constraints];

    //iconView跟contentView左右挨着
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[iconView]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:constraints];

    //iconView的高度
    if (self.iconViewHeightConstraint) {
        [self.iconView removeConstraint:self.iconViewHeightConstraint];
    }

    self.iconViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.iconView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.lines * BUTTON_VIEW_SIDE + (self.lines + 1) * ICON_VIEW_HEIGHT_SPACE];
    [self.iconView addConstraint:self.iconViewHeightConstraint];

    //垂直方向titleLabel挨着iconView挨着cancelButton
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[titleLabel(==30)]-[iconView]-[cancelButton(==44)]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:constraints];
}

- (void)prepareForShow {
    //计算行数
    NSInteger count = [self.buttonArray count];

    self.lines = count / self.workingNumberOfButtonPerLine;

    if (count % self.workingNumberOfButtonPerLine != 0) {
        self.lines++;
    }

    for (int i = 0; i < [self.buttonArray count]; i++) {
        ButtonView *buttonView = [self.buttonArray objectAtIndex:i];
        [self.iconView addSubview:buttonView];

        int y = i / self.workingNumberOfButtonPerLine;
        int x = i % self.workingNumberOfButtonPerLine;

        //排列buttonView的位置
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:buttonView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.iconView attribute:NSLayoutAttributeTop multiplier:1 constant:(y + 1) * ICON_VIEW_HEIGHT_SPACE + y * BUTTON_VIEW_SIDE];
        [self.iconView addConstraint:constraint];
        [self.buttonConstraintsArray addObject:constraint];

        constraint = [NSLayoutConstraint constraintWithItem:buttonView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.iconView attribute:NSLayoutAttributeLeading multiplier:1 constant:(x + 1) * self.buttonSpace + x * BUTTON_VIEW_SIDE];
        [self.iconView addConstraint:constraint];
        [self.buttonConstraintsArray addObject:constraint];
    }

    [self layoutIfNeeded];
}

- (void)show {
    if (self.isShowing) {
        return;
    }

    [self.referView addSubview:self];
    [self setNeedsUpdateConstraints];
    self.alpha = 0;

    [self prepareForShow];

    self.contentViewAndViewConstraint = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    [self addConstraint:self.contentViewAndViewConstraint];

    [UIView animateWithDuration:0.25f animations:^{
        self.alpha = 1;
        [self layoutIfNeeded];
        self.show = YES;
    }];
}

- (void)hide {
    if (!self.isShowing) {
        return;
    }

    [UIView animateWithDuration:0.25f animations:^{
        self.alpha = 0;
        [self removeConstraint:self.contentViewAndViewConstraint];
        self.contentViewAndViewConstraint = nil;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.show = NO;
        [self removeFromSuperview];
    }];
}

- (void)deviceRotate:(NSNotification *)notification {
    [self.iconView removeConstraints:self.buttonConstraintsArray];
    [self.buttonConstraintsArray removeAllObjects];

    [self calculateButtonSpaceWithNumberOfButtonPerLine:self.numberOfButtonPerLine];
    [self prepareForShow];

    [self.iconView removeConstraint:self.iconViewHeightConstraint];
    self.iconViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.iconView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.lines * BUTTON_VIEW_SIDE + (self.lines + 1) * ICON_VIEW_HEIGHT_SPACE];
    [self.iconView addConstraint:self.iconViewHeightConstraint];
}

- (void)setNumberOfButtonPerLine:(NSInteger)numberOfButtonPerLine {
    _numberOfButtonPerLine = numberOfButtonPerLine;
    [self calculateButtonSpaceWithNumberOfButtonPerLine:numberOfButtonPerLine];
}

- (void)setBgColor:(UIColor *)bgColor {
    _bgColor = bgColor;
    self.contentView.backgroundColor = bgColor;
}

- (void)addButtonView:(ButtonView *)buttonView {
    [self.buttonArray addObject:buttonView];
    buttonView.activityView = self;
}

- (void)closeButtonClicked:(UIButton *)button {
    [self hide];
}



@end
