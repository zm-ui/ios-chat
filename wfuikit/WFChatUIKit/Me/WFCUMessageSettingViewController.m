//
//  MessageNotificationViewController.m
//  WildFireChat
//
//  Created by heavyrain lee on 07/01/2018.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "WFCUMessageSettingViewController.h"
#import "WFCUSwitchTableViewCell.h"
#import "UIColor+YH.h"
#import "WFCUGeneralSwitchTableViewCell.h"
#import "WFCUSelectNoDisturbingTimeViewController.h"
#ifdef WFC_PTT
#import <PttClient/WFPttClient.h>
#endif
#import "WFCUConfigManager.h"


@interface WFCUMessageSettingViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;

@property(nonatomic, assign)BOOL isNoDisturb;
@property(nonatomic, assign)int startMins;
@property(nonatomic, assign)int endMins;
@end

@implementation WFCUMessageSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = WFCString(@"NewMessageNotification");
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    
    NSInteger interval = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:[NSDate date]];
    
    self.startMins = 21 * 60 - interval/60; //本地21:00
    self.endMins = 7 * 60 - interval/60;  //本地7:00
    if (self.endMins < 0) {
        self.endMins += 24 * 60;
    }
    
    [[WFCCIMService sharedWFCIMService] getNoDisturbingTimes:^(int startMins, int endMins) {
        self.startMins = startMins;
        self.endMins = endMins;
        self.isNoDisturb = YES;
    } error:^(int error_code) {
        self.isNoDisturb = NO;
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0.1;
    } else {
        return 9;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    } else {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 9)];
        view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        return view;

    }
}

//#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int count = 4;
    if([[WFCCIMService sharedWFCIMService] isCommercialServer] && ![[WFCCIMService sharedWFCIMService] isGlobalDisableSyncDraft]) {
        count ++;
    }
#ifdef WFC_PTT
    count ++;
#endif
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 1;
    } else if (section == 2) {
        return 1;
    } else if (section == 3) {
        if (self.isNoDisturb) {
            return 2;
        }
        return 1;
    } else if(section == 4) {
        if([[WFCCIMService sharedWFCIMService] isCommercialServer] && ![[WFCCIMService sharedWFCIMService] isGlobalDisableSyncDraft]) {
            return 1;
            //草稿
        } else {
            //Ptt
#ifdef WFC_PTT
            if([WFPttClient sharedClient].enablePtt) {
                return 2;
            }
            return 1;
#endif
        }
        return 1;
    } else if(section == 5) {
        //Ptt
#ifdef WFC_PTT
        if([WFPttClient sharedClient].enablePtt) {
            return 2;
        }
        return 1;
#endif
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3) {
        if (indexPath.row == 0) {
            WFCUGeneralSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch"];
            if(cell == nil) {
                cell = [[WFCUGeneralSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"switch"];
            }
            cell.detailTextLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = WFCString(@"NoDisturb");
            cell.on = self.isNoDisturb;
            __weak typeof(self)ws = self;
            cell.onSwitch = ^(BOOL value, int type, void (^handleBlock)(BOOL success)) {
                if (value) {
                    [[WFCCIMService sharedWFCIMService] setNoDisturbingTimes:ws.startMins endMins:ws.endMins success:^{
                        ws.isNoDisturb = YES;
                        [ws.tableView reloadData];
                        handleBlock(YES);
                    } error:^(int error_code) {
                        handleBlock(NO);
                    }];
                } else {
                    [[WFCCIMService sharedWFCIMService] clearNoDisturbingTimes:^{
                        ws.isNoDisturb = NO;
                        [ws.tableView reloadData];
                        handleBlock(YES);
                    } error:^(int error_code) {
                        handleBlock(NO);
                    }];
                }
            };
            return cell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
            }
            cell.textLabel.text = WFCString(@"SilentPeriods");
            NSInteger interval = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:[NSDate date]];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%02d:%02d-%02d:%02d", (self.startMins/60+(int)interval/3600)%24, self.startMins%60, (self.endMins/60+(int)interval/3600)%24, self.endMins%60];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
    }
    WFCUSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"styleSwitch"];
    if(cell == nil) {
        cell = [[WFCUSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"styleSwitch" conversation:nil];
    }
    cell.detailTextLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.section == 0) {
        cell.textLabel.text = WFCString(@"ReceiveNewMessageNotification");
        cell.type = SwitchType_Setting_Global_Silent;
    } else if(indexPath.section == 1) {
        cell.textLabel.text = WFCString(@"ReceiveVoipNotification");
        cell.type = SwitchType_Setting_Voip_Silent;
    } else if(indexPath.section == 2) {
        cell.textLabel.text = WFCString(@"NotificationShowMessageDetail");
        cell.type = SwitchType_Setting_Show_Notification_Detail;
    } else if(indexPath.section == 4 || indexPath.section == 5) {
        if(indexPath.section == 4 && [[WFCCIMService sharedWFCIMService] isCommercialServer] && ![[WFCCIMService sharedWFCIMService] isGlobalDisableSyncDraft]) {
            cell.textLabel.text = WFCString(@"SyncDraft");
            cell.type = SwitchType_Setting_Sync_Draft;
        } else {
#ifdef WFC_PTT
            WFCUGeneralSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch2"];
            if(cell == nil) {
                cell = [[WFCUGeneralSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"switch2"];
            }
            cell.detailTextLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            if(indexPath.row == 0) {
                cell.textLabel.text = @"开启对讲功能";
                cell.on = [WFPttClient sharedClient].enablePtt;
                __weak typeof(self)ws = self;
                cell.onSwitch = ^(BOOL value, int type, void (^handleBlock)(BOOL success)) {
                    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"WFC_PTT_ENABLED"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [WFPttClient sharedClient].enablePtt = value;
                    [ws.tableView reloadData];
                };
            } else {
                cell.textLabel.text = @"对讲保持后台激活";
                cell.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"WFC_PTT_BACKGROUND_KEEPALIVE"];
                
                cell.onSwitch = ^(BOOL value, int type, void (^handleBlock)(BOOL success)) {
                    [[NSUserDefaults standardUserDefaults] setBool:value forKey:@"WFC_PTT_BACKGROUND_KEEPALIVE"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [WFPttClient sharedClient].playSilent = @(value);
                };
            }
            return cell;
#endif
        }
        
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3 && indexPath.row == 1) {
        WFCUSelectNoDisturbingTimeViewController *vc = [[WFCUSelectNoDisturbingTimeViewController alloc] init];
        vc.startMins = self.startMins;
        vc.endMins = self.endMins;
        __weak typeof(self)ws = self;
        vc.onSelectTime = ^(int startMins, int endMins) {
            ws.startMins = startMins;
            ws.endMins = endMins;
            
            [[WFCCIMService sharedWFCIMService] setNoDisturbingTimes:ws.startMins endMins:ws.endMins success:^{
                ws.isNoDisturb = YES;
                [ws.tableView reloadData];
            } error:^(int error_code) {
            }];
        };
        [self.navigationController pushViewController:vc animated:YES];
    }
}
@end
