//
//  ViewController.m
//  QinzSocket
//
//  Created by Qinz on 2019/3/29.
//  Copyright © 2019 Qinz. All rights reserved.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

#import "MsgCell.h"
#import "MsgModel.h"


//htons : 将一个无符号短整型的主机数值转换为网络字节顺序，不同cpu 是不同的顺序 (big-endian大尾顺序 , little-endian小尾顺序)
#define SocketPort htons(9999)
//inet_addr是一个计算机函数，功能是将一个点分十进制的IP转换成一个长整数型数
#define SocketIP   inet_addr("127.0.0.1")

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textTF;

@property (nonatomic, assign) int client_socket;
@property (nonatomic, assign) int restartId;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectItem;

@property (nonatomic, strong) NSMutableArray *dataArrM;

@property (nonatomic, assign) BOOL isClose;

@end

@implementation ViewController

#pragma mark --创建Socket连接
- (IBAction)socketConect:(UIBarButtonItem *)sender {
    
    self.client_socket = socket(AF_INET, SOCK_STREAM, 0);
    
    if (self.client_socket == -1) {
        NSLog(@"---- socket创建失败 ------");
        return;
    }
    
    struct in_addr socketIn_addr;
    socketIn_addr.s_addr = SocketIP;
    
    struct sockaddr_in socketAddr;
    socketAddr.sin_family = AF_INET;
    socketAddr.sin_port = SocketPort;
    socketAddr.sin_addr = socketIn_addr;
   
    int result = connect(self.client_socket, (const struct sockaddr*)&socketAddr, sizeof(socketAddr));
    
    if (result != 0) {
        NSLog(@"---连接socket失败 -----");
        return;
    }
    
    sender.title = @"已连接";
    sender.enabled = NO;
    self.restartId = 0;
    
    //接受数据
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self receiveMsg];
    });
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];


    self.dataArrM = [NSMutableArray array];
}

#pragma mark --发送消息
- (IBAction)sendMsg:(UIButton *)sender {
    
    
    if (self.textTF.text.length == 0) {
        NSLog(@"消息为空");
        return;
    }
    const char *msg = self.textTF.text.UTF8String;
    
    ssize_t sendlength = send(self.client_socket, msg, strlen(msg), 0);
    NSLog(@"发送字节数:%ld",sendlength);
    
    MsgModel*model = [[MsgModel alloc]init];
    model.msg = self.textTF.text;
    model.isSend = YES;
    [self.dataArrM addObject:model];
    
    [self.tableView reloadData];
    
    self.textTF.text = @"";
    
}

#pragma mark --接受消息
-(void)receiveMsg{
    
    while (self.client_socket) {
        uint8_t buffer[1024];
        ssize_t receiveLength = recv(self.client_socket, buffer, sizeof(buffer), 0);
        
        if (receiveLength == 0) {
            self.restartId ++;
            if (self.restartId > 3) {
                self.restartId = 0;
                return;
            }
            NSLog(@"========= 数据为空，请检查连接 ========");
        }
        
        //将接受到的数据进行转换
        NSData*recvData = [NSData dataWithBytes:buffer length:receiveLength];
        NSString*recvStr = [[NSString alloc]initWithData:recvData encoding:NSUTF8StringEncoding];
        NSLog(@"==接收到的数据为:%@",recvStr);
        self.restartId = 0;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            MsgModel*model = [[MsgModel alloc]init];
            model.msg = recvStr;
            model.isSend = NO;
            [self.dataArrM addObject:model];
            
            [self.tableView reloadData];
            
        });
    }
}

#pragma mark --断开
- (IBAction)closeConnect:(UIBarButtonItem *)sender {
    
    int close_result =  close(self.client_socket);
    
    if (close_result == -1) {
        NSLog(@"====  断开失败 ======");
    }else{
        self.connectItem.enabled = NO;
        self.connectItem.title = @"sokect连接";
        NSLog(@"====  断开成功 ======");
        self.client_socket = -1;

    }
}




#pragma mark -- tableView的代理方法

#pragma mark -- 返回多少组
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

#pragma mark -- 每组返回多少个
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArrM.count;
}

#pragma mark -- 每个cell的高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}
#pragma mark -- 每个cell显示的内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    MsgCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([MsgCell class])];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MsgCell class]) owner:nil options:nil] firstObject];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.model = self.dataArrM[indexPath.row];
    
    return cell;
    
    
    
}

#pragma mark -- 每组的头部视图
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    return [UIView new];
}

#pragma mark -- 每组头部视图的高度
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 10;
}

-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    
    
    return [UIView new];
    
}


-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    
    return CGFLOAT_MIN;
}

#pragma mark -- 选择每个cell执行的操作
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

#pragma mark -- 停止滚动的代理
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
}



@end
