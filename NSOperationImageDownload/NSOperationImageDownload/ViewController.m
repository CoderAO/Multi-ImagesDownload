//
//  ViewController.m
//  NSOperationImageDownload
//
//  Created by 敖然 on 15/7/10.
//  Copyright (c) 2015年 AT. All rights reserved.
//

#import "ViewController.h"
#import "News.h"
#import "NewsCell.h"

@interface ViewController ()

/**
 *  全部新闻数据
 */
@property (nonatomic, strong) NSArray *newsArray;

/**
 *  图片内存缓存
 */
@property (nonatomic, strong) NSMutableDictionary *imagesCache;

/**
 *  操作队列
 */
@property (nonatomic, strong) NSOperationQueue *queue;
/**
 *  操作内存缓存
 */
@property (nonatomic, strong) NSMutableDictionary *operationCache;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (NSArray *)newsArray {
    if (!_newsArray) {
        NSArray *dictArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"News.plist" ofType:nil]];

        NSMutableArray *mArray = [NSMutableArray array];
        for (NSDictionary *dict in dictArray) {
            [mArray addObject:[News newsWithDic:dict]];
        }
        _newsArray = mArray;
    }
    return _newsArray;
}

- (NSMutableDictionary *)imagesCache {
    if (!_imagesCache) {
        _imagesCache = [NSMutableDictionary dictionary];
    }
    return _imagesCache;
}

- (NSOperationQueue *)queue {
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

- (NSMutableDictionary *)operationCache {
    if (!_operationCache) {
        _operationCache = [NSMutableDictionary dictionary];
    }
    return _operationCache;
}

#pragma mark - 数据源方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.newsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"news";
    NewsCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    News *news = self.newsArray[indexPath.row];
    cell.titleLabel.text = news.title;

    // 先从内存缓存中取图片
    __block UIImage *image = self.imagesCache[news.url];
    // 如果内存缓存中有则直接显示在cell上
    if (image) {
        cell.imgView.image = image;
    }
    else {
        cell.imgView.image = [UIImage imageNamed:@"placeholder"];
        // 如果内存缓存中没有,再去沙盒里面看看
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        // 文件全路径
        NSString *filePath = [cachePath stringByAppendingPathComponent:news.url.lastPathComponent];
        NSData *diskData = [NSData dataWithContentsOfFile:filePath];
        diskData = nil;
        // 如果沙盒有数据
        if (diskData) {
            UIImage *diskImage =[UIImage imageWithData:diskData];
            cell.imgView.image = diskImage;
            // 缓存到内存
            self.imagesCache[news.url] = diskImage;
        }
        else {
            NSBlockOperation *op = self.operationCache[news.url];
            if (!op) {
                op = [NSBlockOperation blockOperationWithBlock:^{
                    // 根据url进行下载
                    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:news.url]];
                    // 如果网络中断下载失败等导致data为空
                    if (!data) {
                        // 从操作缓存中移除,使得该图片有机会重新下载
                        [self.operationCache removeObjectForKey:news.url];
                        return;
                    }
                    image = [UIImage imageWithData:data];
                    // 写入缓存
                    self.imagesCache[news.url] = image;
                    // 写入沙盒
                    [data writeToFile:filePath atomically:YES];
                    // 回主线程展示
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    }];

                    // 下载完成,移除操作
                    [self.operationCache removeObjectForKey:news.url];
                }];
                // 进行缓存
                self.operationCache[news.url] = op;
                // 添加操作
                [self.queue addOperation:op];
            }
        }
    }
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    self.imagesCache = nil;
    self.operationCache = nil;
    [self.queue cancelAllOperations];
}

@end
