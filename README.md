# FSTextView

## 介绍
[FSTextView](https://github.com/lifution/FSTextView.git)封装

## 如何导入
```
pod 'FSTextView', :git => 'https://github.com/xuzeyu/FSTextView.git'
```

## 增加内容
```objc
/**
 placeholder垂直方向边距
 */
@property (nonatomic, assign) CGFloat placeholderVerticalMargin;

/**
 placeholder水平方向边距
 */
@property (nonatomic, assign) CGFloat placeholderHorizontalMargin;

/**
 UITextView的text和placeholder四边间距
 */
@property (nonatomic, assign) IBInspectable UIEdgeInsets fs_textContainerInset;
/**
  是否禁止换行
 */
@property (nonatomic, assign) BOOL disableNewline;

/**
  是否点击Return按钮自动取消编辑状态
 */
@property (nonatomic, assign) BOOL isResignFirstResponderAfterReturn;

/**
 设定文本开始编辑Block回调. (切记弱化引用, 以免造成内存泄露.)
 */
- (void)addTextDidBeginEditingHandler:(FSTextViewHandler)beginEditingHandler;

/**
 设定文本结束编辑Block回调. (切记弱化引用, 以免造成内存泄露.)
 */
- (void)addTextDidEndEditingHandler:(FSTextViewHandler)endEditingHandler;
```

## 最低版本要求
iOS 6.0 +, Xcode 7.0 +

## 版本
1.8.1 增加属性placeholderVerticalMargin，placeholderHorizontalMargin，fs_textContainerInset,disableNewline,isResignFirstResponderAfterReturn参数，增加addTextDidBeginEditingHandler和addTextDidEndEditingHandler方法监听
