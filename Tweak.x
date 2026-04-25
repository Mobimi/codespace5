#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>

// Khai bao cua so HUD
@interface PerformanceHUDWindow : UIWindow
@property (nonatomic, strong) UILabel *statsLabel;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTime;
@property (nonatomic, assign) NSUInteger count;
@end

@implementation PerformanceHUDWindow
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Ep HUD luon noi tren cung (De len ca game)
        self.windowLevel = UIWindowLevelStatusBar + 100.0;
        self.userInteractionEnabled = NO; // Khong chan thao tac cam ung
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
        self.layer.cornerRadius = 8;
        self.layer.masksToBounds = YES;

        // Thiet lap chu mau Xanh la cay kieu Hacker
        self.statsLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.statsLabel.textColor = [UIColor greenColor];
        self.statsLabel.font = [UIFont boldSystemFontOfSize:12];
        self.statsLabel.textAlignment = NSTextAlignmentCenter;
        self.statsLabel.numberOfLines = 2;
        [self addSubview:self.statsLabel];

        // Vong lap tinh FPS
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)tick:(CADisplayLink *)link {
    if (self.lastTime == 0) {
        self.lastTime = link.timestamp;
        return;
    }
    self.count++;
    NSTimeInterval delta = link.timestamp - self.lastTime;
    if (delta >= 1.0) {
        double fps = self.count / delta;
        self.count = 0;
        self.lastTime = link.timestamp;

        // Doc RAM thuc te dang su dung
        struct mach_task_basic_info info;
        mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
        kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size);
        double ramMB = 0;
        if (kerr == KERN_SUCCESS) {
            ramMB = info.resident_size / 1024.0 / 1024.0;
        }

        self.statsLabel.text = [NSString stringWithFormat:@"FPS: %.1f\nRAM: %.1f MB", fps, ramMB];
    }
}
@end

// ----- MOC HOOK VAO GAME/APP -----
static PerformanceHUDWindow *hudWindow;

%hook UIWindowScene
- (void)_readySceneForConnection {
    %orig; // Cho phep app khoi dong binh thuong
    
    // Chỉ tạo HUD một lần duy nhất khi app bật lên
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // Tao mot khung HUD o goc trai tren cung (Toa do: X=20, Y=40, Rong=100, Cao=40)
            hudWindow = [[PerformanceHUDWindow alloc] initWithFrame:CGRectMake(20, 40, 100, 40)];
            hudWindow.hidden = NO;
        });
    });
}
%end
