//
//  ViewController.m
//  SemaphoreDemo
//
//  Created by HuangLibo on 2020/3/16.
//  Copyright © 2020 HuangLibo. All rights reserved.
//

#import "ViewController.h"

#define LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define UNLOCK(lock) dispatch_semaphore_signal(lock);

@interface ViewController ()

/// 保持任务有序进行, 使用线性队列
@property (nonatomic, strong) dispatch_queue_t serialQueue;

/// 并行队列
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;

/// 模拟执行耗时任务所需的时间
@property (nonatomic, assign) unsigned int taskTime;

/// 使用 semaphore 来做全局的锁
@property (nonatomic, strong) dispatch_semaphore_t lock;

@end

@implementation ViewController

//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//
//    }
//    return self;
//}

// storyboard 的初始化方法
- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.serialQueue = dispatch_queue_create("HLBSerialQueue", DISPATCH_QUEUE_SERIAL);
//        self.concurrentQueue = dispatch_queue_create("HLBConcurrentQueue", DISPATCH_QUEUE_CONCURRENT);
        self.concurrentQueue = dispatch_get_global_queue(0, 0);
        self.taskTime = 2;

        /* 关于 `dispatch_semaphore_create` 的初值:
         * Passing zero for the value is useful for when two threads need to reconcile
         * the completion of a particular event. Passing a value greater than zero is
         * useful for managing a finite pool of resources, where the pool size is equal
         * to the value.
         */
        self.lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self example_7];
}

/*
 信号量的作用二: 控制资源池的数量.
 特别地, 当信号量的初值设为 1, 其功能类似于为互斥锁.
 */

// 将 `dispatch_semaphore_wait` 和 `dispatch_semaphore_signal` 封装成宏, 以便于调用.
- (void)example_7 {
    dispatch_async(self.serialQueue, ^{
        LOCK(self.lock);
        
        // task, 写入数据等
        // ...
        
        UNLOCK(self.lock)
    });
}

 - (void)example_6_safe {
     dispatch_semaphore_t dsemo = dispatch_semaphore_create(1);
     
     __block NSInteger intA = 0;
     
     dispatch_async(self.concurrentQueue, ^{
         // 相当于加锁
         dispatch_semaphore_wait(dsemo, DISPATCH_TIME_FOREVER);
         
         //thread A
         for (NSInteger i = 0; i < 10000; i ++) {
             intA = intA + 1;
             NSLog(@"Thread A: %zd\n", intA);
         }
           
         //相当于解锁
         dispatch_semaphore_signal(dsemo);
     });
     
     dispatch_async(self.concurrentQueue, ^{
         // 相当于加锁
         dispatch_semaphore_wait(dsemo, DISPATCH_TIME_FOREVER);
         
         //thread B
         for (NSInteger i = 0; i < 10000; i ++) {
             intA = intA + 1;
             NSLog(@"Thread B: %zd\n", intA);
         }
           
         //相当于解锁
         dispatch_semaphore_signal(dsemo);
     });
 }

 - (void)example_6_not_safe {
     __block NSInteger intA = 0;
     
     dispatch_async(self.concurrentQueue, ^{
         //thread A
         for (NSInteger i = 0; i < 10000; i ++) {
             intA = intA + 1;
             NSLog(@"Thread A: %zd\n", intA);
         }
     });
     
     dispatch_async(self.concurrentQueue, ^{
         //thread B
         for (NSInteger i = 0; i < 10000; i ++) {
             intA = intA + 1;
             NSLog(@"Thread B: %zd\n", intA);
         }
     });
 }

- (void)example_5 {
    dispatch_async(self.serialQueue, ^{
        dispatch_semaphore_t dsemo = dispatch_semaphore_create(1);
        // 相当于加锁
        dispatch_semaphore_wait(dsemo, DISPATCH_TIME_FOREVER);
        
        // task, 写入数据等
        // ...
        
        //相当于解锁
        dispatch_semaphore_signal(dsemo);
    });
}

/*
 信号量的作用一: 协调多个线程的合作.
 条件: 需要将信号量初值设置 0
 */

// 循环执行一系列任务, 都完成后再执行后续任务
- (void)example_4 {
    dispatch_async(self.serialQueue, ^{
        dispatch_semaphore_t dsema = dispatch_semaphore_create(0);
        
        for (NSInteger i = 0; i < 3; i++) { // 循环执行一系列任务
            dispatch_async(self.concurrentQueue, ^{
                sleep(self.taskTime);
                dispatch_semaphore_signal(dsema);
            });
            
            dispatch_semaphore_wait(dsema, DISPATCH_TIME_FOREVER);
        }
        
        // 任务全部执行完成, 再执行后续任务
        NSLog(@"%@", dsema);
    });
}

// 执行多个独立的任务, 都完成后再执行后续任务
- (void)example_3 {
    dispatch_async(self.serialQueue, ^{
        dispatch_semaphore_t dsema = dispatch_semaphore_create(0);
        
        dispatch_async(self.concurrentQueue, ^{ // 独立的任务一
            sleep(self.taskTime);
            dispatch_semaphore_signal(dsema);
        });
        
        dispatch_async(self.concurrentQueue, ^{ // 独立的任务二
            sleep(self.taskTime);
            dispatch_semaphore_signal(dsema);
        });
        
        dispatch_semaphore_wait(dsema, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(dsema, DISPATCH_TIME_FOREVER);
        // 两个独立的任务都执行完成后, 再执行后续任务
        NSLog(@"%@", dsema);
    });
}

// 执行单个任务, 完成后再执行后续任务
- (void)example_2 {
    dispatch_async(self.serialQueue, ^{
        dispatch_semaphore_t dsema = dispatch_semaphore_create(0);
        
        dispatch_async(self.concurrentQueue, ^{
            sleep(self.taskTime);
            dispatch_semaphore_signal(dsema);
        });
        
        dispatch_semaphore_wait(dsema, DISPATCH_TIME_FOREVER);
        NSLog(@"%@", dsema);
    });
}

/*
 在主线程使用信号量时要特别小心
 */

// 阻塞了主线程, 但不会造成死锁的例子.
// 但还是要避免阻塞主线程, 以避免影响 UI 的正常展示和交互.
- (void)example_1 {
    dispatch_semaphore_t dsema = dispatch_semaphore_create(0);
    dispatch_async(self.concurrentQueue, ^{ // 异步到子线程
        // 子线程内的任务可以正常执行
        sleep(self.taskTime);
        dispatch_semaphore_signal(dsema); // 调用后, 主线程的阻塞会解除
    });
    // 阻塞主线程
    dispatch_semaphore_wait(dsema, DISPATCH_TIME_FOREVER);
    NSLog(@"%@", dsema);
}

// 死锁的例子 2
- (void)example_0 {
    dispatch_semaphore_t dsema = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_main_queue(), ^{ // 对主线程异步
        // 由于主线程被阻塞, 这里无法执行了
        sleep(self.taskTime);
        dispatch_semaphore_signal(dsema);
    });
    // 阻塞主线程
    dispatch_semaphore_wait(dsema, DISPATCH_TIME_FOREVER);
    NSLog(@"%@", dsema);
}

// 死锁的例子 1
- (void)example_00 {
    dispatch_semaphore_t dsema = dispatch_semaphore_create(0);
    // 直接在主线程执行的任务
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.taskTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 由于主线程被阻塞, 无法执行到这里
        dispatch_semaphore_signal(dsema);
    });
    // 阻塞主线程
    dispatch_semaphore_wait(dsema, DISPATCH_TIME_FOREVER);
    NSLog(@"%@", dsema);
}

@end
