//
//  News.h
//  NSOperationImageDownload
//
//  Created by 敖然 on 15/7/20.
//  Copyright (c) 2015年 AT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface News : NSObject

/** 标题 */
@property (nonatomic, strong) NSString *title;
/** 图片地址 */
@property (nonatomic, strong) NSString *url;

+ (instancetype)newsWithDic:(NSDictionary *)dic;

@end
