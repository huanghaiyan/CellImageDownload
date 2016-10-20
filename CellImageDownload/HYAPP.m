//
//  HYAPP.m
//  CellImageDownload
//
//  Created by 黄海燕 on 16/10/19.
//  Copyright © 2016年 huanghy. All rights reserved.
//

#import "HYAPP.h"

@implementation HYAPP

+ (instancetype)appWithDic:(NSDictionary*)dict
{
    HYAPP *app = [[self alloc] init];
    [app setValuesForKeysWithDictionary:dict];
    
    return app;
}

@end
