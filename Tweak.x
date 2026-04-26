#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>

// ==========================================
// COMPONENT 1: VẼ VÒNG TRÒN DÀNH CHO CPU & RAM
// ==========================================
@interface HUDCircleView : UIView
@property (nonatomic, strong) CAShapeLayer *bgLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *valueLabel;
@end

@implementation HUDCircleView
- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat radius = frame.size.width / 2.0 - 4; // Bóp bán kính lại xíu
        CGPoint center = CGPointMake(frame.size.width / 2.0, frame.size.width / 2.0);
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI_2 endAngle:M_PI_2 * 3 clockwise:YES];

        self.bgLayer = [CAShapeLayer layer];
        self.bgLayer.path = circlePath.CGPath;
        self.bgLayer.fillColor = [UIColor clearColor].CGColor;
        self.bgLayer.strokeColor = [UIColor colorWithWhite:0.5 alpha:0.5].CGColor; // Nhạt đi cho đỡ thô
        self.bgLayer.lineWidth = 2.5; // Thanh mảnh
        [self.layer addSublayer:self.bgLayer];

        self.progressLayer = [CAShapeLayer layer];
        self.progressLayer.path = circlePath.CGPath;
        self.progressLayer.fillColor = [UIColor clearColor].CGColor;
        self.progressLayer.strokeColor = [UIColor greenColor].CGColor;
        self.progressLayer.lineWidth = 2.5; // Thanh mảnh
        self.progressLayer.strokeEnd = 0.0; 
        self.progressLayer.lineCap = kCALineCapRound;
        [self.layer addSublayer:self.progressLayer];

        // Tên (CPU/RAM) nằm giữa vòng tròn
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.width)];
        self.titleLabel.text = title;
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:9]; // Hạ cỡ chữ
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.titleLabel];

        // Thông số nằm ngay sát đít vòng tròn
        self.valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(-10, frame.size.width - 2, frame.size.width + 20, 15)];
        self.valueLabel.textColor = [UIColor whiteColor];
        self.valueLabel.font = [UIFont boldSystemFontOfSize:9]; // Hạ cỡ chữ
        self.valueLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.valueLabel];
    }
    return self;
}

- (void)updateWithProgress:(CGFloat)progress valueText:(NSString *)text {
    if (progress > 1.0) progress = 1.0;
    if (progress < 0.0) progress = 0.0;
    self.progressLayer.strokeEnd = progress;
    CGFloat hue = (1.0 - progress) * 0.33; 
    UIColor *dynColor = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
    self.progressLayer.strokeColor = dynColor.CGColor;
    self.valueLabel.text = text;
}
@end

// ==========================================
// COMPONENT 2: BẢNG ĐIỀU KHIỂN CHÍNH & ROOT VC
// ==========================================

@interface HUDRootVC : UIViewController
@end
@implementation HUDRootVC
- (BOOL)prefersStatusBarHidden { return YES; } 

- (UIViewController *)gameRootVC {
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = (UIWindowScene *)self.view.window.windowScene;
        for (UIWindow *w in scene.windows) {
            if (w != self.view.window && w.isKeyWindow && w.rootViewController) {
                return w.rootViewController;
            }
        }
    }
    return nil;
}

- (BOOL)shouldAutorotate { 
    UIViewController *vc = [self gameRootVC];
    return vc ? [vc shouldAutorotate] : YES; 
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { 
    UIViewController *vc = [self gameRootVC];
    return vc ? [vc supportedInterfaceOrientations] : UIInterfaceOrientationMaskAll; 
}
@end

@interface PerformanceHUDWindow : UIWindow
@property (nonatomic, strong) UIView *hudPanel; 
@property (nonatomic, strong) UILabel *fpsTitle;
@property (nonatomic, strong) UILabel *fpsValue;
@property (nonatomic, strong) HUDCircleView *cpuView;
@property (nonatomic, strong) HUDCircleView *ramView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTime;
@property (nonatomic, assign) NSUInteger count;
@end

@implementation PerformanceHUDWindow
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelStatusBar + 100.0;
        self.backgroundColor = [UIColor clearColor]; 
        
        // BẢNG HUD MỚI: XUYÊN THẤU VÀ MI NHON
        self.hudPanel = [[UIView alloc] initWithFrame:CGRectMake(20, 50, 145, 55)]; // Nhỏ lại rõ rệt
        self.hudPanel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4]; // Nền trong suốt 60%
        self.hudPanel.layer.cornerRadius = 12; // Bo tròn sexy
        self.hudPanel.layer.masksToBounds = YES;
        [self addSubview:self.hudPanel];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan]; 

        // CĂN CHỈNH LẠI BỐ CỤC FPS
        self.fpsTitle = [[UILabel alloc] initWithFrame:CGRectMake(5, 8, 45, 15)];
        self.fpsTitle.text = @"FPS";
        self.fpsTitle.textColor = [UIColor lightGrayColor];
        self.fpsTitle.font = [UIFont boldSystemFontOfSize:10];
        self.fpsTitle.textAlignment = NSTextAlignmentCenter;
        [self.hudPanel addSubview:self.fpsTitle];

        self.fpsValue = [[UILabel alloc] initWithFrame:CGRectMake(5, 22, 45, 25)];
        self.fpsValue.textColor = [UIColor greenColor];
        self.fpsValue.font = [UIFont boldSystemFontOfSize:18];
        self.fpsValue.textAlignment = NSTextAlignmentCenter;
        [self.hudPanel addSubview:self.fpsValue];

        // CĂN CHỈNH LẠI VÒNG TRÒN (XÍCH LẠI GẦN NHAU)
        self.cpuView = [[HUDCircleView alloc] initWithFrame:CGRectMake(55, 6, 35, 35) title:@"CPU"];
        [self.hudPanel addSubview:self.cpuView];

        self.ramView = [[HUDCircleView alloc] initWithFrame:CGRectMake(100, 6, 35, 35) title:@"RAM"];
        [self.hudPanel addSubview:self.ramView];

        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(self.hudPanel.frame, point);
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self];
    self.hudPanel.center = CGPointMake(self.hudPanel.center.x + translation.x, self.hudPanel.center.y + translation.y);
    [recognizer setTranslation:CGPointZero inView:self];
}

- (void)tick:(CADisplayLink *)link {
    if (self.lastTime == 0) { self.lastTime = link.timestamp; return; }
    self.count++;
    NSTimeInterval delta = link.timestamp - self.lastTime;
    
    if (delta >= 1.0) {
        double fps = self.count / delta;
        self.count = 0; self.lastTime = link.timestamp;
        self.fpsValue.text = [NSString stringWithFormat:@"%.0f", fps];

        struct mach_task_basic_info info;
        mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
        kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size);
        double ramMB = (kerr == KERN_SUCCESS) ? (info.resident_size / 1024.0 / 1024.0) : 0;
        [self.ramView updateWithProgress:(ramMB / 6144.0) valueText:[NSString stringWithFormat:@"%.0f MB", ramMB]];

        thread_array_t thread_list; mach_msg_type_number_t thread_count;
        thread_info_data_t thinfo; mach_msg_type_number_t thread_info_count; thread_basic_info_t basic_info_th;
        kerr = task_threads(mach_task_self(), &thread_list, &thread_count);
        float total_cpu = 0;
        if (kerr == KERN_SUCCESS) {
            for (int j = 0; j < thread_count; j++) {
                thread_info_count = THREAD_INFO_MAX;
                kerr = thread_info(thread_list[j], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
                if (kerr == KERN_SUCCESS) {
                    basic_info_th = (thread_basic_info_t)thinfo;
                    if (!(basic_info_th->flags & TH_FLAGS_IDLE)) total_cpu += basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
                }
            }
            vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
        }
        
        NSUInteger numCores = [[NSProcessInfo processInfo] activeProcessorCount];
        float normalized_cpu = total_cpu / numCores;
        if (normalized_cpu > 100.0) normalized_cpu = 100.0; 
        [self.cpuView updateWithProgress:(normalized_cpu / 100.0) valueText:[NSString stringWithFormat:@"%.0f%%", normalized_cpu]];
    }
}
@end

// ==========================================
// COMPONENT 3: TIÊM VÀO HỆ THỐNG
// ==========================================
static PerformanceHUDWindow *hudWindow;

%hook UIWindowScene
- (void)_readySceneForConnection {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            hudWindow = [[PerformanceHUDWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            hudWindow.windowScene = (UIWindowScene *)self;
            hudWindow.rootViewController = [[HUDRootVC alloc] init];
            hudWindow.hidden = NO;
        });
    });
}
%end
