//
//  ShoppingCarTableViewCell.m
//  ShangCheng
//
//  Created by TongLi on 2016/11/19.
//  Copyright © 2016年 TongLi. All rights reserved.
//

#import "ShoppingCarTableViewCell.h"

@implementation ShoppingCarTableViewCell

- (void)updateCellWithCellIndex:(NSIndexPath *)cellIndex {

    //得到模型
    ShoppingCarModel *tempShoppingCarModel = [[[Manager shareInstance] shoppingCarDataSourceArr] objectAtIndex:cellIndex.row];
    //是否被选择状态
    if (tempShoppingCarModel.isSelectedShoppingCar == YES) {
        self.selectButton.backgroundColor = [UIColor redColor];
    }else {
        self.selectButton.backgroundColor = [UIColor lightGrayColor];
    }
    
    self.titleLabel.text = tempShoppingCarModel.shoppingCarProduct.productTitle;
    
    self.companyLabel.text = tempShoppingCarModel.shoppingCarProduct.productCompany;
    self.formatLabel.text = tempShoppingCarModel.shoppingCarProduct.productFormatStr;
    self.priceLabel.text = [NSString stringWithFormat:@"￥ %@", tempShoppingCarModel.shoppingCarProduct.productPrice];
    
    self.countLabel.text = [NSString stringWithFormat:@"%@", tempShoppingCarModel.c_number];
    
}

//增加商品个数
- (IBAction)addCountAction:(UIButton *)sender {
    //得到这个cell的index
    NSIndexPath *cellIndex = [((UITableView *)self.superview.superview) indexPathForCell:self];
    //得到模型
    ShoppingCarModel *tempShoppingCarModel = [[[Manager shareInstance] shoppingCarDataSourceArr] objectAtIndex:cellIndex.row];
    
    //增加数量
    Manager *manager = [Manager shareInstance];
    [manager addOrLessShoppingCarProductCountWithShoppingModel:tempShoppingCarModel withIsAddOrLess:YES withAddOrLessSuccessResult:^(id successResult) {
        //刷新数量
        self.countLabel.text = tempShoppingCarModel.c_number;
        //返回控制器计算总价格
        self.totalPriceBlock();

    } withaddOrLessFailResult:^(NSString *failResultStr) {
        NSLog(@"%@",failResultStr);
    }];
    
    
}
//减少商品个数
- (IBAction)lessCountAction:(UIButton *)sender {
    //得到这个cell的index
    NSIndexPath *cellIndex = [((UITableView *)self.superview.superview) indexPathForCell:self];
    //得到模型
    ShoppingCarModel *tempShoppingCarModel = [[[Manager shareInstance] shoppingCarDataSourceArr] objectAtIndex:cellIndex.row];

    
    //减少数量
    Manager *manager = [Manager shareInstance];
    [manager addOrLessShoppingCarProductCountWithShoppingModel:tempShoppingCarModel withIsAddOrLess:NO withAddOrLessSuccessResult:^(id successResult) {
        //刷新数量
        self.countLabel.text = tempShoppingCarModel.c_number;
        //返回控制器计算总价格
        self.totalPriceBlock();

    } withaddOrLessFailResult:^(NSString *failResultStr) {
        NSLog(@"%@",failResultStr);
    }];
    
  
}

//删除按钮
- (IBAction)deleteButtonAction:(UIButton *)sender {
    //得到这个cell的index
    NSIndexPath *cellIndex = [((UITableView *)self.superview.superview) indexPathForCell:self];
    
    [[Manager shareInstance] deleteShoppingCarWithProductIndexSet:[NSMutableIndexSet indexSetWithIndex:cellIndex.row] WithSuccessResult:^(id successResult) {
        
        //删除成功，block返回到控制器刷新
        self.deleteSuccessBlock(cellIndex);
    } withFailResult:^(NSString *failResultStr) {
        //删除失败
        NSLog(@"删除失败");
    }];
    
}
//选择某个产品
- (IBAction)selectButtonAction:(UIButton *)sender {
    //得到这个cell的index
    NSIndexPath *cellIndex = [((UITableView *)self.superview.superview) indexPathForCell:self];
    //得到模型
    ShoppingCarModel *tempShoppingCarModel = [[[Manager shareInstance] shoppingCarDataSourceArr] objectAtIndex:cellIndex.row];
    //改变状态
    tempShoppingCarModel.isSelectedShoppingCar = !tempShoppingCarModel.isSelectedShoppingCar;
    if (tempShoppingCarModel.isSelectedShoppingCar == YES) {
        //如果选择了
        sender.backgroundColor = [UIColor redColor];
        
    }else {
        sender.backgroundColor = [UIColor lightGrayColor];
        
    }
    
    [[Manager shareInstance] isAllSelectForShoppingCarAction];
    
    //block,主要用户刷新全选UI
    self.totalPriceBlock();
    
}


- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
