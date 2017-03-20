//
//  LewReorderableLayout.h
//  LewPhotoBrowser
//
//  Created by pljhonglu on 15/5/18.
//  Copyright (c) 2015年 pljhonglu. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol LewReorderableLayoutDataSource <UICollectionViewDataSource>

@required

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;

@optional

// Default 0
- (CGFloat)reorderingItemAlpha:(UICollectionView * )collectionview inSection:(NSInteger)section;

// Default UIEdgeInsetsMake(100, 100, 100, 100)
- (UIEdgeInsets)scrollTrigerEdgeInsetsInCollectionView:(UICollectionView *)collectionView;

// Default UIEdgeInsetsZero
- (UIEdgeInsets)scrollTrigerPaddingInCollectionView:(UICollectionView *)collectionView;

// Default 10.0f
- (CGFloat)scrollSpeedValueInCollectionView:(UICollectionView *)collectionView;

@end

@protocol LewReorderableLayoutDelegate <UICollectionViewDelegateFlowLayout>

@optional

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath;

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath;

// Default YES
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;

// Default YES
- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath;

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

@end


@interface LewReorderableLayout : UICollectionViewFlowLayout<UIGestureRecognizerDelegate>

@property (nonatomic, weak)id<LewReorderableLayoutDelegate> delegate;
@property (nonatomic, weak)id<LewReorderableLayoutDataSource> dataSource;
@property (nonatomic, strong)UILongPressGestureRecognizer *longPress;
@property (nonatomic, strong)UIPanGestureRecognizer *panGesture;

@end
