//
//  BYMapViewVC.h
//  BYTrackDemo
//
//  Created by SunShine.Rock on 16/9/14.
//  Copyright © 2016年 Berton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MAMapKit/MAMapKit.h>

@interface BYMapViewVC : UIViewController
@property (nonatomic, strong) NSMutableArray *pointArr;//定位信息数组
@property (nonatomic, strong) MAUserLocation *currentUL;//当前位置
@end
