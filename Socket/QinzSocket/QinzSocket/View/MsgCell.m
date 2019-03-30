//
//  MsgCell.m
//  QinzSocket
//
//  Created by Qinz on 2019/3/29.
//  Copyright © 2019 Qinz. All rights reserved.
//

#import "MsgCell.h"

@interface MsgCell()


@property (weak, nonatomic) IBOutlet UILabel *msgLB;

@end

@implementation MsgCell


-(void)setModel:(MsgModel *)model{
    
    _model = model;
    
    if (model.isSend) {
        self.msgLB.textAlignment = NSTextAlignmentRight;
        self.msgLB.textColor = [UIColor redColor];
    }else{
        self.msgLB.textAlignment = NSTextAlignmentLeft;
        self.msgLB.textColor = [UIColor grayColor];

    }
    
    self.msgLB.text = model.msg;
    
}

- (void)awakeFromNib {
    [super awakeFromNib];


}



@end
