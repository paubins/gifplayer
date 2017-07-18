//
//  SpotlightController.m
//  GifPlayer
//
//  Created by Patrick Aubin on 7/13/17.
//  Copyright © 2017 com.paubins.GifPlayer. All rights reserved.
//

#import "SpotlightController.h"

//#import <CoreSpotlight/CoreSpotlight.h>
//#import <MobileCoreServices/MobileCoreServices.h>
//
//@implementation SpotlightController
//
//    
//-(void *)creatSearchableItem{
//    
//    CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeImage];
//    
//    // 标题
//    attributeSet.title = @"标题";
//    // 关键字,NSArray可设置多个
//    attributeSet.keywords = @[@"demo",@"sp"];
//    // 描述
//    attributeSet.contentDescription = @"description";
//    // 图标, NSData格式
//    attributeSet.thumbnailData = UIImagePNGRepresentation([UIImage imageNamed:@"icon"]);
//    // Searchable item
//    CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:@"1" domainIdentifier:@"linkedme.cc" attributeSet:attributeSet];
//    
//    NSMutableArray *searchItems = [NSMutableArray arrayWithObjects:item, nil];
//    //indexSearchableItems 接收参数NSMutableArray
//    [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:searchItems completionHandler:^(NSError * error) {
//        if (error) {
//            NSLog(@"索引创建失败:%@",error.localizedDescription);
//        }else{
//            [self performSelectorOnMainThread:@selector(showAlert:) withObject:@"索引创建成功" waitUntilDone:NO];
//        }
//    }];
//}
//    
//    //通过identifier删除索引
//- (void *)deleteSearchableItemFormIdentifier{
//    [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithIdentifiers:@[@"1"] completionHandler:^(NSError * _Nullable error) {
//        if (error) {
//            NSLog(@"%@", error.localizedDescription);
//        }else{
//            [self performSelectorOnMainThread:@selector(showAlert:) withObject:@"通过identifier删除索引成功" waitUntilDone:NO];
//        }
//    }];
//}
//    
//    //通过DomainIdentifiers删除索引
//- (void *)deleteSearchableItemFormDomain{
//    [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithDomainIdentifiers:@[@"linkedme.cc"] completionHandler:^(NSError * _Nullable error) {
//        if (error) {
//            NSLog(@"%@", error.localizedDescription);
//        }else{
//            [self performSelectorOnMainThread:@selector(showAlert:) withObject:@"通过DomainIdentifiers删除索引成功" waitUntilDone:NO];
//        }
//    }];
//}
//    
//    //删除所有索引
//- (void *)deleteAllSearchableItem{
//    [[CSSearchableIndex defaultSearchableIndex] deleteAllSearchableItemsWithCompletionHandler:^(NSError * _Nullable error) {
//        if (error) {
//            NSLog(@"%@",error.localizedDescription);
//        }else{
//            [self performSelectorOnMainThread:@selector(showAlert:) withObject:@"删除所有索引成功" waitUntilDone:NO];
//        }
//    }];
//}
//    
//
//    
//@end
