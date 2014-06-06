//
//  User.m
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-6.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import "User.h"
#import <sqlite3.h>
#import "ASIFormDataRequest.h"
#import "PublicDefinition.h"
#import "SBJSON.h"
#import "AppDelegate.h"

static User *user = nil;
static NSArray *_subscriptionListData;
static NSMutableDictionary *_runtimeData;
static BOOL _isNeedToRefreshSubscription;
static BOOL _isNeedToSubscribe;
static BOOL _isInit;
static NSString *uid;

@implementation User

+ (User *)sharedUser
{
    @synchronized(self) {
        if (user == nil) {
            [[self alloc] init];
            NSLog(@"user alloc");
        }
    }
    return user;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (user == nil) {
            user = [super allocWithZone:zone];  //确保使用同一块内存地址
            return user;
        }
    }
    return nil;
}

+ (NSString *)getUid
{
    return uid;
}

- (id)init
{
    [super init];
    _runtimeData = [[NSMutableDictionary alloc] init];
    _isNeedToRefreshSubscription = NO;
    _isNeedToSubscribe = YES;
    _isInit = YES;
    uid = [[NSString alloc] initWithString:[[NSUserDefaults standardUserDefaults] objectForKey:UID]];
    
    //获取我的订阅
    [self getMySubscription];
    
    //数据库初始化
    sqlite3 *database;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSLog(@"paths: %@", [paths objectAtIndex:0]);
    NSString *documents = [paths objectAtIndex:0];
    NSString *databasePath = [documents stringByAppendingPathComponent:@"/CloudMessageDB.sqlite"];

    if (sqlite3_open([databasePath UTF8String], &database) != SQLITE_OK) {
        sqlite3_close(database);
        NSLog(@"打开数据库失败！");
    } else {
        //建表
        char *err;
        NSString *sqlCreateTable1 = [[NSString alloc] initWithFormat:@"CREATE TABLE IF NOT EXISTS MESSAGEINFO_%@ (sn INTEGER, mid TEXT PRIMARY KEY, rid TEXT, title TEXT, include_time TEXT, abstract TEXT, read_flag BOOLEAN)", uid];
        NSLog(@"\n%@\n", sqlCreateTable1);
        if (sqlite3_exec(database, [sqlCreateTable1 UTF8String], NULL, NULL, &err) != SQLITE_OK) {
            NSLog(@"创建消息信息表失败！");
        } else {
            NSLog(@"创建消息信息表成功！");
        }
        NSString *sqlCreateTable2 = [[NSString alloc] initWithFormat:@"CREATE TABLE IF NOT EXISTS MESSAGE_%@ (mid TEXT PRIMARY KEY, message BLOB)", uid];
        if (sqlite3_exec(database, [sqlCreateTable2 UTF8String], NULL, NULL, &err) != SQLITE_OK) {
            NSLog(@"创建消息内容表失败！");
        } else {
            NSLog(@"创建消息内容表成功！");
        }
        sqlite3_close(database);
    }
    
    return self;
}

- (void)getMySubscription
{
    NSLog(@"获取我的订阅！");
    //    [SVProgressHUD show];
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://59.77.134.226:80/mobile_get_resource_list_by_uid"]];
    
    [request setRequestMethod:@"POST"];
    NSString *postBody = @"{\"uid\":\"myUid\"}";
 
    postBody = [postBody stringByReplacingOccurrencesOfString:@"myUid" withString:[[NSUserDefaults standardUserDefaults] objectForKey:UID]];
    NSLog(@"postBody: %@", postBody);
    [request setPostBody:(NSMutableData *)[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    request.delegate = self;
    [request startSynchronous];     //阻塞式
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate

- (void)requestStarted:(ASIHTTPRequest *)request
{
    NSLog(@"请求开始了");
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSLog(@"请求结束了");
    
    NSString *str = request.responseString;
    if ([str length] == 0) {
        NSLog(@"str为空！");
    }
    //NSLog(@"str is ---> %@",str);
    
    SBJSON *json = [[SBJSON alloc] init];
    NSDictionary *dic = [json objectWithString:str];
//    NSLog(@"dic = %@",dic);
    NSString *code = [dic objectForKey:@"code"];
    NSString *msg = [dic objectForKey:@"msg"];
    NSLog(@"code: %@", code);
    if ([code intValue] == 0) {
        if ([dic objectForKey:@"data"] != nil) {
            
            NSMutableArray *mySubscriptionData = [[NSMutableArray alloc] initWithArray:(NSMutableArray *)[dic objectForKey:@"data"]];
//            NSLog(@"\nUser sub: %@\n", mySubscriptionData);
            
            //订阅信息保存到内存
            [_runtimeData setObject:mySubscriptionData forKey:MY_SUBSCRIPTION];
            //启动时向推送服务器订阅
            if (_isInit == YES) {
                _isInit = NO;
                AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                MosquittoClient *mosq = [app mosquittoClient];
                
                [mosq setHost:@"59.77.134.227"];
                [mosq connect];
                
                for (NSDictionary *obj in mySubscriptionData) {
                    //订阅，最高质量qos2
                    [mosq subscribe:[obj objectForKey:@"_id"] withQos:2];
//                    [mosq subscribe:[obj objectForKey:@"_id"]];
//                    NSLog(@"\nmosq 订阅: %@", [obj objectForKey:@"_id"]);
                }
            }
        }
    } else {
        NSLog(@"msg: %@", msg);
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    
    NSLog(@"请求失败了");
//    NSLog([[request error] localizedDescription]);
}


- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain
{
    return self;
}

- (unsigned)retainCount
{
    return UINT_MAX;
}

- (id)autorelease
{
    return self;
}

-(oneway void)release
{
    
}

+ (NSArray *)subscriptionListData
{
    return _subscriptionListData;
}

+ (void)setSubscriptionLIstData:(NSArray *)data
{
    _subscriptionListData = data;
}

+ (NSDictionary *)runtimeData
{
    return _runtimeData;
}

+ (void)setRuntimeData:(id)data forKey:(NSString *)key
{
    [_runtimeData setObject:data forKey:key];
}

+ (BOOL)isNeedToRefreshSubscription
{
    return _isNeedToRefreshSubscription;
}

+ (void)setSubscriptionRefresh:(BOOL)refresh
{
    _isNeedToRefreshSubscription = refresh;
}

+ (void)insertMessageInfoBySn:(NSInteger)sn message:(NSDictionary *)message
{
    //数据写入数据库
    sqlite3 *database;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [paths objectAtIndex:0];
    NSString *databasePath = [documents stringByAppendingPathComponent:@"/CloudMessageDB.sqlite"];
    if (sqlite3_open([databasePath UTF8String], &database) != SQLITE_OK) {
        NSLog(@"打开数据库失败！");
    } else {
        //MESSAGEINFO (sn INTEGER PRIMARY KEY, mid TEXT, rid TEXT, title TEXT, include_time, TEXT, abstract TEXT, read_flag BOOLEAN)
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO MESSAGEINFO_%@ VALUES('sn', 'mid', 'rid', 'title', 'include_time', 'abstract', 'read_flag')", uid];
        sql = [sql stringByReplacingOccurrencesOfString:@"sn" withString:[NSString stringWithFormat:@"%d", sn]];
        sql = [sql stringByReplacingOccurrencesOfString:@"mid" withString:[message objectForKey:@"mid"]];
        sql = [sql stringByReplacingOccurrencesOfString:@"rid" withString:[message objectForKey:@"rid"]];
        sql = [sql stringByReplacingOccurrencesOfString:@"title" withString:[message objectForKey:@"title"]];
        sql = [sql stringByReplacingOccurrencesOfString:@"include_time" withString:[message objectForKey:@"include_time"]];
        //sql = [sql stringByReplacingOccurrencesOfString:@"abstract" withString:[message objectForKey:@"abstract"]];
        NSString *abstract = [NSString stringWithString:[message objectForKey:@"include_time"]];
        //将字符“'"去除，防止数据库错误
        abstract = [abstract stringByReplacingOccurrencesOfString:@"'" withString:@""];
        sql = [sql stringByReplacingOccurrencesOfString:@"abstract" withString:abstract];
        sql = [sql stringByReplacingOccurrencesOfString:@"read_flag" withString:[message objectForKey:@"read_flag"]];

        char *err;
        if (sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"数据库错误" message:@"insertMessageInfo" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [alertView show];
            NSLog(@"\n插入数据失败！\nsql: %@\n", sql);
            NSString *errStr = [[NSString alloc] initWithUTF8String:err];
            NSLog(@"Err: %@", errStr);
        } else {
            NSLog(@"\n插入数据成功\n");
        }
    }
    sqlite3_close(database);
}

+ (NSMutableArray *)getMessageInfoByLimit:(NSInteger)limit offset:(NSInteger)offset
{
    NSMutableArray *data = [[NSMutableArray alloc] init];
    sqlite3 *database;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [paths objectAtIndex:0];
    NSString *databasePath = [documents stringByAppendingPathComponent:@"/CloudMessageDB.sqlite"];
    if (sqlite3_open([databasePath UTF8String], &database) != SQLITE_OK) {
        NSLog(@"打开数据库失败！");
    } else {
//        NSString *sqlQuery = @"SELECT * FROM MESSAGEINFO WHERE sn >= startSn AND sn <= endSn ORDER BY sn DESC";
        NSString *sqlQuery = [[NSString alloc] initWithFormat:@"SELECT * FROM MESSAGEINFO_%@ ORDER BY include_time LIMIT startSn OFFSET endSn", uid];
        sqlQuery = [sqlQuery stringByReplacingOccurrencesOfString:@"startSn" withString:[NSString stringWithFormat:@"%d", limit]];
        sqlQuery = [sqlQuery stringByReplacingOccurrencesOfString:@"endSn" withString:[NSString stringWithFormat:@"%d", offset]];
        NSLog(@"\nsqlQuery: %@\n", sqlQuery);
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                //MESSAGEINFO (sn INTEGER PRIMARY KEY, mid TEXT, rid TEXT, title TEXT, include_time, TEXT, abstract TEXT, read_flag BOOLEAN)
                char *sn = (char *)sqlite3_column_text(statement, 0);
                NSString *snStr = [[NSString alloc] initWithUTF8String:sn];
                char *mid = (char *)sqlite3_column_text(statement, 1);
                NSString *midStr = [[NSString alloc] initWithUTF8String:mid];
                char *rid = (char *)sqlite3_column_text(statement, 2);
                NSString *ridStr = [[NSString alloc] initWithUTF8String:rid];
                char *title = (char *)sqlite3_column_text(statement, 3);
                NSString *titleStr = [[NSString alloc] initWithUTF8String:title];
                char *includeTime = (char *)sqlite3_column_text(statement, 4);
                NSString *includeTimeStr = [[NSString alloc] initWithUTF8String:includeTime];
                char *abstract = (char *)sqlite3_column_text(statement, 5);
                NSString *abstractStr = [[NSString alloc] initWithUTF8String:abstract];
                char *readFlag = (char *)sqlite3_column_text(statement, 6);
                NSString *readFlagStr = [[NSString alloc] initWithUTF8String:readFlag];
                
//                NSLog(@"\nGet Message Info:\nsn: %@\nmid: %@\nrid: %@\ntitle: %@\ninclude_time: %@\nabstract: %@\nreadFlag: %@\n", snStr, midStr, ridStr, titleStr, includeTimeStr, abstractStr, readFlagStr);
                NSDictionary *dic = [[NSDictionary alloc] initWithObjects:@[midStr, ridStr, titleStr, includeTimeStr, abstractStr, readFlagStr] forKeys:@[@"mid", @"rid", @"title", @"include_time", @"abstract", @"read_flag"]];
                [data addObject:dic];
            }
        }
    }
    sqlite3_close(database);
    return data;
}

+ (void)insertMessageContent:(NSDictionary *)data
{
    //数据写入数据库
    sqlite3 *database;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [paths objectAtIndex:0];
    NSString *databasePath = [documents stringByAppendingPathComponent:@"/CloudMessageDB.sqlite"];
    if (sqlite3_open([databasePath UTF8String], &database) != SQLITE_OK) {
        NSLog(@"打开数据库失败！");
    } else {
        NSMutableData *blobData = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:blobData];
        [archiver encodeObject:data forKey:@"data"];
        [archiver finishEncoding];

        //MESSAGE (mid TEXT PRIMARY KEY, message BLOB)
        NSString *sql = [[NSString alloc] initWithFormat:@"INSERT INTO MESSAGE_%@ VALUES('myMid', ?)", uid];
        sql = [sql stringByReplacingOccurrencesOfString:@"myMid" withString:[data objectForKey:@"_id"]];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_blob(statement, 1, [blobData bytes], [blobData length], SQLITE_TRANSIENT);
            if (sqlite3_step(statement) == SQLITE_DONE) {
                NSLog(@"\n保存消息内容到数据库\n");
            }
        } else {
            NSLog(@"\nSave blob error: %s\n", sqlite3_errmsg(database));
        }
        [archiver release];
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
}

+ (NSDictionary *)getMessageContentByMid:(NSString *)mid
{
    NSDictionary *dic = nil;
    sqlite3 *database;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [paths objectAtIndex:0];
    NSString *databasePath = [documents stringByAppendingPathComponent:@"/CloudMessageDB.sqlite"];
    if (sqlite3_open([databasePath UTF8String], &database) != SQLITE_OK) {
        NSLog(@"打开数据库失败！");
    } else {
        NSData *data = nil;
        NSString *sqlQuery = [NSString stringWithFormat:@"SELECT message FROM MESSAGE_%@ WHERE mid = '%@'", uid, mid];
        NSLog(@"\nGet Message Content:\n%@\n", sqlQuery);
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, [sqlQuery UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                int length = sqlite3_column_bytes(statement, 0);
                data = [NSData dataWithBytes:sqlite3_column_blob(statement, 0) length:length];
                NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
                dic = [[unarchiver decodeObjectForKey:@"data"] retain];
//                NSLog(@"\ndic: %@\n", dic);
                [unarchiver finishDecoding];
                [unarchiver release];
            }
        } else {
            NSLog(@"\nGet blob error: %s\n", sqlite3_errmsg(database));
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    return dic;
}

+ (void)deleteMessageByMid:(NSString *)mid
{
    sqlite3 *database;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [paths objectAtIndex:0];
    NSString *databasePath = [documents stringByAppendingPathComponent:@"/CloudMessageDB.sqlite"];
    if (sqlite3_open([databasePath UTF8String], &database) != SQLITE_OK) {
        NSLog(@"打开数据库失败！");
    } else {
        NSString *sqlQuery = [NSString stringWithFormat:@"DELETE FROM MESSAGEINFO_%@ WHERE mid = '%@'", uid, mid];
        
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, [sqlQuery UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_DONE) {
                NSLog(@"\n删除消息简介成功\n");
                //更新sn
//                sqlQuery = [NSString stringWithFormat:@"UPDATE MESSAGEINFO_%@ SET sn = sn - 1 WHERE sn > '%d'", uid, sn];
//                NSLog(@"\n更新sn sql：%@\n", sqlQuery);
//                if (sqlite3_prepare_v2(database, [sqlQuery UTF8String], -1, &statement, NULL) == SQLITE_OK) {
//                    if (sqlite3_step(statement) == SQLITE_DONE) {
//                        NSLog(@"\n更新sn成功\n");
//                    }
//                }
            }

        } else {
            NSLog(@"\nDelete messageinfo error: %s\n", sqlite3_errmsg(database));
        }
        sqlQuery = [NSString stringWithFormat:@"DELETE FROM MESSAGE_%@ WHERE mid = '%@'", uid, mid];
        
        if (sqlite3_prepare_v2(database, [sqlQuery UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_DONE) {
                NSLog(@"\n删除消息内容成功\n");
                //更新rowid
//                sqlQuery = [NSString stringWithFormat:@"UPDATE MESSAGE SET rowid = rowid - 1 WHERE rowid > %d", sn];
//                if (sqlite3_prepare_v2(database, [sqlQuery UTF8String], -1, &statement, NULL) == SQLITE_OK) {
//                    if (sqlite3_step(statement) == SQLITE_DONE) {
//                        NSLog(@"\n更新rowid成功\n");
//                    }
//                }
            }
            
        } else {
            NSLog(@"\nDelete message error: %s\n", sqlite3_errmsg(database));
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
}


+ (void)updateMessageContentByMid:(NSString *) mid forField:(NSString *)field withValue:(NSString *)value
{
    sqlite3 *database;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [paths objectAtIndex:0];
    NSString *databasePath = [documents stringByAppendingPathComponent:@"/CloudMessageDB.sqlite"];
    if (sqlite3_open([databasePath UTF8String], &database) != SQLITE_OK) {
        NSLog(@"打开数据库失败！");
    } else {
        //MESSAGEINFO (sn INTEGER PRIMARY KEY, mid TEXT, rid TEXT, title TEXT, include_time, TEXT, abstract TEXT, read_flag BOOLEAN)
        NSString *sql = [NSString stringWithFormat:@"UPDATE MESSAGEINFO_%@ SET field = 'myValue' WHERE mid = 'myMid'", uid];
        sql = [sql stringByReplacingOccurrencesOfString:@"field" withString:field];
        sql = [sql stringByReplacingOccurrencesOfString:@"myValue" withString:value];
        sql = [sql stringByReplacingOccurrencesOfString:@"myMid" withString:mid];
        
        char *err;
        if (sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
            NSLog(@"\nUpdate error！\nsql: %@\n", sql);
            NSString *errStr = [[NSString alloc] initWithUTF8String:err];
            NSLog(@"Err: %@", errStr);
        } else {
            NSLog(@"\n修改数据成功\n");
        }
    }
    sqlite3_close(database);
}

+ (void)emptyDataBase
{
    sqlite3 *database;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [paths objectAtIndex:0];
    NSString *databasePath = [documents stringByAppendingPathComponent:@"/CloudMessageDB.sqlite"];
    if (sqlite3_open([databasePath UTF8String], &database) != SQLITE_OK) {
        NSLog(@"打开数据库失败！");
    } else {
        char *err;
        NSString *sql = [[NSString alloc] initWithFormat:@"DELETE FROM MESSAGEINFO_%@", uid];
        if (sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
            NSString *errStr = [[NSString alloc] initWithUTF8String:err];
            NSLog(@"Err: %@", errStr);
        } else {
            NSLog(@"\n清除MESSAGEINFO数据\n");
        }
        NSString *sql1 = [[NSString alloc] initWithFormat:@"DELETE FROM MESSAGE_%@", uid];
        if (sqlite3_exec(database, [sql1 UTF8String], NULL, NULL, &err) != SQLITE_OK) {
            NSString *errStr = [[NSString alloc] initWithUTF8String:err];
            NSLog(@"Err: %@", errStr);
        } else {
            NSLog(@"\n清除MESSAGE数据\n");
        }
    }
    sqlite3_close(database);
}

+ (NSArray *)getMessageCount
{
    sqlite3 *database;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [paths objectAtIndex:0];
    NSString *databasePath = [documents stringByAppendingPathComponent:@"/CloudMessageDB.sqlite"];
    NSInteger messageCount = 0;
    NSInteger unreadCount = 0;
    
    if (sqlite3_open([databasePath UTF8String], &database) != SQLITE_OK) {
        NSLog(@"打开数据库失败！");
    } else {
        char *err;
        //获取消息数
        NSString *sql = [[NSString alloc] initWithFormat:@"SELECT COUNT (*) FROM MESSAGEINFO_%@", uid];
        NSLog(@"\nUser MessageInfoCount sql: %@\n", sql);
        sqlite3_stmt *statement = NULL;
        if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, &err) != SQLITE_OK) {
            NSString *errStr = [[NSString alloc] initWithUTF8String:err];
            NSLog(@"Err: %@", errStr);
        } else {
            //Loop through all the returned rows (should be just one)
            while( sqlite3_step(statement) == SQLITE_ROW )
            {
                messageCount = sqlite3_column_int(statement, 0);
            }
            NSLog(@"\n[User]Message count: %d\n", messageCount);
        }
        //获取未读数
        sql = [[NSString alloc] initWithFormat:@"SELECT COUNT (*) FROM MESSAGEINFO_%@ WHERE read_flag = 'false'", uid];
        NSLog(@"\nUser UnreadCount sql: %@\n", sql);
        statement = NULL;
        if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, &err) != SQLITE_OK) {
            NSString *errStr = [[NSString alloc] initWithUTF8String:err];
            NSLog(@"Err: %@", errStr);
        } else {
            //Loop through all the returned rows (should be just one)
            while( sqlite3_step(statement) == SQLITE_ROW )
            {
                unreadCount = sqlite3_column_int(statement, 0);
            }
            NSLog(@"\n[User]Unread count: %d\n", unreadCount);
        }
    }
    sqlite3_close(database);
    NSArray *array = [[NSArray alloc] initWithObjects:[NSNumber numberWithInteger:messageCount], [NSNumber numberWithInteger:unreadCount], nil];
    return array;
}

@end
