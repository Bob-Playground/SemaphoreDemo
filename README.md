# Dispatch Semaphore 在 iOS 开发中的使用

## Dispatch Semaphore 简介

An object that controls access to a resource across multiple execution contexts through use of a **traditional counting semaphore**.

A dispatch semaphore is an efficient implementation of a traditional counting semaphore. *Dispatch semaphores call down to the kernel only when the calling thread needs to be blocked*. If the calling semaphore does not need to block, no kernel call is made.

You increment a semaphore count by calling the `dispatch_semaphore_signal` method, and decrement a semaphore count by calling `dispatch_semaphore_wait` or one of its variants that specifies a timeout.

## Dispatch Semaphore - API

### dispatch_semaphore_t

```objc
typedef NSObject<OS_dispatch_semaphore> *dispatch_semaphore_t;
```

`dispatch_semaphore_t` 是遵守 `OS_dispatch_semaphore` 协议的 `NSObject` 类。所以它做属性时，用 `strong` 修饰。

### Creating a Semaphore：`dispatch_semaphore_create`

```objc
dispatch_semaphore_t dispatch_semaphore_create(long value);
```

*Passing zero* for the value is useful for when two threads need to reconcile the completion of a particular event.

*Passing a value greater than zero* is useful for managing a finite pool of resources, where the pool size is equal to the value.

Warning：

*Calls to `dispatch_semaphore_signal` must be balanced with calls to `dispatch_semaphore_wait`*. Attempting to dispose of a semaphore with a count lower than value causes an EXC_BAD_INSTRUCTION exception.

### Signaling the Semaphore：`dispatch_semaphore_signal`

```objc
long dispatch_semaphore_signal(dispatch_semaphore_t dsema);
```

Increment the counting semaphore. If the previous value was less than zero, this function wakes a thread currently waiting in dispatch_semaphore_wait.

### Blocking on the Semaphore：`dispatch_semaphore_wait`

```objc
long dispatch_semaphore_wait(dispatch_semaphore_t dsema, dispatch_time_t timeout);
```

**timeout**：When to timeout (see `dispatch_time`). The constants `DISPATCH_TIME_NOW` and `DISPATCH_TIME_FOREVER` are available as a convenience.

**Returns** *zero* on success, or *non-zero* if the timeout occurred.

Decrement the counting semaphore. If the *resulting value* is less than zero, this function waits for a signal to occur before returning.

## 使用场景一：初值设置为 0，多线程同步

```objc
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
// ...
```

## 使用场景二：初值设置为 1, 实现锁的功能

```objc
dispatch_semaphore_t dsemo = dispatch_semaphore_create(1);
// 相当于加锁
dispatch_semaphore_wait(dsemo, DISPATCH_TIME_FOREVER);

// task, 写入数据等
// ...

//相当于解锁
dispatch_semaphore_signal(dsemo);
```

也可以将其简单封装一下：

```objc
#define LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define UNLOCK(lock) dispatch_semaphore_signal(lock);
```

然后设置一个属性：

```objc
@property (nonatomic, strong) dispatch_semaphore_t lock;

self.lock = dispatch_semaphore_create(1);
```

调用：

```objc
LOCK(self.lock);

// task, 写入数据等
// ...

UNLOCK(self.lock)
```

## 使用场景三：初值设置为其他正整数，设置资源池的数量

这种场景在 iOS 开发中用的比较少。

## 参考链接

https://developer.apple.com/documentation/dispatch/dispatch_semaphore?language=objc

https://blog.csdn.net/u012380572/article/details/81541954

https://bestswifter.com/ios-lock
