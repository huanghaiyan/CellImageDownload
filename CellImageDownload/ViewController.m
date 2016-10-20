//
//  ViewController.m
//  CellImageDownload
//
//  Created by 黄海燕 on 16/10/19.
//  Copyright © 2016年 huanghy. All rights reserved.
//

#import "ViewController.h"
#import "HYAPP.h"

//缓存路径，拼接Cache文件夹的路径与url最后的部分
#define CachedImageFile(url)[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:[url lastPathComponent]]

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
/*
 *图片缓存，下载操作缓存，沙盒缓存路径
 */
//存放所有下载完的图片
@property (nonatomic,strong) NSMutableDictionary *images;

//存放所有的下载操作（key是url,value是operation对象）
@property (nonatomic,strong) NSMutableDictionary *operations;

//存放所有下载操作的队列
@property (nonatomic,strong) NSOperationQueue* queue;
/**
 *  所有应用数据
 */
@property (nonatomic,strong) NSMutableArray* apps;

@property (nonatomic,strong) UITableView *mTableView;

@end

@implementation ViewController

- (NSMutableArray *)apps
{
    if (!_apps) {
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"apps.plist" ofType:nil];
        NSArray* dictArr = [NSArray arrayWithContentsOfFile:filePath];
        
        NSMutableArray* appsArr = [NSMutableArray array];
        for (NSDictionary* dict in dictArr) {
            
            HYAPP* app = [HYAPP appWithDic:dict];
            
            [appsArr addObject:app];
        }
        self.apps = appsArr;
    }
    return _apps;
    
}

- (NSOperationQueue *)queue
{
    if (!_queue) {
        self.queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

- (NSMutableDictionary *)operations
{
    if (!_operations) {
        
        self.operations = [NSMutableDictionary dictionary];
    }
    return _operations;
}

- (NSMutableDictionary *)images
{
    if (!_images) {
        self.images = [NSMutableDictionary dictionary];
    }
    return _images;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"沙盒路径: %@",NSHomeDirectory());
    
    _mTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height)];
    _mTableView.delegate = self;
    _mTableView.dataSource = self;
    [self.view addSubview:self.mTableView];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.apps.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    //取出数据
    HYAPP* app = self.apps[indexPath.row];
    cell.textLabel.text = app.name;
    cell.detailTextLabel.text = app.download;

    //先从images缓存中取出图片url对应的UIImage
    UIImage *image = self.images[app.icon];
    if (image) {
        //存在，说明图片已经下载成功
        cell.imageView.image = image;
    }else{
        //不存在，说明图片并未下载成功过，或者成功下载但是images里缓存失败，需要在沙盒里寻找对应的图片
        //获得url对应的沙盒缓存路径
        NSString *filePath = CachedImageFile(app.icon);
        //先从沙盒中取出图片
        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
        if (imageData) {
            //data不为空，说明沙盒中存在这个文件
            cell.imageView.image = [UIImage imageWithData:imageData];
        }else{
            //沙盒中图片文件不存在
            //在下载之前显示转为图片
            cell.imageView.image = [UIImage imageNamed:@"2"];
            //下载图片
            [self download:app.icon indexPath:indexPath];
        }
    }
    
    return cell;
}

#pragma mark -图片下载 ，imageUrl图片的url
- (void)download:(NSString *)imageUrl indexPath:(NSIndexPath *)indexPath{
    //取出当前图片url对应的下载操作（operation对象）
    NSBlockOperation *operation = self.operations[imageUrl];
    if (operation == nil) {
        //创建操作，下载图片
        __weak typeof(self) vc = self;
        operation = [NSBlockOperation blockOperationWithBlock:^{
            NSURL *url = [NSURL URLWithString:imageUrl];
            NSData *data = [NSData dataWithContentsOfURL:url];//下载
            UIImage *image = [UIImage imageWithData:data];
            if (image) {
                //如果图片存在（下载完成），存放图片到图片缓存字典中
                vc.images[imageUrl] = image;
                //将图片存入沙盒中
                //1.先将图片转化为NSData
                NSData *imageData = UIImagePNGRepresentation(image);
                //2.再生成缓存路径
                [imageData writeToFile:CachedImageFile(imageUrl) atomically:YES];
            }

            //回到主线程
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
              //从字典中移除下载操作（保证下载失败后，能重新下载）
                [vc.operations removeObjectForKey:imageUrl];
                //刷新表格，减少系统开销
                [vc.mTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:(UITableViewRowAnimationNone)];
            }];
        }];
        //添加下载操作到队列中
        [self.queue addOperation:operation];
        //添加到字典中
        self.operations[imageUrl] = operation;
    }
}

/**
 *  当用户开始拖拽表格时调用
 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    // 暂停下载
    [self.queue setSuspended:YES];
}

/**
 *  当用户停止拖拽表格时调用
 */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // 恢复下载
    [self.queue setSuspended:NO];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
