//
//  HYAPP.h
//  CellImageDownload
//
//  Created by 黄海燕 on 16/10/19.
//  Copyright © 2016年 huanghy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYAPP : NSObject
/**
 *  应用的名字
 */
@property (nonatomic ,copy)NSString *name;

@property (nonatomic ,copy)NSString *download;
/**
 *  图片url
 */
@property (nonatomic ,copy)NSString *icon;

+ (instancetype)appWithDic:(NSDictionary*)dict;

@end
