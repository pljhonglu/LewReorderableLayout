//
//  LewReorderableLayout.m
//  LewPhotoBrowser
//
//  Created by pljhonglu on 15/5/18.
//  Copyright (c) 2015年 pljhonglu. All rights reserved.
//

#import "LewReorderableLayout.h"
#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSUInteger, LewScrollDirction) {
    LewScrollDirctionStay,
    LewScrollDirctionToTop,
    LewScrollDirctionToEnd,
};

@interface LewCellFakeView :UIView
@property (nonatomic, weak)UICollectionViewCell *cell;
@property (nonatomic, strong)UIImageView *cellFakeImageView;
@property (nonatomic, strong)UIImageView *cellFakeHightedView;
@property (nonatomic, strong)NSIndexPath *indexPath;
@property (nonatomic, assign)CGPoint originalCenter;
@property (nonatomic, assign)CGRect cellFrame;

- (instancetype)initWithCell:(UICollectionViewCell *)cell;
- (void)changeBoundsIfNeeded:(CGRect)bounds;
- (void)pushFowardView;
- (void)pushBackView:(void(^)(void))completion;
@end


@interface LewReorderableLayout ()
@property (nonatomic) LewScrollDirction continuousScrollDirection;
@property (nonatomic, assign)CGFloat scrollValue;
@property (nonatomic, strong)CADisplayLink *displayLink;

@property (nonatomic, strong)LewCellFakeView *cellFakeView;
@property (nonatomic, assign)CGPoint panTranslation;
@property (nonatomic, assign)CGPoint fakeCellCenter;
@property (nonatomic, assign)UIEdgeInsets trigerInsets;
@property (nonatomic, assign)UIEdgeInsets trigerPadding;
@property (nonatomic, assign)CGFloat scrollSpeedValue;

@property (nonatomic, readonly)CGFloat offsetFromTop;
@property (nonatomic, readonly)CGFloat insetsTop;
@property (nonatomic, readonly)CGFloat insetsEnd;
@property (nonatomic, readonly)CGFloat contentLength;
@property (nonatomic, readonly)CGFloat collectionViewLength;
@property (nonatomic, readonly)CGFloat fakeCellTopEdge;
@property (nonatomic, readonly)CGFloat fakeCellEndEdge;
@property (nonatomic, readonly)CGFloat trigerInsetTop;
@property (nonatomic, readonly)CGFloat trigerInsetEnd;
@property (nonatomic, readonly)CGFloat trigerPaddingTop;
@property (nonatomic, readonly)CGFloat trigerPaddingEnd;

@end

@implementation LewReorderableLayout

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _continuousScrollDirection = LewScrollDirctionStay;
        _trigerInsets = UIEdgeInsetsMake(100, 100, 100, 100);
        _scrollSpeedValue = 10.0f;
        [self configureObserver];
    }
    return self;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _continuousScrollDirection = LewScrollDirctionStay;
        _trigerInsets = UIEdgeInsetsMake(100, 100, 100, 100);
        _scrollSpeedValue = 10.0f;
        [self configureObserver];
    }
    return self;
}

- (void)dealloc{
    [self removeObserver:self forKeyPath:@"collectionView"];
}

#pragma mark - setup

- (void)configureObserver{
    [self addObserver:self forKeyPath:@"collectionView" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)setUpGestureRecognizers{
    if (self.collectionView == nil) {
        return;
    }
    _longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongPress:)];
    _panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePanGesture:)];
    _longPress.delegate = self;
    _panGesture.delegate = self;
    _panGesture.maximumNumberOfTouches = 1;
    NSArray *gestures = [self.collectionView gestureRecognizers];
    [gestures enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [(UILongPressGestureRecognizer *)obj requireGestureRecognizerToFail:_longPress];
        }
    }];
    [self.collectionView addGestureRecognizer:_longPress];
    [self.collectionView addGestureRecognizer:_panGesture];
}

- (void)setUpDisplayLink{
    if (_displayLink) {
        return;
    }
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(continuousScroll)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)invalidateDisplayLink{
    _continuousScrollDirection = LewScrollDirctionStay;
    [_displayLink invalidate];
    _displayLink = nil;
}

- (void)beginScrollIfNeeded{
    if (_cellFakeView == nil) {
        return;
    }
    CGFloat offset = self.offsetFromTop;
    CGFloat trigerInsetTop = self.trigerInsetTop;
    CGFloat trigerInsetEnd = self.trigerInsetEnd;
    CGFloat paddingTop = self.trigerPaddingTop;
    CGFloat paddingEnd = self.trigerPaddingEnd;
    CGFloat length = self.collectionViewLength;
    CGFloat fakeCellTopEdge = self.fakeCellTopEdge;
    CGFloat fakeCellEndEdge = self.fakeCellEndEdge;
    
    if(fakeCellTopEdge <= offset + paddingTop + trigerInsetTop){

        self.continuousScrollDirection = LewScrollDirctionToTop;
        [self setUpDisplayLink];
    }else if(fakeCellEndEdge >= offset + length - paddingEnd - trigerInsetEnd) {

        self.continuousScrollDirection = LewScrollDirctionToEnd;
        [self setUpDisplayLink];
    }else {
        [self invalidateDisplayLink];
    }
}

// move item
- (void)moveItemIfNeeded {
    NSIndexPath *atIndexPath;
    NSIndexPath *toIndexPath;
    if (_cellFakeView) {
        atIndexPath = _cellFakeView.indexPath;
        toIndexPath = [self.collectionView indexPathForItemAtPoint:_cellFakeView.center];
    }
    
    if (atIndexPath == nil || toIndexPath == nil) {
        return;
    }
    
    if ([atIndexPath isEqual:toIndexPath]) {
        return;
    }
    
    // can move item
    // 方便根据路径判断是否可移动，fixed #2
    if ([_delegate respondsToSelector:@selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)]) {
        if (![_delegate collectionView:self.collectionView itemAtIndexPath:atIndexPath canMoveToIndexPath:toIndexPath]) {
            return;
        }
    }
    
    // will move item
    if ([_delegate respondsToSelector:@selector(collectionView:itemAtIndexPath:willMoveToIndexPath:)]) {
        [_delegate collectionView:self.collectionView itemAtIndexPath:atIndexPath willMoveToIndexPath:toIndexPath];
    }
    
    UICollectionViewLayoutAttributes *attribute = [self layoutAttributesForItemAtIndexPath:toIndexPath];
    [self.collectionView performBatchUpdates:^{
        _cellFakeView.indexPath = toIndexPath;
        _cellFakeView.cellFrame = attribute.frame;
        [_cellFakeView changeBoundsIfNeeded:attribute.bounds];
        [self.collectionView moveItemAtIndexPath:atIndexPath toIndexPath:toIndexPath];
        
        if ([_delegate respondsToSelector:@selector(collectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
            [_delegate collectionView:self.collectionView itemAtIndexPath:atIndexPath didMoveToIndexPath:toIndexPath];
        }
    } completion:nil];
}

- (void)continuousScroll{
    if (_cellFakeView == nil) {
        return;
    }
    
    CGFloat percentage = [self calcTrigerPercentage];
    CGFloat scrollRate = [self scrollValueWithSpeed:_scrollSpeedValue andPercentage:percentage];
    
    CGFloat offset = self.offsetFromTop;
    CGFloat insetTop = self.insetsTop;
    CGFloat insetEnd = self.insetsEnd;
    CGFloat length = self.collectionViewLength;
    CGFloat contentLength = self.contentLength;
    
    if (contentLength + insetTop + insetEnd <= length) {
        return;
    }
    
    if (offset + scrollRate <= -insetTop) {
        scrollRate = -insetTop - offset;
    }else if (offset + scrollRate >= contentLength + insetEnd - length) {
        scrollRate = contentLength + insetEnd - length - offset;
    }
    
    [self.collectionView performBatchUpdates:^{
        if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
            _fakeCellCenter.y += scrollRate;
            CGPoint center = _cellFakeView.center;
            center.y = self.fakeCellCenter.y + self.panTranslation.y;
            _cellFakeView.center = center;
            CGPoint contentOffset = self.collectionView.contentOffset;
            contentOffset.y += scrollRate;
            self.collectionView.contentOffset = contentOffset;
        }else{
            _fakeCellCenter.x += scrollRate;
            CGPoint center = _cellFakeView.center;
            center.x = self.fakeCellCenter.x + self.panTranslation.x;
            _cellFakeView.center = center;
            CGPoint contentOffset = self.collectionView.contentOffset;
            contentOffset.x += scrollRate;
            self.collectionView.contentOffset = contentOffset;
        }
    } completion:nil];

    [self moveItemIfNeeded];
}

- (CGFloat)calcTrigerPercentage{
    if (_cellFakeView == nil) {
        return 0;
    }
    CGFloat offset = self.offsetFromTop;
    CGFloat offsetEnd = self.offsetFromTop + self.collectionViewLength;
    CGFloat insetTop = self.insetsTop;
    CGFloat trigerInsetTop = self.trigerInsetTop;
    CGFloat trigerInsetEnd = self.trigerInsetEnd;
    CGFloat paddingTop = self.trigerPaddingTop;
    CGFloat paddingEnd = self.trigerPaddingEnd;
    
    CGFloat percentage = 0.0;
    
    if (self.continuousScrollDirection == LewScrollDirctionToTop) {
        if (self.fakeCellTopEdge) {
            percentage = 1.0 - ((self.fakeCellTopEdge - (offset + paddingTop)) / trigerInsetTop);
        }
    }else if (self.continuousScrollDirection == LewScrollDirctionToEnd){
        if (self.fakeCellEndEdge) {
            percentage = 1.0 - (((insetTop + offsetEnd - paddingEnd) - (self.fakeCellEndEdge + insetTop)) / trigerInsetEnd);
        }
    }
    percentage = fmin(1.0f, percentage);
    percentage = fmax(0.0f, percentage);
    return percentage;
}

- (void)cancelDrag{
    [self cancelDrag:nil];
}

- (void)cancelDrag:(NSIndexPath *)toIndexPath {
    if (_cellFakeView == nil) {
        return;
    }
    
    // will end drag item
    if ([_delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
        [_delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:toIndexPath];
    }
    
    self.collectionView.scrollsToTop = YES;
    
    _fakeCellCenter = CGPointZero;
    
    [self invalidateDisplayLink];
    
    [_cellFakeView pushBackView:^{
        [_cellFakeView removeFromSuperview];
        _cellFakeView = nil;
        [self invalidateLayout];
        
        if ([_delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
            [_delegate collectionView:self.collectionView layout:self didEndDraggingItemAtIndexPath:toIndexPath];
        }
    }];
}

#pragma mark - gesture
// long press gesture
- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress {
    CGPoint location = [longPress locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    
    if (_cellFakeView != nil) {
        indexPath = self.cellFakeView.indexPath;
    }
    
    if (indexPath == nil) {
        return;
    }
    
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:{
        // will begin drag item
            if ([_delegate respondsToSelector:@selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [_delegate collectionView:self.collectionView layout:self willBeginDraggingItemAtIndexPath:indexPath];
            }
            
            self.collectionView.scrollsToTop = NO;
        
            UICollectionViewCell *currentCell = [self.collectionView cellForItemAtIndexPath:indexPath];
        
            _cellFakeView = [[LewCellFakeView alloc]initWithCell:currentCell];
            _cellFakeView.indexPath = indexPath;
            _cellFakeView.originalCenter = currentCell.center;
            _cellFakeView.cellFrame = [self layoutAttributesForItemAtIndexPath:indexPath].frame;
            [self.collectionView addSubview:self.cellFakeView];
        
            _fakeCellCenter = self.cellFakeView.center;
        
            [self invalidateLayout];
        
            [_cellFakeView pushFowardView];
        
            // did begin drag item
            if ([_delegate respondsToSelector:@selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                [_delegate collectionView:self.collectionView layout:self didBeginDraggingItemAtIndexPath:indexPath];
            }
        }
            break;
    case UIGestureRecognizerStateCancelled:
        
    case UIGestureRecognizerStateEnded:
            [self cancelDrag: indexPath];
    default:
            break;
    }
}

// pan gesture
- (void)handlePanGesture:(UIPanGestureRecognizer *)pan {
    _panTranslation = [pan translationInView:self.collectionView];
    if (_cellFakeView != nil) {
        switch (pan.state) {
            case UIGestureRecognizerStateChanged:{
                CGPoint center = _cellFakeView.center;
                center.x = self.fakeCellCenter.x + self.panTranslation.x;
                center.y = self.fakeCellCenter.y + self.panTranslation.y;
                _cellFakeView.center = center;
                
                [self beginScrollIfNeeded];
                [self moveItemIfNeeded];
            }
                break;
        case UIGestureRecognizerStateCancelled:
            
        case UIGestureRecognizerStateEnded:
                [self invalidateDisplayLink];
        default:
                break;
        }
    }
}

// gesture recognize delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{

    // allow move item
    CGPoint location = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    if (indexPath) {
        if ([_delegate respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)]) {
            BOOL canMove = [_delegate collectionView:self.collectionView canMoveItemAtIndexPath:indexPath];
            if (!canMove) {
                return NO;
            }
        }
    }else{
        // fix #3
        return NO;
    }

    if([gestureRecognizer isEqual:_longPress]){
        return (self.collectionView.panGestureRecognizer.state == UIGestureRecognizerStatePossible || self.collectionView.panGestureRecognizer.state == UIGestureRecognizerStateFailed);
        
    }else if([gestureRecognizer isEqual:_panGesture]){
        return (_longPress.state != UIGestureRecognizerStatePossible && _longPress.state != UIGestureRecognizerStateFailed);
        
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    
    if ([_panGesture isEqual:gestureRecognizer]) {
        return [_longPress isEqual:otherGestureRecognizer];
        
    }else if ([self.collectionView.panGestureRecognizer isEqual:gestureRecognizer]) {
        return (_longPress.state != UIGestureRecognizerStatePossible && _longPress.state != UIGestureRecognizerStateFailed);
        
    }
    return YES;
}

#pragma mark - override

- (void)prepareLayout{
    [super prepareLayout];
    
    if (_dataSource && [_dataSource respondsToSelector:@selector(scrollTrigerEdgeInsetsInCollectionView:)]) {
        self.trigerInsets = [_dataSource scrollTrigerEdgeInsetsInCollectionView:self.collectionView];
    }
    
    if (_dataSource && [_dataSource respondsToSelector:@selector(scrollTrigerPaddingInCollectionView:)]) {
        self.trigerPadding = [_dataSource scrollTrigerPaddingInCollectionView:self.collectionView];
    }
    
    if (_dataSource && [_dataSource respondsToSelector:@selector(scrollSpeedValueInCollectionView:)]) {
        _scrollSpeedValue = [_dataSource scrollSpeedValueInCollectionView:self.collectionView];
    }
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    NSArray *attributesArray = [super layoutAttributesForElementsInRect:rect];
    if (attributesArray == nil) {
        return attributesArray;
    }
    [attributesArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UICollectionViewLayoutAttributes *layoutAttribute = obj;
        if ([layoutAttribute.indexPath isEqual:_cellFakeView.indexPath]) {
            CGFloat cellAlpha = 0;
            if (_dataSource && [_dataSource respondsToSelector:@selector(reorderingItemAlpha:inSection:)]) {
                cellAlpha = [_dataSource reorderingItemAlpha:self.collectionView inSection:layoutAttribute.indexPath.section];
            }
            layoutAttribute.alpha = cellAlpha;
        }
    }];
    return attributesArray;
}

#pragma mark - observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"collectionView"]) {
        [self setUpGestureRecognizers];
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - getter
- (CGFloat)scrollValueWithSpeed:(CGFloat)speed andPercentage:(CGFloat)percentage{
    CGFloat value = 0.0f;
    switch (_continuousScrollDirection) {
        case LewScrollDirctionStay: {
            return 0.0f;
            break;
        }
        case LewScrollDirctionToTop: {
            value = -speed;
            break;
        }
        case LewScrollDirctionToEnd: {
            value = speed;
            break;
        }
        default: {
            return 0.0f;
        }
    }
    
    CGFloat proofedPercentage = fmax(fmin(1.0f, percentage), 0.0f);
    return value * proofedPercentage;
}

- (CGFloat)offsetFromTop{
    CGPoint contentOffset = self.collectionView.contentOffset;
    return self.scrollDirection == UICollectionViewScrollDirectionVertical? contentOffset.y : contentOffset.x;
}

- (CGFloat)insetsTop{
    UIEdgeInsets contentInsets = self.collectionView.contentInset;
    return self.scrollDirection == UICollectionViewScrollDirectionVertical? contentInsets.top : contentInsets.left;
}

- (CGFloat)insetsEnd{
    UIEdgeInsets contentInsets = self.collectionView.contentInset;
    return self.scrollDirection == UICollectionViewScrollDirectionVertical? contentInsets.bottom : contentInsets.right;
}

- (CGFloat)contentLength{
    CGSize contentSize = self.collectionView.contentSize;
    return self.scrollDirection == UICollectionViewScrollDirectionVertical? contentSize.height : contentSize.width;
}

- (CGFloat)collectionViewLength{
    CGSize collectionViewSize = self.collectionView.bounds.size;
    return self.scrollDirection == UICollectionViewScrollDirectionVertical? collectionViewSize.height : collectionViewSize.width;
}

- (CGFloat)fakeCellTopEdge{
    if (_cellFakeView) {
        return self.scrollDirection == UICollectionViewScrollDirectionVertical? CGRectGetMinY(_cellFakeView.frame) : CGRectGetMinX(_cellFakeView.frame);
    }
    return 0.0f;
}

- (CGFloat)fakeCellEndEdge{
    if (_cellFakeView) {
        return self.scrollDirection == UICollectionViewScrollDirectionVertical? CGRectGetMaxY(_cellFakeView.frame) : CGRectGetMaxX(_cellFakeView.frame);
    }
    return 0.0f;
}

- (CGFloat)trigerInsetTop{
    return self.scrollDirection == UICollectionViewScrollDirectionVertical? _trigerInsets.top : _trigerInsets.left;
}

- (CGFloat)trigerInsetEnd{
    return self.scrollDirection == UICollectionViewScrollDirectionVertical? _trigerInsets.bottom : _trigerInsets.right;
}

- (CGFloat)trigerPaddingTop{
    return self.scrollDirection == UICollectionViewScrollDirectionVertical? _trigerPadding.top : _trigerPadding.left;
}

- (CGFloat)trigerPaddingEnd{
    return self.scrollDirection == UICollectionViewScrollDirectionVertical? _trigerPadding.top : _trigerPadding.left;
}

#pragma mark - setter

- (void)setDelegate:(id<LewReorderableLayoutDelegate>)delegate{
    _delegate = delegate;
    self.collectionView.delegate = delegate;
}

- (void)setDataSource:(id<LewReorderableLayoutDataSource>)dataSource{
    _dataSource = dataSource;
    self.collectionView.dataSource = dataSource;
}
@end

#pragma mark - LewCellFakeView implementation

@implementation LewCellFakeView

- (instancetype)initWithCell:(UICollectionViewCell *)cell{
    self = [super initWithFrame:cell.frame];
    if (self) {
        self.cell = cell;
        
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowOpacity = 0;
        self.layer.shadowRadius = 5.0;
        self.layer.shouldRasterize = false;
        
        self.cellFakeImageView = [[UIImageView alloc]initWithFrame:self.bounds];
        self.cellFakeImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.cellFakeImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.cellFakeHightedView = [[UIImageView alloc]initWithFrame:self.bounds];
        self.cellFakeHightedView.contentMode = UIViewContentModeScaleAspectFill;
        self.cellFakeHightedView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        cell.highlighted = YES;
        self.cellFakeHightedView.image = [self getCellImage];
        cell.highlighted = NO;
        self.cellFakeImageView.image = [self getCellImage];
        
        [self addSubview:self.cellFakeImageView];
        [self addSubview:self.cellFakeHightedView];
        
    }
    
    return self;
}

- (void)changeBoundsIfNeeded:(CGRect)bounds{
    if (CGRectEqualToRect(self.bounds, bounds)) {
        return;
    }
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.bounds = bounds;
    } completion:nil];
}

- (void)pushFowardView{
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.center = self.originalCenter;
        self.transform = CGAffineTransformMakeScale(1.1, 1.1);
        self.cellFakeHightedView.alpha = 0;
        
        CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        shadowAnimation.fromValue = @(0);
        shadowAnimation.toValue = @(0.7);
        shadowAnimation.removedOnCompletion = NO;
        shadowAnimation.fillMode = kCAFillModeForwards;
        [self.layer addAnimation:shadowAnimation forKey:@"applyShadow"];
    } completion:^(BOOL finished) {
        [self.cellFakeHightedView removeFromSuperview];
    }];
}

- (void)pushBackView:(void(^)(void))completion{
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.transform = CGAffineTransformIdentity;
        self.frame = self.cellFrame;
        CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        shadowAnimation.fromValue = @(0.7);
        shadowAnimation.toValue = @(0);
        shadowAnimation.removedOnCompletion = NO;
        shadowAnimation.fillMode = kCAFillModeForwards;
        [self.layer addAnimation:shadowAnimation forKey:@"removeShadow"];
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

- (UIImage *)getCellImage{
    UIGraphicsBeginImageContextWithOptions(_cell.bounds.size, NO, [UIScreen mainScreen].scale * 2);

    // fix issue #1
    // [_cell drawViewHierarchyInRect:_cell.bounds afterScreenUpdates:YES];
    [_cell.layer renderInContext:UIGraphicsGetCurrentContext()];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end
