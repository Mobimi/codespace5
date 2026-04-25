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
        CGFloat radius = frame.size.width / 2.0 - 5;
        CGPoint center = CGPointMake(frame.size.width / 2.0, frame.size.width / 2.0);
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI_2 endAngle:M_PI_2 * 3 clockwise:YES];

        self.bgLayer = [CAShapeLayer layer];
        self.bgLayer.path = circlePath.CGPath;
        self.bgLayer.fillColor = [UIColor clearColor].CGColor;
        self.bgLayer.strokeColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor;
        self.bgLayer.lineWidth = 4.0;
        [self.layer addSublayer:self.bgLayer];

        self.progressLayer = [CAShapeLayer layer];
        self.progressLayer.path = circlePath.CGPath;
        self.progressLayer.fillColor = [UIColor clearColor].CGColor;
        self.progressLayer.strokeColor = [UIColor greenColor].CGColor;
        self.progressLayer.lineWidth = 4.0;
        self.progressLayer.strokeEnd = 0.0; 
        self.progressLayer.lineCap = kCALineCapRound;
        [self.layer addSublayer:self.progressLayer];

        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.width)];
        self.titleLabel.text = title;
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:11];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.titleLabel];

        self.valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(-10, frame.size.width + 2, frame.size.width + 20, 20)];
        self.valueLabel.textColor = [UIColor whiteColor];
        self.valueLabel.font = [UIFont boldSystemFontOfSize:11];
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
// COMPONENT 2: BẢNG ĐIỀU KHIỂN CHÍNH
// ==========================================
@interface PerformanceHUDWindow : UIWindow
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
        self.userInteractionEnabled = YES; 
        self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.85]; 
        self.layer.cornerRadius = 15;
        self.layer.masksToBounds = YES;

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];

        self.fpsTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 50, 15)];
        self.fpsTitle.text = @"FPS";
        self.fpsTitle.textColor = [UIColor lightGrayColor];
        self.fpsTitle.font = [UIFont boldSystemFontOfSize:12];
        self.fpsTitle.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.fpsTitle];

        self.fpsValue = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, 50, 30)];
        self.fpsValue.textColor = [UIColor greenColor];
        self.fpsValue.font = [UIFont boldSystemFontOfSize:22];
        self.fpsValue.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.fpsValue];

        self.cpuView = [[HUDCircleView alloc] initWithFrame:CGRectMake(70, 10, 40, 40) title:@"CPU"];
        [self addSubview:self.cpuView];

        self.ramView = [[HUDCircleView alloc] initWithFrame:CGRectMake(130, 10, 40, 40) title:@"RAM"];
        [self addSubview:self.ramView];

        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

// --- HÀM XỬ LÝ KÉO THẢ CHUẨN ---
static CGPoint startCenter;
static CGPoint startTouch;

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        startCenter = self.center;
        startTouch = [recognizer locationInView:nil]; 
    } 
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint currentTouch = [recognizer locationInView:nil];
        CGFloat dx = currentTouch.x - startTouch.x;
        CGFloat dy = currentTouch.y - startTouch.y;
        self.center = CGPointMake(startCenter.x + dx, startCenter.y + dy);
    }
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
        self.fpsValue.text = [NSString stringWithFormat:@"%.0f", fps];

        struct mach_task_basic_info info;
        mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
        kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size);
        double ramMB = (kerr == KERN_SUCCESS) ? (info.resident_size / 1024.0 / 1024.0) : 0;
        
        CGFloat ramProgress = ramMB / 6144.0;
        [self.ramView updateWithProgress:ramProgress valueText:[NSString stringWithFormat:@"%.0f MB", ramMB]];

        thread_array_t thread_list;
        mach_msg_type_number_t thread_count;
        thread_info_data_t thinfo;
        mach_msg_type_number_t thread_info_count;
        thread_basic_info_t basic_info_th;
        
        kerr = task_threads(mach_task_self(), &thread_list, &thread_count);
        float total_cpu = 0;
        
        if (kerr == KERN_SUCCESS) {
            for (int j = 0; j < thread_count; j++) {
                thread_info_count = THREAD_INFO_MAX;
                kerr = thread_info(thread_list[j], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
                if (kerr == KERN_SUCCESS) {
                    basic_info_th = (thread_basic_info_t)thinfo;
                    if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
                        total_cpu += basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
                    }
                }
            }
            vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
        }
        
        CGFloat cpuProgress = total_cpu / 100.0; 
        [self.cpuView updateWithProgress:cpuProgress valueText:[NSString stringWithFormat:@"%.0f%%", total_cpu]];
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
            hudWindow = [[PerformanceHUDWindow alloc] initWithFrame:CGRectMake(20, 50, 185, 75)];
            hudWindow.hidden = NO;
        });
    });
}
%end
