//
//  ViewController.m
//  IT07FMDBQueueDemo
//
//  Created by student on 16/6/24.
//  Copyright © 2016年 zxh. All rights reserved.
//

#import "ViewController.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
@interface ViewController ()
@property (strong, nonatomic) FMDatabaseQueue *queue;
@property (strong, nonatomic) FMDatabase *dataBase;
@property (strong, nonatomic) NSLock *lock;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createBtn];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.lock = [[NSLock alloc]init];
    
    self.dataBase = [FMDatabase databaseWithPath:[self getDataPath:@"data.sqlite"]];
    
    [self.dataBase open];
    
    BOOL created = [self.dataBase executeUpdate:@"CREATE TABLE IF NOT EXISTS stu (id integer PRIMARY KEY AUTOINCREMENT,name text,age integer)"];
    if (created) {
        NSLog(@"创建成功");
    }else{
        NSLog(@"error");
    }
    
    self.queue = [FMDatabaseQueue databaseQueueWithPath:[self getDataPath:@"queue.sqlite"]];
    
    [self.queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS stu (id integer PRIMARY KEY AUTOINCREMENT,name text,age integer)"];
    }];
}

-(NSString *)getDataPath:(NSString *)str{
    NSString *path = NSHomeDirectory();
    NSString *pathDoc = [path stringByAppendingPathComponent:@"Documents"];
    NSString *strPath = [pathDoc stringByAppendingPathComponent:str];
    NSLog(@"路径是%@",strPath);
    
    return strPath;
}

-(void)createBtn{
    for (NSInteger i=0; i<9; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(50 + i%3*(100+20), 50 + i/3*(100+20), 100, 100);
        btn.backgroundColor = [UIColor colorWithRed:arc4random()%256/255.0 green:arc4random()%256/255.0 blue:arc4random()%256/255.0 alpha:1];
        [btn setTitle:[NSString stringWithFormat:@"%ld",i+1] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = i;
        [self.view addSubview:btn];
    }

}

- (void)insertDBWithQueue:(FMDatabase *)db {
    
    NSString   *name = [NSString stringWithFormat:@"name%d",arc4random()%100];
    NSString    *age = [NSString stringWithFormat:@"%d",arc4random()%100];
    
    [db executeUpdate:@"INSERT INTO stu (name,age) values (?,?)",name,age];
    
    
}

-(void)testOne{
//    获取了一个并行队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_t group = dispatch_group_create();
    
    for (NSInteger i=0; i<100; i++) {
        dispatch_group_async(group, queue, ^{
            dispatch_group_enter(group);
            [self insertDataToBase];
            dispatch_group_leave(group);
        });
    }

//    dispatch_group_async(group, queue, ^{
//        dispatch_group_enter(group);
//        [self insertDataToBase];
//        dispatch_group_leave(group);
//    });

//    组队列完成后的通知
    dispatch_group_notify(group, queue, ^{
        NSLog(@"组队列完成");
    });
}

-(void)testTwo{
[self.queue inDatabase:^(FMDatabase *db) {
    [db executeUpdate:@""];
}];
}

-(void)testThree{
    for (NSInteger i=0; i<100; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.queue inDatabase:^(FMDatabase *db) {
                [self insertDataToBase];
            }];
        });
    }
}

-(void)testFour{
    NSDate *startDate = [NSDate date];
    /**
     *  事务操作
     *
     *  @param db       数据库
     *  @param rollback 回滚参数
     *
     *  @return <#return value description#>
     */
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
//        回滚
        for (NSInteger i=0; i<10000; i++) {
            [self insertDBWithQueue:db];
        }
        
    }];
    NSDate *endDate = [NSDate date];
    NSTimeInterval time = [endDate timeIntervalSinceDate:startDate];
    NSLog(@"时间间隔是%f",time);
}

-(void)testFive{
NSDate *startDate = [NSDate date];
    for (NSInteger i=0; i<100; i++) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                for (NSInteger j=0; j<1000; j++) {
                    [self insertDBWithQueue:db];
                }
            }];

        });
    }
    NSDate *endDate = [NSDate date];
    NSTimeInterval time = [endDate timeIntervalSinceDate:startDate];
    NSLog(@"时间间隔是%f",time);

}

-(void)btnClicked:(UIButton *)sender{
    switch (sender.tag) {
        case 0:
        {
            [self testOne];
            break;
        }
        case 1:
        {
             [self testTwo];
            break;
        }
        case 2:
        {
            [self testThree];
            break;
        }
        case 3:
        {
            [self testFour];
            break;
        }
        case 4:
        {
            [self testFive];
            break;
        }
        case 5:
        {
            break;
        }
        case 6:
        {
            break;
        }
        case 7:
        {
            break;
        }
        case 8:
        {
            break;
        }
    }
}

#pragma mark- 插入数据到数据库
-(void)insertDataToBase{
    
    [self.lock lock];
    
    [self.dataBase open];
    
    NSString *name = [NSString stringWithFormat:@"name%d",arc4random()%100];
    
    NSString *age =[NSString stringWithFormat:@"%d",arc4random()%250];
    
    [self.dataBase executeUpdate:@"insert into stu(name,age) values(?,?)",name,age];
    
    [self.dataBase close];
    
    [self.lock unlock];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
