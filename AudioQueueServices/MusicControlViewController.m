//
//  MusicControlViewController.m
//  AudioQueueServices
//
//  Created by Super on 2017/5/25.
//  Copyright © 2017年 cmjstudio. All rights reserved.
//

#import "MusicControlViewController.h"
#import <AVFoundation/AVFoundation.h>
#define kMusicFile @"刘若英 - 原来你也在这里.mp3"
#define kMusicSinger @"刘若英"
#define kMusicTitle @"原来你也在这里"
@interface MusicControlViewController ()<AVAudioPlayerDelegate>
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;//播放器
@property (strong, nonatomic) UILabel *controlPanel; //控制面板
@property (strong, nonatomic) UIProgressView *playProgress;//播放进度
@property (strong, nonatomic) UILabel *musicSinger; //演唱者
@property (strong, nonatomic) UIButton *playOrPause; //播放/暂停按钮(如果tag为0认为是暂停状态，1是播放状态)
@property (strong ,nonatomic) NSTimer *timer;//进度更新定时器
@end
@implementation MusicControlViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.controlPanel = [[UILabel alloc]initWithFrame:CGRectMake(0, 300, 300, 200)];
    self.playProgress = [[UIProgressView alloc]initWithFrame:CGRectMake(0, 20, 300, 5)];
    self.musicSinger = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 300, 20)];
    self.playOrPause = [[UIButton alloc]initWithFrame:CGRectMake(0, 100, 100, 80)];
    self.timer =[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateProgress) userInfo:nil repeats:true];
    [self.playOrPause addTarget:self action:@selector(playClick:) forControlEvents:UIControlEventTouchUpInside];
    self.title=kMusicTitle;
    self.musicSinger.text=kMusicSinger;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //开启远程控制
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}
/**
 *  当前控制器视图不显示时取消远程控制
 */
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    //[self resignFirstResponder];
}
/**
 *  创建播放器
 *  @return 音频播放器
 */
-(AVAudioPlayer *)audioPlayer{
    if (!_audioPlayer) {
        NSString *urlStr=[[NSBundle mainBundle]pathForResource:kMusicFile ofType:nil];
        NSURL *url=[NSURL fileURLWithPath:urlStr];
        NSError *error=nil;
        //初始化播放器，注意这里的Url参数只能时文件路径，不支持HTTP Url
        _audioPlayer=[[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
        //设置播放器属性
        _audioPlayer.numberOfLoops=0;//设置为0不循环
        _audioPlayer.delegate=self;
        [_audioPlayer prepareToPlay];//加载音频文件到缓存
        if(error){
            NSLog(@"初始化播放器过程发生错误,错误信息:%@",error.localizedDescription);
            return nil;
        }
        //设置后台播放模式
        AVAudioSession *audioSession=[AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        //        [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:nil];
        [audioSession setActive:YES error:nil];
        //添加通知，拔出耳机后暂停播放
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    }
    return _audioPlayer;
}

/**
 *  播放音频
 */
-(void)play{
    if (![self.audioPlayer isPlaying]) {
        [self.audioPlayer play];
        self.timer.fireDate=[NSDate distantPast];//恢复定时器
    }
}
-(void)pause{
    if ([self.audioPlayer isPlaying]) {
        [self.audioPlayer pause];
        self.timer.fireDate=[NSDate distantFuture];//暂停定时器，注意不能调用invalidate方法，此方法会取消，之后无法恢复
        
    }
}
- (IBAction)playClick:(UIButton *)sender {
    if(sender.tag){
        sender.tag=0;
        [sender setImage:[UIImage imageNamed:@"playing_btn_play_n"] forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"playing_btn_play_h"] forState:UIControlStateHighlighted];
        [self pause];
    }else{
        sender.tag=1;
        [sender setImage:[UIImage imageNamed:@"playing_btn_pause_n"] forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"playing_btn_pause_h"] forState:UIControlStateHighlighted];
        [self play];
    }
}

/**
 *  更新播放进度
 */
-(void)updateProgress{
    float progress= self.audioPlayer.currentTime /self.audioPlayer.duration;
    [self.playProgress setProgress:progress animated:true];
}

/**
 *  一旦输出改变则执行此方法
 *  @param notification 输出改变通知对象
 */
-(void)routeChange:(NSNotification *)notification{
    NSDictionary *dic=notification.userInfo;
    int changeReason= [dic[AVAudioSessionRouteChangeReasonKey] intValue];
    //等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
    if (changeReason==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioSessionRouteDescription *routeDescription=dic[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescription= [routeDescription.outputs firstObject];
        //原设备为耳机则暂停
        if ([portDescription.portType isEqualToString:@"Headphones"]) {
            [self pause];
        }
    }
    //    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    //        NSLog(@"%@:%@",key,obj);
    //    }];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
}
#pragma mark - 播放器代理方法
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"音乐播放完成...");
    //根据实际情况播放完成可以将会话关闭，其他音频应用继续播放
    [[AVAudioSession sharedInstance]setActive:NO error:nil];
}

@end
