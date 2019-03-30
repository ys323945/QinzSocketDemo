//
//  MsgModel.h
//  QinzSocket
//
//  Created by Qinz on 2019/3/29.
//  Copyright © 2019 Qinz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MsgModel : NSObject

@property (nonatomic, copy) NSString *msg;
@property (nonatomic, assign) BOOL isSend;

@end

NS_ASSUME_NONNULL_END
