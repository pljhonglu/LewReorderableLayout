//
//  VerticalViewController.m
//  LewPhotoBrowser
//
//  Created by pljhonglu on 15/5/19.
//  Copyright (c) 2015年 pljhonglu. All rights reserved.
//

#import "VerticalViewController.h"
#import "LewReorderableLayout.h"
#import "LewCollectionViewCell.h"

#define cellIdentifier @"LewCollectionViewCell"

@interface VerticalViewController ()<LewReorderableLayoutDelegate, LewReorderableLayoutDataSource>
@property (nonatomic, strong)NSMutableArray *imagesForSection_0;
@property (nonatomic, strong)NSMutableArray *imagesForSection_1;
@end

@implementation VerticalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [_collectionView registerNib:[UINib nibWithNibName:cellIdentifier bundle:nil] forCellWithReuseIdentifier:cellIdentifier];
    LewReorderableLayout *layout = (LewReorderableLayout *)[_collectionView collectionViewLayout];
    layout.delegate = self;
    layout.dataSource = self;
    
    _imagesForSection_0 = @[].mutableCopy;
    _imagesForSection_1 = @[].mutableCopy;
    
    for (int i = 0; i<18; i++) {
        NSString *imageName = [NSString stringWithFormat:@"Sample%d.jpg",i];
        UIImage *image = [UIImage imageNamed:imageName];
        [_imagesForSection_0 addObject:image];
    }
    
    for (int i = 18; i<30; i++) {
        NSString *imageName = [NSString stringWithFormat:@"Sample%d.jpg",i];
        UIImage *image = [UIImage imageNamed:imageName];
        [_imagesForSection_1 addObject:image];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - LewReorderableLayoutDataSource
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    LewCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if (indexPath.section == 0) {
        cell.imageView.image = _imagesForSection_0[indexPath.item];
    }else{
        cell.imageView.image = _imagesForSection_1[indexPath.item];
    }
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return _imagesForSection_0.count;
        case 1:
            return _imagesForSection_1.count;
        default:
            return 0;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 2;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat threePiecesWidth = floor(screenWidth / 3.0 - ((2.0 / 3) * 2));
    CGFloat twoPiecesWidth = floor(screenWidth / 2.0 - (2.0 / 2));
    if (indexPath.section == 0) {
        return CGSizeMake(threePiecesWidth, threePiecesWidth);
    }else {
        return CGSizeMake(twoPiecesWidth, twoPiecesWidth);
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 2.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 2.0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0, 0, 2.0, 0);
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    if ([collectionView numberOfItemsInSection:indexPath.section] <= 1) {
        return NO;
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath{
    UIImage *image = nil;
    if (fromIndexPath.section == 0) {
        image = _imagesForSection_0[fromIndexPath.item];
        [_imagesForSection_0 removeObjectAtIndex:fromIndexPath.item];
    }else{
        image = _imagesForSection_1[fromIndexPath.item];
        [_imagesForSection_1 removeObjectAtIndex:fromIndexPath.item];
    }
    
    if (toIndexPath.section == 0) {
        [_imagesForSection_0 insertObject:image atIndex:toIndexPath.item];
    }else{
        [_imagesForSection_1 insertObject:image atIndex:toIndexPath.item];
    }
}
@end
