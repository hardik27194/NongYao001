//
//  MineCollectionViewCellTwo.h
//  ShangCheng
//
//  Created by TongLi on 2016/11/2.
//  Copyright © 2016年 TongLi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MineCollectionViewCellTwo : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *headerImageView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

- (void)updateCellWithHeaderImage:(NSString *)headerImageUrl withInfoStr:(NSString *)infoStr;
@end
