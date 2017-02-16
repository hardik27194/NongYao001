//
//  MyAgentViewController.m
//  ShangCheng
//
//  Created by TongLi on 2017/2/15.
//  Copyright © 2017年 TongLi. All rights reserved.
//

#import "MyAgentViewController.h"
#import "Manager.h"
#import "MyAgentPeopleTableViewCell.h"
#import "MyAgentOrderTableViewCell.h"
@interface MyAgentViewController ()<UITableViewDataSource,UITableViewDelegate>
//头部收益金额
@property (weak, nonatomic) IBOutlet UILabel *incomeAmountLabel;
//人员button
@property (weak, nonatomic) IBOutlet UIButton *peopleNumberButton;
//订单button
@property (weak, nonatomic) IBOutlet UIButton *orderNumberButton;


@property (weak, nonatomic) IBOutlet UITableView *myAgentTableView;
//类型，是人员或者订单 peopleType orderType
@property (nonatomic,strong)NSString *currentTypeStr;
//人员页数
@property (nonatomic,assign)NSInteger peoplePageIndex;
//订单页数
@property (nonatomic,assign)NSInteger orderPageIndex;


@end

@implementation MyAgentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    Manager *manager = [Manager shareInstance];

    // 让cell自适应高度
    self.myAgentTableView.rowHeight = UITableViewAutomaticDimension;
    //设置估算高度
    self.myAgentTableView.estimatedRowHeight = 44;
    
    //默认为第一页
    self.peoplePageIndex = 1;
    self.orderPageIndex = 1;
    //默认为人员类型
    self.currentTypeStr = @"peopleType";
    
    
    //网络请求人员数据
    [manager httpMyAgentPeopleListDataWithUserId:manager.memberInfoModel.u_id withPageindex:1 withMyAgentSuccess:^(id successResult) {
        
        [self.myAgentTableView reloadData];
        
    } withMyagentFail:^(NSString *failResultStr) {
        
    }];
    
    
    //更新头部view
    [self upHeaderView];
    
}
//更新头部View
- (void)upHeaderView {
    
    Manager *manager = [Manager shareInstance];
    
    self.incomeAmountLabel.text = [manager.myAgentDic objectForKey:@"u_amount_avail"];
    [self.orderNumberButton setTitle:[NSString stringWithFormat:@"订单(%@)",[manager.myAgentDic objectForKey:@"ordernum"] ] forState:UIControlStateNormal];
    [self.peopleNumberButton setTitle:[NSString stringWithFormat:@"人员(%@)", [manager.myAgentDic objectForKey:@"peonum"] ] forState:UIControlStateNormal];

}

//人员
- (IBAction)peopleButtonAction:(UIButton *)sender {
    //只有当前为订单类型，点击人员按钮才有效果
    if ([self.currentTypeStr isEqualToString:@"orderType"]) {
        //更改类型
        self.currentTypeStr = @"peopleType";
        
        Manager *manager = [Manager shareInstance];
        
        if ([manager.myAgentDic objectForKey:@"people"] != nil && [[manager.myAgentDic objectForKey:@"people"] isKindOfClass:[NSMutableArray class]]) {
            //不用请求，刷新cell
            NSLog(@"不用请求，只做刷新cell");
            [self.myAgentTableView reloadData];

            
        }else {
            //需要请求
            //网络请求人员数据
            
            [manager httpMyAgentPeopleListDataWithUserId:manager.memberInfoModel.u_id withPageindex:1 withMyAgentSuccess:^(id successResult) {
                
                [self.myAgentTableView reloadData];
                
            } withMyagentFail:^(NSString *failResultStr) {
                
            }];
            
        }

        
        
    }
    
}
//订单
- (IBAction)orderButtonAction:(UIButton *)sender {
    //只有当前为人员类型，点击订单按钮才有效果
    if ([self.currentTypeStr isEqualToString:@"peopleType"]) {
        //更改类型
        self.currentTypeStr = @"orderType";
        
        Manager *manager = [Manager shareInstance];
        if ([manager.myAgentDic objectForKey:@"order"] != nil && [[manager.myAgentDic objectForKey:@"people"] isKindOfClass:[NSMutableArray class]]) {
            //不用请求，刷新cell
            NSLog(@"不用请求，只做刷新cell");
            [self.myAgentTableView reloadData];
            
        }else {
            //需要请求
            //网络请求订单数据
            [manager httpMyAgentOrderListDataWithUserId:manager.memberInfoModel.u_id withPageindex:1 withMyAgentSuccess:^(id successResult) {
                [self.myAgentTableView reloadData];
                
            } withMyagentFail:^(NSString *failResultStr) {
                
            }];
            
            
        }

    }
    
}


#pragma mark - TableView Delegate -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    Manager *manager = [Manager shareInstance];
    if ([self.currentTypeStr isEqualToString:@"peopleType"]) {
        if ([manager.myAgentDic objectForKey:@"people"] != nil && [[manager.myAgentDic objectForKey:@"people"] isKindOfClass:[NSMutableArray class]]) {
            return [[manager.myAgentDic objectForKey:@"people"] count];
        }
        
    }
    
    if ([self.currentTypeStr isEqualToString:@"orderType"]) {
        if ([manager.myAgentDic objectForKey:@"order"] != nil && [[manager.myAgentDic objectForKey:@"order"] isKindOfClass:[NSMutableArray class]]) {
            return [[manager.myAgentDic objectForKey:@"order"] count];
        }
        
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Manager *manager = [Manager shareInstance];
    
    if ([self.currentTypeStr isEqualToString:@"peopleType"]) {
        MyAgentPeopleTableViewCell *peopleCell = [tableView dequeueReusableCellWithIdentifier:@"agentPeopleCell" forIndexPath:indexPath];
        MyAgentPeopleModel *peopleModel = [[manager.myAgentDic objectForKey:@"people"] objectAtIndex:indexPath.row];
        [peopleCell updateMyAgentPeopleCellWithAgentModel:peopleModel];
        return peopleCell;
    }
    
    if ([self.currentTypeStr isEqualToString:@"orderType"]) {
        MyAgentOrderTableViewCell *orderCell = [tableView dequeueReusableCellWithIdentifier:@"agentOrderCell" forIndexPath:indexPath];
        MyAgentOrderModel *orderModel = [[manager.myAgentDic objectForKey:@"order"] objectAtIndex:indexPath.row];

        [orderCell updateMyAgentOrderCellWithAgentModel:orderModel];

        return orderCell;
    }
    return 0;
    
    
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

@end
