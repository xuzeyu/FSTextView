
#import "FSTextView.h"

CGFloat const kFSTextViewPlaceholderVerticalMargin = 8.0; ///< placeholder垂直方向边距
CGFloat const kFSTextViewPlaceholderHorizontalMargin = 6.0; ///< placeholder水平方向边距

@interface FSTextView ()

@property (nonatomic, copy) FSTextViewHandler beginEditingHandler; ///< 文本开始编辑Block
@property (nonatomic, copy) FSTextViewHandler changeHandler; ///< 文本改变Block
@property (nonatomic, copy) FSTextViewHandler endEditingHandler; ///< 文本结束编辑Block
@property (nonatomic, copy) FSTextViewHandler maxHandler; ///< 达到最大限制字符数Block
@property (nonatomic, strong) UILabel *placeholderLabel; ///< placeholderLabel

@property (nonatomic, strong) NSMutableArray *placeholderLabelConstraints; ///<placeholderLabel的约束
@end

@implementation FSTextView

#pragma mark - Override

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _changeHandler = NULL;
    _maxHandler = NULL;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (!(self = [super initWithCoder:aDecoder])) return nil;
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"10.0" options:NSNumericSearch] != NSOrderedAscending) {
        
        [self layoutIfNeeded];
    }
    
    [self initialize];
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame])) return nil;
    
    [self initialize];
    
    return self;
}

- (BOOL)becomeFirstResponder
{
    // 成为第一响应者时注册通知监听文本变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:UITextViewTextDidEndEditingNotification object:nil];
    
    BOOL become = [super becomeFirstResponder];
    
    return become;
}

- (BOOL)resignFirstResponder
{
    BOOL resign = [super resignFirstResponder];
    
    // 注销第一响应者时移除文本变化的通知, 以免影响其它的`UITextView`对象.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidEndEditingNotification object:nil];
    
    return resign;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL result = [super canPerformAction:action withSender:sender];
    
    if (result) {
        if (![self respondsToSelector:action]) {
            result = NO;
        } else {
            result = _canPerformAction;
        }
    }
    
    return result;
}

#pragma mark - Private

- (void)initialize
{
    _placeholderVerticalMargin = kFSTextViewPlaceholderVerticalMargin;
    _placeholderHorizontalMargin = kFSTextViewPlaceholderHorizontalMargin;
    
    // 基本配置 (需判断是否在Storyboard中设置了值)
    _canPerformAction = YES;
    
    if (_maxLength == 0 || _maxLength == NSNotFound) {
        
        _maxLength = NSUIntegerMax;
    }
    
    if (!_placeholderColor) {
        
        _placeholderColor = [UIColor colorWithRed:0.780 green:0.780 blue:0.804 alpha:1.000];
    }
    
    // 基本设定 (需判断是否在Storyboard中设置了值)
    if (!self.backgroundColor) {
        
        self.backgroundColor = [UIColor whiteColor];
    }
    
    if (!self.font) {
        
        self.font = [UIFont systemFontOfSize:15.f];
    }
    
    // placeholderLabel
    self.placeholderLabel.font = self.font;
    self.placeholderLabel.text = _placeholder; // 可能在Storyboard中设置了Placeholder
    self.placeholderLabel.textColor = _placeholderColor;
    [self addSubview:self.placeholderLabel];
    
    // constraint
    self.placeholderLabelConstraints = [NSMutableArray array];
    [self.placeholderLabelConstraints addObject:[NSLayoutConstraint constraintWithItem:self.placeholderLabel
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1.0
                                                      constant:self.placeholderVerticalMargin]];
    [self.placeholderLabelConstraints addObject:[NSLayoutConstraint constraintWithItem:self.placeholderLabel
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0
                                                      constant:self.placeholderHorizontalMargin]];
    [self.placeholderLabelConstraints addObject:[NSLayoutConstraint constraintWithItem:self.placeholderLabel
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:1.0
                                                      constant:-self.placeholderHorizontalMargin*2]];
    [self.placeholderLabelConstraints addObject:[NSLayoutConstraint constraintWithItem:self.placeholderLabel
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeHeight
                                                    multiplier:1.0
                                                      constant:-self.placeholderVerticalMargin*2]];
    [self addConstraints:self.placeholderLabelConstraints];
}

- (void)setPlaceholderVerticalMargin:(CGFloat)placeholderVerticalMargin {
    _placeholderVerticalMargin = placeholderVerticalMargin;
    
    if (!self.placeholderLabel) {
        return;
    }
    
    for (NSLayoutConstraint *constraint in self.placeholderLabelConstraints) {
        if (constraint.firstItem == self.placeholderLabel && (constraint.firstAttribute == NSLayoutAttributeTop || constraint.firstAttribute == NSLayoutAttributeHeight)) {
            [self removeConstraint:constraint];
        }
    }
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.placeholderLabel
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1.0
                                                      constant:self.placeholderVerticalMargin]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.placeholderLabel
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeHeight
                                                    multiplier:1.0
                                                      constant:-self.placeholderVerticalMargin*2]];
}

- (void)setPlaceholderHorizontalMargin:(CGFloat)placeholderHorizontalMargin {
    _placeholderHorizontalMargin = placeholderHorizontalMargin;
    
    if (!self.placeholderLabel) {
        return;
    }
 
    for (NSLayoutConstraint *constraint in self.placeholderLabelConstraints) {
        if (constraint.firstItem == self.placeholderLabel && (constraint.firstAttribute == NSLayoutAttributeLeft || constraint.firstAttribute == NSLayoutAttributeWidth)) {
            [self removeConstraint:constraint];
        }
    }
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.placeholderLabel
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0
                                                      constant:self.placeholderHorizontalMargin]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.placeholderLabel
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:1.0
                                                      constant:-self.placeholderHorizontalMargin*2]];
}

- (void)setFs_textContainerInset:(UIEdgeInsets)fs_textContainerInset {
    _fs_textContainerInset = fs_textContainerInset;
    [self setTextContainerInset:UIEdgeInsetsMake(fs_textContainerInset.top, fs_textContainerInset.left - kFSTextViewPlaceholderHorizontalMargin, fs_textContainerInset.bottom, fs_textContainerInset.right)];
    self.layoutManager.allowsNonContiguousLayout = NO;
    
    [self removeConstraints:self.placeholderLabelConstraints];
    [self.placeholderLabelConstraints removeAllObjects];
    [self.placeholderLabelConstraints addObject:[NSLayoutConstraint constraintWithItem:self.placeholderLabel
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1.0
                                                      constant:fs_textContainerInset.top]];
    [self.placeholderLabelConstraints addObject:[NSLayoutConstraint constraintWithItem:self.placeholderLabel
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0
                                                      constant:fs_textContainerInset.left]];
    [self.placeholderLabelConstraints addObject:[NSLayoutConstraint constraintWithItem:self.placeholderLabel
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:1.0
                                                      constant:- fs_textContainerInset.left - fs_textContainerInset.right]];
    [self.placeholderLabelConstraints addObject:[NSLayoutConstraint constraintWithItem:self.placeholderLabel
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1.0
                                                      constant:- fs_textContainerInset.top - fs_textContainerInset.bottom]];
    [self addConstraints:self.placeholderLabelConstraints];
}

#pragma mark - Getter
/// 返回一个经过处理的 `self.text` 的值, 去除了首位的空格和换行.
- (NSString *)formatText
{
    return [[super text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; // 去除首尾的空格和换行.
}

- (UILabel *)placeholderLabel
{
    if (!_placeholderLabel) {
        
        _placeholderLabel = [[UILabel alloc] init];
        _placeholderLabel.numberOfLines = 0;
        _placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return _placeholderLabel;
}

#pragma mark - Setter

- (void)setText:(NSString *)text
{
    [super setText:text];
    
    self.placeholderLabel.hidden = [@(text.length) boolValue];
    // 手动模拟触发通知
    NSNotification *notification = [NSNotification notificationWithName:UITextViewTextDidChangeNotification object:self];
    [self textDidChange:notification];
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    
    self.placeholderLabel.font = font;
}

- (void)setMaxLength:(NSUInteger)maxLength
{
    _maxLength = fmax(0, maxLength);
    self.text = self.text;
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;
    self.layer.cornerRadius = _cornerRadius;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    if (!borderColor) return;
    
    _borderColor = borderColor;
    self.layer.borderColor = _borderColor.CGColor;
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    _borderWidth = borderWidth;
    self.layer.borderWidth = _borderWidth;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    if (!placeholder) return;
    
    _placeholder = [placeholder copy];
    
    if (_placeholder.length > 0) {
        
        self.placeholderLabel.text = _placeholder;
    }
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    if (!placeholderColor) return;
    
    _placeholderColor = placeholderColor;
    
    self.placeholderLabel.textColor = _placeholderColor;
}

- (void)setPlaceholderFont:(UIFont *)placeholderFont
{
    if (!placeholderFont) return;
    
    _placeholderFont = placeholderFont;
    
    self.placeholderLabel.font = _placeholderFont;
}

#pragma mark - NSNotification
- (void)textDidBeginEditing:(NSNotification *)notification {
    !_beginEditingHandler ?: _beginEditingHandler(self);
}

- (void)textDidChange:(NSNotification *)notification
{
    // 通知回调的实例的不是当前实例的话直接返回
    if (notification.object != self) return;
    
    // 根据字符数量显示或者隐藏 `placeholderLabel`
    self.placeholderLabel.hidden = [@(self.text.length) boolValue];
    
    // 禁止第一个字符输入空格或者换行
    if (self.text.length == 1) {
        
        if ([self.text isEqualToString:@" "] || [self.text isEqualToString:@"\n"]) {
            
            self.text = @"";
        }
    }
    
    if ([self.text containsString:@"\n"]) {
        if (self.disableNewline) {
            self.text = [self.text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        }
        
        if (self.isResignFirstResponderAfterReturn) {
            [self resignFirstResponder];
        }
    }
    
    // 只有当maxLength字段的值不为无穷大整型也不为0时才计算限制字符数.
    if (_maxLength != NSUIntegerMax && _maxLength != 0 && self.text.length > 0) {
        
        if (!self.markedTextRange && self.text.length > _maxLength) {
            
            !_maxHandler ?: _maxHandler(self); // 回调达到最大限制的Block.
            self.text = [self.text substringToIndex:_maxLength]; // 截取最大限制字符数.
            [self.undoManager removeAllActions]; // 达到最大字符数后清空所有 undoaction, 以免 undo 操作造成crash.
        }
    }
    
    // 回调文本改变的Block.
    !_changeHandler ?: _changeHandler(self);
}

- (void)textDidEndEditing:(NSNotification *)notification {
    !_endEditingHandler ?: _endEditingHandler(self);
}

#pragma mark - Public

+ (instancetype)textView
{
    return [[self alloc] init];
}

- (void)addTextDidBeginEditingHandler:(FSTextViewHandler)beginEditingHandler
{
    _beginEditingHandler = [beginEditingHandler copy];
}

- (void)addTextDidChangeHandler:(FSTextViewHandler)changeHandler
{
    _changeHandler = [changeHandler copy];
}

- (void)addTextDidEndEditingHandler:(FSTextViewHandler)endEditingHandler
{
    _endEditingHandler = [endEditingHandler copy];
}

- (void)addTextLengthDidMaxHandler:(FSTextViewHandler)maxHandler
{
    _maxHandler = [maxHandler copy];
}

@end
