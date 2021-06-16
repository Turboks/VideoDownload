//
//  ViewController.m
//  VideoDownload
//
//  Created by Turboks on 2021/4/15.
//

//注意点！！！！！
//因为接口请求的视频太小了、基本是秒下载、使用此视频链接效果明显、可替换链接进行测试
//https://vd2.bdstatic.com/mda-kidkfudrpqgg8891/sc/cae_h264_clips/mda-kidkfudrpqgg8891.mp4

#import "ViewController.h"
#import <AFNetworking/AFNetworking.h>
#import "Movie.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    //一次下载的条数
    int allNum;
}
@property (nonatomic, strong) UITableView                           * tableView;
@property (nonatomic, strong) NSMutableArray                        * videoList;
@property (nonatomic, strong) NSMutableArray<NSURLSessionTask *>    * downloadTaskList;
@property (nonatomic, strong) NSMutableArray<UIProgressView *>      * progressViewList;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    allNum = 5;
    
    _progressViewList = [[NSMutableArray alloc] init];
    _videoList = [[NSMutableArray alloc] init];
    
    //右上角下载按钮
    UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithTitle:@"下载" style:UIBarButtonItemStyleDone target:self action:@selector(download)];
    self.navigationItem.rightBarButtonItem = item;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
    for (int i = 0; i < allNum; i++) {
        UIProgressView * pro = [[UIProgressView alloc] initWithFrame:CGRectMake(110,40,150, 20)];
        pro.backgroundColor = [UIColor redColor];
        [self.progressViewList addObject:pro];
    }
    
    //获取网络数据
    [self getdata];
}
-(void)getdata{
    NSString *urlString = @"http://c.m.163.com/nc/video/list/V9LG4B3A0/y/1-20.html";
    AFHTTPSessionManager  *manager = [AFHTTPSessionManager manager];
    [manager GET:urlString parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *arr = responseObject[@"V9LG4B3A0"];
        for (NSDictionary *dic in arr) {
            Movie *movie = [[Movie alloc]init];
            [movie setValuesForKeysWithDictionary:dic];
            [self.videoList addObject:movie];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"请求失败");
    }];
}

//开始下载
-(void)download{
    _downloadTaskList = [[NSMutableArray alloc] init];
    for (int i = 0; i < allNum; i++) {
        //获取路径libray、大文件存储的话尽量存储到cache中
        NSString * caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject];
        //视频的路径
        NSString * fileStr = [caches stringByAppendingString:[NSString stringWithFormat:@"/video%d.mp4",i]];
        // 判读缓存数据是否存在
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileStr]) {
            [[NSFileManager defaultManager] removeItemAtPath:fileStr error:nil];
        }
        Movie *movie = self.videoList[i];
        NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:movie.mp4_url]];
        AFHTTPSessionManager * manager = [[AFHTTPSessionManager alloc] init];
        __weak typeof(self) weakSelf = self;
        NSURLSessionDownloadTask * task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            float tt = downloadProgress.totalUnitCount;
            float com = downloadProgress.completedUnitCount;
            [weakSelf uploadProgress:com/tt andIndex:i];
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            NSLog(@"开始写入数据");
            NSLog(@"%@",[NSThread currentThread]);
            return [NSURL fileURLWithPath:fileStr];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            if (error == nil) {
                NSLog(@"写入成功");
            }else{
                NSLog(@"写入失败");
            }
        }];
        [_downloadTaskList addObject:task];
    }
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.downloadTaskList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    Movie * mo = self.videoList[indexPath.row];
    NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:mo.cover]];
    UIImageView * im = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 90, 90)];
    im.image = [[UIImage alloc] initWithData:data];
    im.contentMode = UIViewContentModeScaleAspectFit;
    [cell addSubview:im];
    
    [cell addSubview:self.progressViewList[indexPath.row]];
    [self.downloadTaskList[indexPath.row] resume]; //suspend: 暂停
    return cell;
}

-(void)uploadProgress:(float)num andIndex:(int)index{
    NSLog(@"%f",num);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressViewList[index].progress = num;
    });
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.progressViewList[indexPath.row].progress == 1) {
        //步骤1：获取视频路径
        NSString * caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject];
        NSString * fileStr = [caches stringByAppendingString:[NSString stringWithFormat:@"/vv%ld.mp4",(long)indexPath.row]];
        NSURL *videoUrl = [NSURL fileURLWithPath:fileStr];
        //步骤2：创建AVPlayer
        AVPlayer * avPlayer = [[AVPlayer alloc]initWithURL:videoUrl];
        //步骤3：使用AVPlayer创建AVPlayerViewController，并跳转播放界面
        AVPlayerViewController *avPlayerVC =[[AVPlayerViewController alloc] init];
        [avPlayer play];
        avPlayerVC.player= avPlayer;
        [self presentViewController:avPlayerVC animated:YES completion:nil];
    }
}
@end
