//
//  Manager.m
//  ShangCheng
//
//  Created by TongLi on 2016/10/27.
//  Copyright © 2016年 TongLi. All rights reserved.
//

#import "Manager.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation Manager
+ (Manager *)shareInstance {
    static Manager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[Manager alloc] init];
    });
    return manager;
}

#pragma mark - 产品 -
- (NSMutableDictionary *)homeDataSourceDic {
    if (!_homeDataSourceDic) {
        self.homeDataSourceDic = [NSMutableDictionary dictionary];
    }
    return _homeDataSourceDic;
}

//首页产品 cnum是热销产品的个数，rnum是推荐产品的个数
- (void)httpHomeProductWithCnum:(NSString *)cnum withRnum:(NSString *)rnum withSuccessHomeResult:(SuccessResult)successHomeResult withFailHomeResult:(FailResult)failHomeResult {
    
    [[NetManager shareInstance] getRequestWithURL:[[InterfaceManager shareInstance] homeProductURLWithCnum:cnum withRnum:rnum] withParameters:nil withContentTypes:nil withHeaderArr:nil withSuccessResult:^(AFHTTPRequestOperation *operation, id successResult) {
        
        if (operation.response.statusCode == 200) {
            //网络成功，解析数据
            [self analyzeHomeProductJsonDic:successResult withSuccessHomeResult:successHomeResult withFailHomeResult:failHomeResult];

        }
        
    } withError:^(AFHTTPRequestOperation *operation, NSError *errorResult) {
        NSLog(@"%ld",operation.response.statusCode);
        failHomeResult([operation.responseObject objectForKey:@"Message"]);
    }];
}

- (void)analyzeHomeProductJsonDic:(NSDictionary *)jsonDic withSuccessHomeResult:(SuccessResult)successHomeResult withFailHomeResult:(FailResult)failHomeResult {

    //解析热销产品
    NSMutableArray *hotArr = [NSMutableArray array];
    NSArray *crazeArr = [jsonDic objectForKey:@"craze"];
    for (NSDictionary *crazeDic in crazeArr) {
        ProductModel *hotProductModel = [[ProductModel alloc] init];
        [hotProductModel setValuesForKeysWithDictionary:crazeDic];
        
        [hotArr addObject:hotProductModel];
    }
    [self.homeDataSourceDic setValue:hotArr forKey:@"热销"];
    
    //解析推荐产品
    NSMutableArray *recommendArr = [NSMutableArray array];
    NSArray *recomArr = [jsonDic objectForKey:@"recom"];
    for (NSDictionary *recomDic in recomArr) {
        ProductClassModel *tempClassModel = [[ProductClassModel alloc] init];
        [tempClassModel setValuesForKeysWithDictionary:recomDic];
        tempClassModel.productArr = [NSMutableArray array];

        for (NSDictionary *productDic in [recomDic objectForKey:@"item"]) {
            
            ProductModel *tempProductModel = [[ProductModel alloc] init];
            [tempProductModel  setValuesForKeysWithDictionary:productDic];
            
            [tempClassModel.productArr addObject:tempProductModel];
        }

        [recommendArr addObject:tempClassModel];
    }
    [self.homeDataSourceDic setValue:recommendArr forKey:@"推荐"];
    
    successHomeResult(self.homeDataSourceDic);
    
}


//获取产品详情
- (void)httpProductDetailInfoWithProductDetailModel:(ProductDetailModel *)productDetailModel withSuccessDetailResult:(SuccessResult)successDetailResult withFailDetailResult:(FailResult)failDetailResult {

    [[NetManager shareInstance] getRequestWithURL:[[InterfaceManager shareInstance] productDetailURLWithProductID:productDetailModel.productModel.productID] withParameters:nil withContentTypes:nil withHeaderArr:nil withSuccessResult:^(AFHTTPRequestOperation *operation, id successResult) {
        
        if (operation.response.statusCode == 200) {
            //网络成功，解析数据
            [self analyzeProductDetailInfoWithJsonArr:successResult withProductDetailModel:productDetailModel withSuccessDetailResult:successDetailResult withFailDetailResult:failDetailResult];
        }
        
    } withError:^(AFHTTPRequestOperation *operation, NSError *errorResult) {
        NSLog(@"%ld",operation.response.statusCode);
        failDetailResult([operation.responseObject objectForKey:@"Message"]);
    }];
    
}

//解析产品详情
- (void)analyzeProductDetailInfoWithJsonArr:(NSArray *)jsonArr withProductDetailModel:(ProductDetailModel *)productDetailModel withSuccessDetailResult:(SuccessResult)successDetailResult withFailDetailResult:(FailResult)failDetailResult {
    if (jsonArr.count > 0) {

        ProductModel *tempModel = [[ProductModel alloc] init];
        [tempModel setValuesForKeysWithDictionary:jsonArr[0]];
        
        productDetailModel.productModel = tempModel;
        [productDetailModel setValuesForKeysWithDictionary:jsonArr[0]];
        
        successDetailResult(productDetailModel);
        
    }else {
        failDetailResult(@"暂时没有数据哦亲");
    }
    
    
}

//获取产品的所有规格
- (void)httpProductAllFarmatInfoWithProductDetailModel:(ProductDetailModel *)productDetailModel withSuccessFarmatResult:(SuccessResult)successFarmatResult withFailFarmatResult:(FailResult)failFarmatResult {

    [[NetManager shareInstance] getRequestWithURL:[[InterfaceManager shareInstance] productAllFarmatWithProductID:productDetailModel.productModel.productID] withParameters:nil withContentTypes:nil withHeaderArr:nil withSuccessResult:^(AFHTTPRequestOperation *operation, id successResult) {
        //解析
        [self analyzeProductAllFarmatInfoWithJsonArr:successResult withProductDetailModel:productDetailModel withSuccessFarmatResult:successFarmatResult withFailFarmatResult:failFarmatResult];
        
    } withError:^(AFHTTPRequestOperation *operation, NSError *errorResult) {
        NSLog(@"%ld",operation.response.statusCode);
        failFarmatResult([operation.responseObject objectForKey:@"Message"]);

    }];
}

- (void)analyzeProductAllFarmatInfoWithJsonArr:(NSArray *)jsonArr withProductDetailModel:(ProductDetailModel *)productDetailModel withSuccessFarmatResult:(SuccessResult)successFarmatResult withFailFarmatResult:(FailResult)failFarmatResult {
    
    productDetailModel.productFarmatArr = [NSMutableArray array];
    for (NSDictionary *jsonDic in jsonArr) {
        ProductFormatModel *formatModel = [[ProductFormatModel alloc] init];
        [formatModel setValuesForKeysWithDictionary:jsonDic];
        formatModel.seletctCount = 1;
        [productDetailModel.productFarmatArr addObject:formatModel];
    }
    successFarmatResult(productDetailModel);
    
}



#pragma mark - 购物车 -
//将产品加入购物车
- (void)httpProductToShoppingCarWithProductDetailModel:(ProductDetailModel *)productDetailModel withSuccessToShoppingCarResult:(SuccessResult)successToShoppingCarResult withFailToShoppingCarResult:(FailResult)failToShoppingCarResult {
    NSString *tempProductCount ;
    for (ProductFormatModel *tempFormatModel in productDetailModel.productFarmatArr) {
        if (tempFormatModel.isSelect == YES) {
            tempProductCount = [NSString stringWithFormat:@"%ld",tempFormatModel.seletctCount];
        }
    }
    
    NSDictionary *valueDic = @{@"userid":self.memberInfoModel.u_id,@"sid":productDetailModel.productModel.productFormatID,@"number":tempProductCount};
    
    //给value加密
    NSString *secretStr = [self digest:[NSString stringWithFormat:@"%@Nongyao_Com001", [self dictionaryToJson:@[valueDic]]]];
    
    NSDictionary *parametersDic = @{@"m":secretStr,@"value":@[valueDic]};
    
    [[NetManager shareInstance] postRequestWithURL:[[InterfaceManager shareInstance] shoppingCarBaseURL] withParameters:parametersDic withContentTypes:@"string" withHeaderArr:@[@{@"Authorization":self.memberInfoModel.token}] withSuccessResult:^(AFHTTPRequestOperation *operation, id successResult) {
        NSLog(@" %ld",operation.response.statusCode);
        successToShoppingCarResult(successResult);

    } withError:^(AFHTTPRequestOperation *operation, NSError *errorResult) {
        NSLog(@"请求失败 %ld--%@",operation.response.statusCode,[operation.responseObject objectForKey:@"Message"]);

    }];
    
    
}

- (NSMutableArray *)shoppingCarDataSourceArr {
    if (!_shoppingCarDataSourceArr) {
        self.shoppingCarDataSourceArr = [NSMutableArray array];
    }
    return _shoppingCarDataSourceArr;
}

//判断是否全选了
- (void)isAllSelectForShoppingCarAction {
    //如果有一个没被选择，那么就是非全选
    if (self.shoppingCarDataSourceArr.count > 0) {
        for (ShoppingCarModel *tempModel in self.shoppingCarDataSourceArr) {
            if (tempModel.isSelectedShoppingCar == NO) {
                
                self.isAllSelectForShoppingCar = NO;
                //计算金额

                return ;
            }
        }
        self.isAllSelectForShoppingCar = YES;

    }else {
        //如果购物车没有东西，那么就是非全选
        self.isAllSelectForShoppingCar = NO;
    }
    
}

//网络得到购物车数据
- (void)httpShoppingCarDataWithUserId:(NSString *)userId WithSuccessResult:(SuccessResult)shoppingCarSuccessResult withFailResult:(FailResult)failResult {
    
    [[NetManager shareInstance] getRequestWithURL:[[InterfaceManager shareInstance] getShoppingCarProductUrlWithUserId:userId] withParameters:nil withContentTypes:nil withHeaderArr:@[@{@"Authorization":self.memberInfoModel.token}] withSuccessResult:^(AFHTTPRequestOperation *operation, id successResult) {
        
        NSLog(@"--%ld",operation.response.statusCode);
        if (operation.response.statusCode == 200) {
            //请求成功，封装模型
            [self analyzeShoppingCarDataWithJsonData:successResult WithSuccessResult:shoppingCarSuccessResult];
            
        }else {
            failResult(@"未知错误，请稍后再试");
        }
        
    } withError:^(AFHTTPRequestOperation *operation, NSError *errorResult) {
        NSLog(@"购物车请求失败 %ld--%@",operation.response.statusCode,[operation.responseObject objectForKey:@"Message"]);
        
        failResult([operation.responseObject objectForKey:@"Message"]);

    }];
    
}

//封装购物车模型
- (void)analyzeShoppingCarDataWithJsonData:(NSArray *)jsonDataArr WithSuccessResult:(SuccessResult)successResult {
    
    if (jsonDataArr.count > 0) {
        for (NSDictionary *tempJsonDic in jsonDataArr) {
            //封装产品
            ProductModel *tempProductModel = [[ProductModel alloc] init];
            [tempProductModel setValuesForKeysWithDictionary:tempJsonDic];
            //封装购物车信息
            ShoppingCarModel *tempShoppingCarModel = [[ShoppingCarModel alloc] init];
            [tempShoppingCarModel setValuesForKeysWithDictionary:tempJsonDic];
            tempShoppingCarModel.shoppingCarProduct = tempProductModel;
            tempShoppingCarModel.isSelectedShoppingCar = NO;
            
            //加到数组中
            [self.shoppingCarDataSourceArr addObject:tempShoppingCarModel];
        }
    }
    successResult(self.shoppingCarDataSourceArr);
}


//删除购物车的内容
- (void)deleteShoppingCarWithProductIndexSet:(NSMutableIndexSet *)productIndexSet WithSuccessResult:(SuccessResult)deleteSuccessResult withFailResult:(FailResult)deleteFailResult {

    //遍历产品集合，然后拼成字符串
    __block NSString *tempUrl = @""  ;
    [productIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        //从数组中得到具体的产品模型
        ShoppingCarModel *tempModel = self.shoppingCarDataSourceArr[idx];
        
        tempUrl = [tempUrl stringByAppendingString:tempModel.c_id];
        tempUrl = [tempUrl stringByAppendingString:@","];
    }];
    tempUrl = [tempUrl substringToIndex:tempUrl.length-1];

    //对id加密，id+Nongyao_Com001
    //明文
    NSString *clearStr = [NSString stringWithFormat:@"%@Nongyao_Com001",tempUrl];
    NSString *secretStr = [self digest:clearStr];
    
    
    [[NetManager shareInstance] deleteRequestWithURL:[[InterfaceManager shareInstance] deleteShoppingCarProductUrlWithShoppingCarID:tempUrl withSecret:secretStr] withParameters:nil withContentTypes:@"string" withHeaderArr:@[@{@"Authorization":self.memberInfoModel.token}] withSuccessResult:^(AFHTTPRequestOperation *operation, id successResult) {
        NSLog(@"%ld -- %@",operation.response.statusCode,successResult);

        if (operation.response.statusCode == 200) {
            //远程数据库删除成功,本地删除数据源
            //删除数据源
            [self.shoppingCarDataSourceArr removeObjectsAtIndexes:productIndexSet];
            
            //判断一下是否全选了
            [self isAllSelectForShoppingCarAction];

            //block返回，刷新UI
            deleteSuccessResult(productIndexSet);
        }
    } withError:^(AFHTTPRequestOperation *operation, NSError *errorResult) {
        //删除失败
        NSLog(@"%ld -- %@",operation.response.statusCode,[operation.responseObject objectForKey:@"Message"]);
    }];
    
}

- (void)addOrLessShoppingCarProductCountWithShoppingModel:(ShoppingCarModel *)shoppingModel withIsAddOrLess:(BOOL)isAdd withAddOrLessSuccessResult:(SuccessResult)addOrLessSuccessResult withaddOrLessFailResult:(FailResult)addOrLessFailResult {
    
    NSInteger tempCount = [shoppingModel.c_number integerValue];
    if (isAdd == YES) {
        tempCount++;
    }else {
        
        //如果个数已经是1了，就不能再减少了
        if (tempCount == 1) {
            addOrLessFailResult(@"商品最少为1");
            return;
        }
        tempCount--;
    }
    NSString *tempCountStr = [NSString stringWithFormat:@"%ld",tempCount];
    
    NSDictionary *valueDic = @{@"userid":self.memberInfoModel.u_id,@"number":tempCountStr};
    
    //给value加密
    NSString *secretStr = [self digest:[NSString stringWithFormat:@"%@Nongyao_Com001", [self dictionaryToJson:valueDic]]];
    
    NSDictionary *parametersDic = @{@"m":secretStr,@"value":@[valueDic]};
    
    [[NetManager shareInstance] putRequestWithURL:[[InterfaceManager shareInstance] shoppingAdd:shoppingModel.c_id] withParameters:parametersDic withContentTypes:@"string" withHeaderArr:@[@{@"Authorization":self.memberInfoModel.token}] withSuccessResult:^(AFHTTPRequestOperation *operation, id successResult) {
        
        NSLog(@"%ld -- %@",operation.response.statusCode,successResult);
        
        if (operation.response.statusCode == 200) {
            //修改数据源个数
            shoppingModel.c_number = tempCountStr;
            //修改数据源总价
            shoppingModel.totalprice = [NSString stringWithFormat:@"%ld", [shoppingModel.shoppingCarProduct.productPrice integerValue] * [shoppingModel.c_number integerValue] ];
            //刷新
            addOrLessSuccessResult(shoppingModel);
        }else {
            addOrLessFailResult(@"增加数量失败");
        }
        
    } withError:^(AFHTTPRequestOperation *operation, NSError *errorResult) {
        NSLog(@"%ld -- %@",operation.response.statusCode,errorResult);
        addOrLessFailResult([operation.responseObject objectForKey:@"Message"]);

    }];
    
}


//计算总金额
- (float)selectProductTotalPrice {
    float totalPrice = 0;
    for (ShoppingCarModel *tempModel in self.shoppingCarDataSourceArr) {
        //判断这个产品是否被选中
        if (tempModel.isSelectedShoppingCar == YES) {
            // 一个产品的总价格 = 单价*数量
            totalPrice += [tempModel.totalprice floatValue];
        }
    }
    return totalPrice;
}


#pragma mark - 订单 -
- (NSMutableDictionary *)orderListDataSourceDic {
    if (_orderListDataSourceDic == nil) {
        self.orderListDataSourceDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableArray array],@"1",[NSMutableArray array],@"2",[NSMutableArray array],@"3",[NSMutableArray array],@"4", nil];
    }
    return _orderListDataSourceDic;
}
//订单列表。 pageIndex页数,pageSize多少数据
- (void)getOrderListDataWithUserID:(NSString *)userID withOrderStatus:(NSString *)orderStatus withPageIndex:(NSString *)pageIndex withPageSize:(NSString *)pageSize downPushRefresh:(BOOL)downPushRefresh withUpPushReload:(BOOL)upPushReload withOrderListSuccessResult:(SuccessResult)orderListSuccessResult withOrderListFailResult:(FailResult)orderListFailResult {
    NSString *orderStatusPar ;
    //全部
    if ([orderStatus isEqualToString:@"1"]) {
        orderStatusPar = @"";
    }
    //待付款
    if ([orderStatus isEqualToString:@"2"]) {
        orderStatusPar = @"0,1B,1A";
    }
    //进行中
    if ([orderStatus isEqualToString:@"3"]) {
        orderStatusPar = @"1";
    }
    //已完成
    if ([orderStatus isEqualToString:@"4"]) {
        orderStatusPar = @"9";
    }
    
    //如果是下拉刷新,或者是下拉加载，都要请求数据
    if (downPushRefresh == YES || upPushReload == YES) {
        //如果是下拉刷新，需要清空数据
        if (downPushRefresh == YES) {
            NSMutableArray *orderListArr = [self.orderListDataSourceDic objectForKey:orderStatus];
            [orderListArr removeAllObjects];
        }
        //请求数据
        [[NetManager shareInstance] getRequestWithURL:[[InterfaceManager shareInstance] orderListWithUserID:userID withOrderStatus:orderStatusPar withPageIndex:pageIndex withPageSize:pageSize] withParameters:nil withContentTypes:nil withHeaderArr:@[@{@"Authorization":self.memberInfoModel.token}] withSuccessResult:^(AFHTTPRequestOperation *operation, id successResult) {
            NSLog(@"%ld -- %@",operation.response.statusCode,successResult);
            NSLog(@"%@",[self dictionaryToJson:successResult]);
            if (operation.response.statusCode == 200) {
                //解析
                [self analyzeOrderListWithJsonArr:successResult withOrderStatus:orderStatus withOrderListSuccessResult:orderListSuccessResult withOrderListFailResult:orderListFailResult];
                
            }
        } withError:^(AFHTTPRequestOperation *operation, NSError *errorResult) {
            //失败
            NSLog(@"%ld -- %@",operation.response.statusCode,errorResult);
            orderListFailResult([operation.responseObject objectForKey:@"Message"]);

        }];

        
    }else {
        //既不是上拉刷新，也不是加载，那就看原来有没有数据，如果有，就不用请求，如果没有在请求
        NSMutableArray *orderListArr = [self.orderListDataSourceDic objectForKey:orderStatus];
        if (orderListArr.count == 0) {
            //如果没有数据，就请求
            [[NetManager shareInstance] getRequestWithURL:[[InterfaceManager shareInstance] orderListWithUserID:userID withOrderStatus:orderStatusPar withPageIndex:pageIndex withPageSize:pageSize] withParameters:nil withContentTypes:nil withHeaderArr:@[@{@"Authorization":self.memberInfoModel.token}] withSuccessResult:^(AFHTTPRequestOperation *operation, id successResult) {
                NSLog(@"%ld -- %@",operation.response.statusCode,successResult);
                NSLog(@"%@",[self dictionaryToJson:successResult]);
                if (operation.response.statusCode == 200) {
                    //解析
                    [self analyzeOrderListWithJsonArr:successResult withOrderStatus:orderStatus withOrderListSuccessResult:orderListSuccessResult withOrderListFailResult:orderListFailResult];
                    
                }
            } withError:^(AFHTTPRequestOperation *operation, NSError *errorResult) {
                //失败
                NSLog(@"%ld -- %@",operation.response.statusCode,errorResult);
                orderListFailResult([operation.responseObject objectForKey:@"Message"]);
            }];

        }else {
            //直接block返回刷新数据
            orderListSuccessResult(self.orderListDataSourceDic);
        }
        
    }

}

//解析订单列表
- (void)analyzeOrderListWithJsonArr:(NSArray *)jsonArr withOrderStatus:(NSString *)orderStatus withOrderListSuccessResult:(SuccessResult)orderListSuccessResult withOrderListFailResult:(FailResult)orderListFailResult {
    //得到模型数组
    NSMutableArray *orderListArr = [self.orderListDataSourceDic objectForKey:orderStatus];
    
    for (NSDictionary *jsonDic in jsonArr) {
        SupOrderModel *supOrderModel = [[SupOrderModel alloc] init];
        [supOrderModel setValuesForKeysWithDictionary:jsonDic];
        //加入数组
        [orderListArr addObject:supOrderModel];
    }
    
    orderListSuccessResult(self.orderListDataSourceDic);
    
}


#pragma mark - 注册登录 -
//登录
- (void)loginActionWithUserID:(NSString *)userID withPassword:(NSString *)password withLoginSuccessResult:(SuccessResult )loginSuccessResult withLoginFailResult:(FailResult)loginFailResult {
    //清空原有的个人数据
    self.memberInfoModel = nil;
//    {"loginname":"admin","password":"3CBFCCCB67766883CF4F03B74A763CDC","facility":"1"}
    NetManager *netManager = [NetManager shareInstance];
    //参数.密码需要md5加密
    NSDictionary *parameter = @{@"loginname": userID, @"password": password,@"facility":@"4"};

    [netManager postRequestWithURL:[[InterfaceManager shareInstance] loginPOSTUrl] withParameters:parameter withContentTypes:nil withHeaderArr:nil withSuccessResult:^(AFHTTPRequestOperation *operation, id successResult) {
        //得到网络请求状态码
        NSLog(@"%ld",operation.response.statusCode);
        if (operation.response.statusCode == 200) {
            //登录成功，
            //解析数据，保存到本地
            BOOL locationResult = [self analyzeMemberWithJsonDic:successResult[0] withPassword:password];
            //如果存入本地成功
            if (locationResult == YES) {
                loginSuccessResult(successResult);
                
#warning 登录成功发送通知
                [[NSNotificationCenter defaultCenter] postNotificationName:@"logedIn" object:self userInfo:nil];
                
            }else{
                loginFailResult(@"未知错误，登录失败，请稍后再试");

            }
            
        }else{
            loginFailResult(@"未知服务器错误，请联系客服");

        }
        
    } withError:^(AFHTTPRequestOperation *operation, NSError *errorResult) {
        
        //得到网络请求状态码
        NSLog(@"%ld -- %@",operation.response.statusCode,[operation.responseObject objectForKey:@"Message"]);

        if (operation.response.statusCode == 400 ) {
            loginFailResult([operation.responseObject objectForKey:@"Message"]);
        }else if(operation.response.statusCode == 500) {
            loginFailResult(@"未知服务器错误，请联系客服");
        }else {
            loginFailResult(@"网络连接失败，请检查网络后重试");
        }
        
    }];
}

- (BOOL)analyzeMemberWithJsonDic:(NSDictionary *)jsonDic withPassword:(NSString *)password {
    
    MemberInfoModel *memberInfoModel = [[MemberInfoModel alloc] init];
    [memberInfoModel setValuesForKeysWithDictionary:jsonDic ];

//    memberInfoModel.u_mobile = [[jsonDic objectForKey:@"user"] objectForKey:@"u_mobile"];
    memberInfoModel.userPassword = password;
    //存到本地利用归档
    BOOL saveResult = [self saveMemberInfoModelToLocationWithMemberInfo:memberInfoModel];
    if (saveResult == YES) {
        //存入本地成功
        self.memberInfoModel = memberInfoModel;
        return YES;
    }else{
        return NO;

    }

}


#pragma mark - MD5加密 -
//  封装字符串加密方法
- (NSString *)digest:(NSString *)sourceStr {
    //把OC要转化为C语言字符串
    const char * cStr = [sourceStr UTF8String];
    
    //得到C语言字符串的长度
    unsigned long cStrLenth = strlen(cStr);
    //  声明一个字符数组,个数为16
    unsigned char theResult[CC_MD5_DIGEST_LENGTH];
    //使用这个函数进行加密。参数1：要加密的字符串；参数2：C语言字符串的长度。参数3：MD5函数声明的密文由16个16进制的字符组成，这个参数，其实就是一个数组首地址的指针，这个数组用来存放这个函数生成16个16进制的字符
    CC_MD5(cStr, (CC_LONG)cStrLenth, theResult);
    
    //遍历这个数组，把他们拼接起来就是加密后的字符串(密文)了
    NSMutableString *secretStr = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        NSLog(@"%02X",theResult[i]);
        //这个数组中的类型是%02X
        [secretStr appendFormat:@"%02X",theResult[i]];
    }
    return secretStr;
}

#pragma mark - 归档，将个人信息存入本地 - 
//归档 写入沙盒
- (BOOL)saveMemberInfoModelToLocationWithMemberInfo:(MemberInfoModel *)memberInfo {
    NSArray *_paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *_documentPath = [_paths lastObject];
    NSLog(@"%@",_documentPath);
    NSString *_personFilePath = [_documentPath stringByAppendingPathComponent:@"memberInfoModel.archiver"];
    
    //实例化一个可变二进制数据的对象
    NSMutableData *_writingData = [NSMutableData data];
    //根据_writingData创建归档器对象
    NSKeyedArchiver *_archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:_writingData];
    //对指定数据做归档，并将归档数据写入到_writingData中
    [_archiver encodeObject:memberInfo forKey:@"memberInfoModel"];
    //完成归档
    [_archiver finishEncoding];
    
    //将_writingData写入到指定文件路径
    return  [_writingData writeToFile:_personFilePath atomically:YES];
}

//反归档，从沙盒中读取
- (BOOL)readMemberInfoModelFromLocation {
    NSArray *_paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *_documentPath = [_paths lastObject];
    NSLog(@"%@",_documentPath);
    
    NSString *_personFilePath = [_documentPath stringByAppendingPathComponent:@"memberInfoModel.archiver"];
    //获取二进制字节流对象
    NSData *_readingData = [NSData dataWithContentsOfFile:_personFilePath];
    //通过_readingData对象来创建解档器对象
    NSKeyedUnarchiver *_unarchiver = [[NSKeyedUnarchiver alloc]initForReadingWithData:_readingData];
    if (_unarchiver == nil) {
        return NO;
    }else {
        //对二进制字节流做解档操作
        MemberInfoModel *membermodel = [_unarchiver decodeObjectForKey:@"memberInfoModel"];
        //完成解档
        [_unarchiver finishDecoding];
        //将从沙盒读取的个人信息，赋给当前的单例model
        if (membermodel.u_mobile != nil || ![membermodel.u_mobile isEqualToString:@""]) {
            self.memberInfoModel = membermodel;
            return YES;
        }else{
            return NO;
        }
        
    }
    
}

//是否已经登陆了
- (BOOL)isLoggedInStatus {
    if ([Manager shareInstance].memberInfoModel.u_id != nil && ![[Manager shareInstance].memberInfoModel.u_id isEqualToString:@""]) {
        return YES;
    }else {
        return NO;
    }

}
//退出登录
- (void)logOffAction {
    //清空单例模型
    self.memberInfoModel = nil;
    //清空本地存储的模型
    [self clearMemberInfoFromLocation];
    //发送通知
#warning 退出登录发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"logOff" object:self userInfo:nil];
    
    
}
//清空本地的用户信息
- (void)clearMemberInfoFromLocation {
    NSArray *_paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *_documentPath = [_paths lastObject];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *memberInfoPath = [_documentPath stringByAppendingPathComponent:@"memberInfoModel.archiver"];
    
    BOOL isExists = [fileManager fileExistsAtPath:memberInfoPath];
    
    if (isExists) {
        
        NSError *err;
        
        [fileManager removeItemAtPath:memberInfoPath error:&err];
        
    }
}



//获取手机验证码
- (void)httpMobileCodeWithMobileNumber:(NSString *)mobileNumber withCodeSuccessResult:(SuccessResult)codeSuccessResult withCodeFailResult:(FailResult)codeFailResult {
    
    NSDictionary *valueDic = @{@"tel":mobileNumber};
    
    //给value加密
    NSString *secretStr = [self digest:[NSString stringWithFormat:@"%@Nongyao_Com001", [self dictionaryToJson:@[valueDic]]]];
    
    NSDictionary *parametersDic = @{@"m":secretStr,@"value":@[valueDic]};
    
    [[NetManager shareInstance] postRequestWithURL:[[InterfaceManager shareInstance] mobileCodePOST] withParameters:parametersDic withContentTypes:@"string" withHeaderArr:nil withSuccessResult:^(AFHTTPRequestOperation *operation, id successResult) {
        NSLog(@"%ld",operation.response.statusCode);
        codeSuccessResult(@"200");
        
    } withError:^(AFHTTPRequestOperation *operation, NSError *errorResult) {
        NSLog(@"请求失败 %ld--%@",operation.response.statusCode,[operation.responseObject objectForKey:@"Message"]);
        codeFailResult([operation.responseObject objectForKey:@"Message"]);
    }];
    
}

//检验手机验证码
- (void)httpCheckMobileCodeWithMobileNumber:(NSString *)mobileNumber withCode:(NSString *)code withCodeSuccessResult:(SuccessResult)codeSuccessResult withCodeFailResult:(FailResult)codeFailResult {
    [[NetManager shareInstance] getRequestWithURL:[[InterfaceManager shareInstance] checkMobileCodeWithMobileNumber:mobileNumber withCode:code] withParameters:nil withContentTypes:@"string" withHeaderArr:nil withSuccessResult:^(AFHTTPRequestOperation *operation, id successResult) {
        NSLog(@"%ld",operation.response.statusCode);
        codeSuccessResult(@"200");
        
    } withError:^(AFHTTPRequestOperation *operation, NSError *errorResult) {
        NSLog(@"请求失败 %ld--%@",operation.response.statusCode,[operation.responseObject objectForKey:@"Message"]);
        codeFailResult(@"验证失败");
    }];
}
//注册
- (void)httpRegisterWithMobileNumber:(NSString *)mobileNumber withPassword:(NSString *)password withUserType:(NSString *)usertType withAreaId:(NSString *)areaId withRegisterSuccess:(SuccessResult )registerSuccessResult withRegisterFailResult:(FailResult)registerFailResult {
    
    password = [self digest:password];
    
//    NSDictionary *valueDic = @{@"password":password,@"usertype":usertType,@"username":mobileNumber,@"email":@"",@"mobile":mobileNumber,@"qq":@"",@"areaid":areaId};
    
    NSArray *valueArr = @[@{@"password":password},@{@"usertype":usertType},@{@"username":mobileNumber},@{@"email":@""},@{@"mobile":mobileNumber},@{@"qq":@""},@{@"areaid":areaId},@{@"stauts":@"1"}];
    
    NSString *newJsonStr = [self changeJsonStrSortWithOldStr:[self dictionaryToJson:valueArr]];
    
    //给value加密
    NSString *secretStr = [self digest:[NSString stringWithFormat:@"%@Nongyao_Com001", newJsonStr]];
    
    NSString *parametersStr = [NSString stringWithFormat:@"{\"m\":\"%@\",\"value\":%@}",secretStr,newJsonStr];
    
    
    [[NetManager shareInstance] postRequestWithURL:[[InterfaceManager shareInstance] registerPOSTUrl] withParameters:parametersStr withContentTypes:@"string" withHeaderArr:nil withSuccessResult:^(AFHTTPRequestOperation *operation, id successResult) {
        
        NSLog(@"%@",[[NSString alloc] initWithData:successResult encoding:NSUTF8StringEncoding]  );
        NSLog(@"%ld",operation.response.statusCode);
        
    } withError:^(AFHTTPRequestOperation *operation, NSError *errorResult) {
        NSLog(@"请求失败 %ld--%@",operation.response.statusCode,[operation.responseObject objectForKey:@"Message"]);

    }];
    
    
    
}

#pragma mark - 将字典变为json格式的字符串 -
- (NSString *)dictionaryToJson:(id )dic {
    
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    NSString *tempStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    tempStr = [tempStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    tempStr = [tempStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    return tempStr;
}

//处理字典顺序
- (NSString *)changeJsonStrSortWithOldStr:(NSString *)oldJsonStr {
    oldJsonStr = [oldJsonStr stringByReplacingOccurrencesOfString:@"{" withString:@""];
    oldJsonStr = [oldJsonStr stringByReplacingOccurrencesOfString:@"}" withString:@""];
    oldJsonStr = [oldJsonStr stringByReplacingOccurrencesOfString:@"[" withString:@"{"];
    oldJsonStr = [oldJsonStr stringByReplacingOccurrencesOfString:@"]" withString:@"}"];
    oldJsonStr = [NSString stringWithFormat:@"[%@]",oldJsonStr];
    
    return oldJsonStr;
}

@end
