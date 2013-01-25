//
//  PHReward.h
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 7/11/11.
//  Copyright 2011 Playhaven. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * @internal
 *
 * @brief Class that contains information about an unlocked reward.
 **/
// TODO: Move validation methods from PHPublisherContentRequest to here
@interface PHReward : NSObject {
    NSString *_reward;
    NSInteger _quantity;
    NSString *_receipt;
}

@property (nonatomic, copy)   NSString *name;     /**< Reward name, this is a string value that is configured on the publisher Dashboard
                                                       and should correspond to unlockables recognized by the publisher's game */
@property (nonatomic, assign) NSInteger quantity; /**< Quantity of the reward to unlock */
@property (nonatomic, copy)   NSString *receipt;  /**< Unique receipt value, used for reward validation in the SDK */
@end
