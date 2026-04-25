#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

// =====================================================
// PHẦN 1: KÉT SẮT LƯU TRỮ (Universal Settings)
// =====================================================
static CGFloat ut_scale = 3.0;
static BOOL ut_ipadUI = NO;

static void LoadSettings() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"UT_Scale"]) {
        ut_scale = [defaults floatForKey:@"UT_Scale"];
    } else {
        ut_scale = [UIScreen mainScreen].scale; 
    }
    ut_ipadUI = [defaults boolForKey:@"UT_IpadUI"];
}

#define SAVE_FLOAT(key, val) [[NSUserDefaults standardUserDefaults] setFloat:val forKey:key]; [[NSUserDefaults standardUserDefaults] synchronize]
#define SAVE_BOOL(key, val) [[NSUserDefaults standardUserDefaults] setBool:val forKey:key]; [[NSUserDefaults standardUserDefaults] synchronize]

// =====================================================
// PHẦN 2: THIẾT KẾ GIAO DIỆN MENU (Nút nổi & Bảng điều khiển)
// =====================================================
@interface UTMenuWindow : UIWindow
@property (nonatomic, strong) UIButton *floatingBtn;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UILabel *scaleLabel;
@end

@implementation UTMenuWindow
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelStatusBar + 200.0;
        self.backgroundColor = [UIColor clearColor]; // Xuyên thấu
        
        // --- NÚT NỔI ---
        self.floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.floatingBtn.frame = CGRectMake(20, 100, 45, 45);
        self.floatingBtn.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
        self.floatingBtn.layer.cornerRadius = 22.5;
        self.floatingBtn.layer.borderWidth = 1.5;
        self.floatingBtn.layer.borderColor = [UIColor cyanColor].CGColor;
        [self.floatingBtn setTitle:@"🚀" forState:UIControlStateNormal];
        self.floatingBtn.titleLabel.font = [UIFont systemFontOfSize:20];
        [self.floatingBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.floatingBtn addGestureRecognizer:pan];
        [self addSubview:self.floatingBtn];
        
        // --- BẢNG MENU ---
        self.menuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 260, 200)];
        self.menuView.center = self.center;
        self.menuView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
        self.menuView.layer.cornerRadius = 15;
        self.menuView.layer.borderWidth = 1;
        self.menuView.layer.borderColor = [UIColor grayColor].CGColor;
        self.menuView.hidden = YES;
        [self addSubview:self.menuView];
        
        // Tiêu đề
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 260, 30)];
        title.text = @"UNIVERSAL TWEAK";
        title.textColor = [UIColor cyanColor];
        title.font = [UIFont boldSystemFontOfSize:18];
        title.textAlignment = NSTextAlignmentCenter;
        [self.menuView addSubview:title];
        
        // --- MODULE 1: ÉP ĐỘ PHÂN GIẢI ---
        UILabel *scTitle = [[UILabel alloc] initWithFrame:CGRectMake(15, 50, 150, 20)];
        scTitle.text = @"Độ Phân Giải GPU";
        scTitle.textColor = [UIColor whiteColor];
        scTitle.font = [UIFont systemFontOfSize:13];
        [self.menuView addSubview:scTitle];
        
        self.scaleLabel = [[UILabel alloc] initWithFrame:CGRectMake(180, 50, 60, 20)];
        self.scaleLabel.text = [NSString stringWithFormat:@"%.1fx", ut_scale];
        self.scaleLabel.textColor = [UIColor orangeColor];
        self.scaleLabel.font = [UIFont boldSystemFontOfSize:13];
        self.scaleLabel.textAlignment = NSTextAlignmentRight;
        [self.menuView addSubview:self.scaleLabel];
        
        UISlider *scaleSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, 75, 230, 30)];
        scaleSlider.minimumValue = 1.0;
        scaleSlider.maximumValue = 3.0;
        scaleSlider.value = ut_scale;
        [scaleSlider addTarget:self action:@selector(scaleChanged:) forControlEvents:UIControlEventValueChanged];
        [self.menuView addSubview:scaleSlider];
        
        // --- MODULE 2: GIAO DIỆN IPAD ---
        UILabel *ipadTitle = [[UILabel alloc] initWithFrame:CGRectMake(15, 120, 180, 20)];
        ipadTitle.text = @"Giao diện iPad (Tablet UI)";
        ipadTitle.textColor = [UIColor whiteColor];
        ipadTitle.font = [UIFont boldSystemFontOfSize:13];
        [self.menuView addSubview:ipadTitle];
        
        UISwitch *ipadSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(195, 115, 50, 30)];
        ipadSwitch.on = ut_ipadUI;
        ipadSwitch.onTintColor = [UIColor cyanColor];
        [ipadSwitch addTarget:self action:@selector(ipadUIChanged:) forControlEvents:UIControlEventValueChanged];
        [self.menuView addSubview:ipadSwitch];
        
        // Lưu ý chung
        UILabel *note = [[UILabel alloc] initWithFrame:CGRectMake(0, 165, 260, 20)];
        note.text = @"⚠️ Thoát hẳn Game vào lại để áp dụng ⚠️";
        note.textColor = [UIColor redColor];
        note.font = [UIFont boldSystemFontOfSize:11];
        note.textAlignment = NSTextAlignmentCenter;
        [self.menuView addSubview:note];
    }
    return self;
}

// Giữ nguyên tính năng xuyên thấu cảm ứng
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.floatingBtn.hidden && CGRectContainsPoint(self.floatingBtn.frame, point)) return YES;
    if (!self.menuView.hidden && CGRectContainsPoint(self.menuView.frame, point)) return YES;
    return NO;
}

- (void)toggleMenu { self.menuView.hidden = !self.menuView.hidden; }

// Kéo thả nút nổi
static CGPoint startCenter;
static CGPoint startTouch;
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        startCenter = self.floatingBtn.center;
        startTouch = [recognizer locationInView:self];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint currentTouch = [recognizer locationInView:self];
        self.floatingBtn.center = CGPointMake(startCenter.x + (currentTouch.x - startTouch.x), startCenter.y + (currentTouch.y - startTouch.y));
    }
}

// Xử lý lưu thiết lập
- (void)scaleChanged:(UISlider *)sender {
    float val = round(sender.value * 2.0) / 2.0; 
    sender.value = val;
    self.scaleLabel.text = [NSString stringWithFormat:@"%.1fx", val];
    ut_scale = val;
    SAVE_FLOAT(@"UT_Scale", val);
}
- (void)ipadUIChanged:(UISwitch *)sender {
    ut_ipadUI = sender.on;
    SAVE_BOOL(@"UT_IpadUI", sender.on);
}
@end

// =====================================================
// PHẦN 3: LÕI HACK/MOD (THE HOOKS)
// =====================================================

// --- 1. HỆ THỐNG ĐỘ PHÂN GIẢI ---
%hook UIScreen
- (CGFloat)scale { return ut_scale < 3.0 ? ut_scale : %orig; }
- (CGFloat)nativeScale { return ut_scale < 3.0 ? ut_scale : %orig; }
%end

%hook UIWindow
- (void)setContentScaleFactor:(CGFloat)scale { %orig(ut_scale < 3.0 ? ut_scale : scale); }
%end

%hook UIView
- (void)setContentScaleFactor:(CGFloat)scale { %orig(ut_scale < 3.0 ? ut_scale : scale); }
%end

%hook CAMetalLayer
- (void)setContentsScale:(CGFloat)scale { %orig(ut_scale < 3.0 ? ut_scale : scale); }
%end

%hook CAEAGLLayer
- (void)setContentsScale:(CGFloat)scale { %orig(ut_scale < 3.0 ? ut_scale : scale); }
%end

// --- 2. HỆ THỐNG GIẢ MẠO THIẾT BỊ (UI IDIOM SPOOFING) ---
%hook UIDevice
- (UIUserInterfaceIdiom)userInterfaceIdiom {
    // Nếu bật công tắc, hét vào mặt Game: "Tao là iPad!"
    if (ut_ipadUI) {
        return UIUserInterfaceIdiomPad; 
    }
    return %orig;
}
%end

// =====================================================
// PHẦN 4: TIÊM MENU VÀO GAME
// =====================================================
static UTMenuWindow *utWindow;

%hook UIWindowScene
- (void)_readySceneForConnection {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            LoadSettings(); 
            utWindow = [[UTMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            utWindow.hidden = NO;
        });
    });
}
%end
