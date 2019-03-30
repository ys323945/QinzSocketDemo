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



#define SocketPort htons(9999)
#define SocketIP   inet_addr("127.0.0.1")

static int const kMaxConnectCount = 5;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textTF;


@property (nonatomic, assign) int serverId;
@property (nonatomic, assign) int client_socket;

@property (nonatomic, strong) NSMutableArray *dataArrM;


@end

@implementation ViewController

#pragma mark --创建Socket连接
- (IBAction)socketConect:(UIBarButtonItem *)sender {
    
    //1.创建socket
    self.serverId = socket(AF_INET, SOCK_STREAM, 0);
    
    if (self.serverId == -1) {
        NSLog(@"---- socket创建失败 ------");
        return;
    }
    
    struct in_addr socketIn_addr;
    socketIn_addr.s_addr = SocketIP;
    
    struct sockaddr_in socketAddr;
    socketAddr.sin_family = AF_INET;
    socketAddr.sin_port = SocketPort;
    socketAddr.sin_addr = socketIn_addr;
    bzero(&(socketAddr.sin_zero), 8);
   
    // 2: 绑定socket
    int bind_result = bind(self.serverId, (const struct sockaddr *)&socketAddr, sizeof(socketAddr));
    if (bind_result == -1) {
        NSLog(@"====== 绑定socket失败 ======");
        return;
    }
    
    NSLog(@"====== 绑定socket成功 ======");
    
    // 3: 监听socket
    int listen_result = listen(self.serverId, kMaxConnectCount);
    if (listen_result == -1) {
        NSLog(@"====== 监听失败 ======");
        return;
    }
    
    NSLog(@"监听成功");
    // 4: 接受客户端的链接
    for (int i = 0; i < kMaxConnectCount; i++) {
        [self acceptClientConnet];
    }
    
    
}


#pragma mark - 接受客户端的链接

- (void)acceptClientConnet{
    
    // 阻塞线程
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        struct sockaddr_in client_address;
        socklen_t address_len;
        // accept函数
        int client_socket = accept(self.serverId, (struct sockaddr *)&client_address, &address_len);
        self.client_socket = client_socket;
        
        if (client_socket == -1) {
            NSLog(@"接受 %u 客户端错误",address_len);
            
        }else{
            NSString *acceptInfo = [NSString stringWithFormat:@"客户端 in,socket:%d",client_socket];
            NSLog(@"%@",acceptInfo);
            [self receiveMsgWithClietnSocket:client_socket];
        }
        
    });
    
}

- (void)receiveMsgWithClietnSocket:(int)clientSocket{
    while (1) {
        // 5: 接受客户端传来的数据
        char buf[1024] = {0};
        long iReturn = recv(clientSocket, buf, 1024, 0);
        if (iReturn>0) {
            // 接收到的数据转换
            NSData *recvData  = [NSData dataWithBytes:buf length:iReturn];
            NSString *recvStr = [[NSString alloc] initWithData:recvData encoding:NSUTF8StringEncoding];
            NSLog(@"======接受到客户端消息:%@",recvStr);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                MsgModel*model = [[MsgModel alloc]init];
                model.msg = recvStr;
                model.isSend = NO;
                [self.dataArrM addObject:model];
                
                [self.tableView reloadData];
                
            });
            
            
        }else if (iReturn == -1){
            NSLog(@"====== 读取消息失败 =====");
            break;
        }else if (iReturn == 0){
            NSLog(@"====== 客户端断开连接了 ======");
            
            close(clientSocket);
            
            break;
        }
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];


    self.dataArrM = [NSMutableArray array];
}

#pragma mark --发送消息
- (IBAction)sendMsg:(UIButton *)sender {
    
    
    if (self.textTF.text.length == 0) {
        NSLog(@"====== 消息为空 ======");
        return;
    }
    const char *msg = self.textTF.text.UTF8String;
    
    ssize_t sendlength = send(self.client_socket, msg, strlen(msg), 0);
    NSLog(@"====== 发送字节数:%ld",sendlength);
    
    MsgModel*model = [[MsgModel alloc]init];
    model.msg = self.textTF.text;
    model.isSend = YES;
    [self.dataArrM addObject:model];
    
    [self.tableView reloadData];
    
    self.textTF.text = @"";
    
}


#pragma mark --断开连接:关闭socket连接
- (IBAction)closeConnet:(UIBarButtonItem *)sender {
    
    int close_result = close(self.client_socket);
    
    if (close_result == -1) {
        NSLog(@"====== socket关闭失败 ======");
        return;
    }else{
        NSLog(@"====== socket关闭成功 ======");
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
