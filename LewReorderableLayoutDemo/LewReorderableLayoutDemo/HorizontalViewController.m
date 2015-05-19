//
//  HorizontalViewController.m
//  LewPhotoBrowser
//
//  Created by pljhonglu on 15/5/19.
//  Copyright (c) 2015年 pljhonglu. All rights reserved.
//

#import "HorizontalViewController.h"
#import "LewReorderableLayout.h"
#import "LewCollectionViewCell.h"

#define cellIdentifier @"LewCollectionViewCell"

@interface HorizontalViewController ()<LewReorderableLayoutDelegate, LewReorderableLayoutDataSource>
@property (nonatomic, strong)NSMutableArray *images;

@end

@implementation HorizontalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [_collectionView registerNib:[UINib nibWithNibName:cellIdentifier bundle:nil] forCellWithReuseIdentifier:cellIdentifier];
    LewReorderableLayout *layout = (LewReorderableLayout *)[_collectionView collectionViewLayout];
    layout.delegate = self;
    layout.dataSource = self;
    
    _images = @[].mutableCopy;
    for (int i = 0; i<100; i++) {
        NSString *imageName = [NSString stringWithFormat:@"Sample%d.jpg",i%30];
        UIImage *image = [UIImage imageNamed:imageName];
        [_images addObject:image];
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
    cell.imageView.image = _images[indexPath.item];
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _images.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

@end
