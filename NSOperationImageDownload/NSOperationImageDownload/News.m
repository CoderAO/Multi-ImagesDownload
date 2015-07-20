//
//  News.m
//  NSOperationImageDownload
//
//  Created by 敖然 on 15/7/20.
//  Copyright (c) 2015年 AT. All rights reserved.
//

#import "News.h"

@implementation News

+ (instancetype)newsWithDic:(NSDictionary *)dic {
    News *news = [[self alloc] init];
    [news setValuesForKeysWithDictionary:dic];
    return news;
}

@end
