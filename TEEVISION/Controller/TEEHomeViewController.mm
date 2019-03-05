//
//  ViewController.m
//  EyeBlickCheck
//
//  Created by Nile on 2017/3/17.
//  Copyright © 2017年 Nile. All rights reserved.
//

#import "TEEHomeViewController.h"
#import "CaptureFaceService.h"
#import "TEEHomeViewController.h"
#import "UIImage+OpenCV.h"
#import "TEEFaceDlibWrapper.h"
#import "ZDScrollView.h"
#import <AVFoundation/AVFoundation.h>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/opencv.hpp>
#import <CoreMedia/CMTime.h>
#import <CoreGraphics/CGGeometry.h>
#import "UIView+Extension.h"

CGFloat btnW = 100;
CGFloat btnY = 100;
CGFloat btnH = 50;

typedef enum{
    Fase = 0,       // 人脸识别
    Shopping = 1,   // 拍照购物
    Clothes = 2,    // 服装
    Beautiful = 3,  // 美妆
}CameraType;


@interface TEEHomeViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UIView *vidioView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (nonatomic, nonatomic) UIButton *changeCamalorButton;
/** AVFoundation相关
 AVCaptureSession对象是用来管理采集数据和输出数据的，它负责协调从哪里采集数据，输出到哪里。
 */
@property (nonatomic,strong) AVCaptureSession *session;
// 数据输入
@property (nonatomic,strong) AVCaptureDeviceInput *captureInput;
// 捕获的视频数据输出
@property (nonatomic,strong) AVCaptureVideoDataOutput *captureOutput;
// 捕获的元数据输出
@property (nonatomic,strong) AVCaptureMetadataOutput *metaDateOutput;

@property (nonatomic,strong) AVCaptureConnection *captureConnection;

@property (nonatomic,strong) ZDScrollView *typeScroView;
@property (nonatomic,strong) UIImageView *cameraView;
@property (nonatomic,strong) UIImageView *catImageView;
@property (nonatomic,strong) UIButton *openBetiful;
@property (nonatomic,assign) BOOL isOpenBetiful;
@property (nonatomic,strong) dispatch_queue_t sample;
@property (nonatomic,strong) dispatch_queue_t faceQueue;
@property (nonatomic,copy) NSArray *currentMetadata; //?< 如果检测到了人脸系统会返回一个数组 我们将这个数组存起来

@property (nonatomic,assign) CameraType cameraType;

@property (nonatomic,strong)CATransition *animation;
@end

@implementation TEEHomeViewController{
    TEEFaceDlibWrapper *face;
    BOOL _isTwinkle;//第一次闭眼
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.cameraType = Fase;
    face = [[TEEFaceDlibWrapper alloc] init];
    _currentMetadata = [NSMutableArray arrayWithCapacity:0];
    [self.view addSubview:self.cameraView];
    _sample = dispatch_queue_create("sample", NULL);
    _faceQueue = dispatch_queue_create("face", NULL);
    
    _catImageView = [[UIImageView alloc] init];
    _catImageView.image = [UIImage imageNamed:@"timg"];
    
    [self.view addSubview:self.catImageView];
    
    _openBetiful = [[UIButton alloc]initWithFrame:CGRectMake((self.view.frame.size.width - 100)/2, 50, 100, 40)];
    [_openBetiful setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [_openBetiful setTitle:@"打开美颜" forState:UIControlStateNormal];
    [_openBetiful addTarget:self action:@selector(openBetifulClickHandler) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_openBetiful];
    
    //一个AVCaptureDevice对象代表一个物理采集设备，我们可以通过该对象来设置物理设备的属性。
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *deviceF;
    for (AVCaptureDevice *device in devices )
    {
        if ( device.position == AVCaptureDevicePositionFront )
        {
            deviceF = device;
            break;
        }
    }
    
    AVCaptureDeviceInput*input = [[AVCaptureDeviceInput alloc] initWithDevice:deviceF error:nil];
    self.captureInput = input;
    
    
    //AVCaptureVideoDataOutput，作为视频数据的输出端。
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    self.captureOutput = output;
    
    [output setSampleBufferDelegate:self queue:_sample];
    
    AVCaptureMetadataOutput *metaout = [[AVCaptureMetadataOutput alloc] init];
    self.metaDateOutput = metaout;
    
    [metaout setMetadataObjectsDelegate:self queue:_faceQueue];
    self.session = [[AVCaptureSession alloc] init];
    [self.session beginConfiguration];
    
    if ([self.session canAddInput:self.captureInput]) {
        [self.session addInput:self.captureInput];
    }
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        [self.session setSessionPreset:AVCaptureSessionPreset640x480];
    }
    if ([self.session canAddOutput:self.captureOutput]) {
        [self.session addOutput:self.captureOutput];
    }
    if ([self.session canAddOutput:self.metaDateOutput]) {
        [self.session addOutput:self.metaDateOutput];
    }
    [self.session commitConfiguration];
    
    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [output setVideoSettings:videoSettings];
    //这里 我们告诉要检测到人脸 就给我一些反应，里面还有QRCode 等 都可以放进去，就是 如果视频流检测到了你要的 就会出发下面第二个代理方法
    [metaout setMetadataObjectTypes:@[AVMetadataObjectTypeFace]];
    AVCaptureSession* session = (AVCaptureSession *)self.session;
    
    // 获取连接并设置视频方向为竖屏方向
    self.captureConnection = [self.captureOutput connectionWithMediaType:AVMediaTypeVideo];
    self.captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
//     设置是否为镜像，前置摄像头采集到的数据本来就是翻转的，这里设置为镜像把画面转回来 AVCaptureDevicePositionFront
    if (self.captureInput.device.position == AVCaptureDevicePositionFront && self.captureConnection.supportsVideoMirroring)
    {
        self.captureConnection.videoMirrored = YES;
    }
    
    //前置摄像头一定要设置一下 要不然画面是镜像
    for (AVCaptureVideoDataOutput* output in session.outputs) {
        for (AVCaptureConnection * av in output.connections) {
            //判断是否是前置摄像头状态
            if (av.supportsVideoMirroring) {
                //镜像设置
                av.videoOrientation = AVCaptureVideoOrientationPortrait;
                av.videoMirrored = YES;
            }
        }
    }
    
    [self.session startRunning];
    _animation = [[CATransition alloc]init];
    [self.view addSubview:self.typeScroView];
    [self.view addSubview:self.changeCamalorButton];
}

- (UIImageView *)cameraView
{
    if (!_cameraView) {
        _cameraView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        //不拉伸
        _cameraView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _cameraView;
}

-(UIButton *)changeCamalorButton{
    if (!_changeCamalorButton) {
        _changeCamalorButton = [[UIButton alloc]initWithFrame:CGRectMake(ScreenSize.width/2 - 20, 50, 40, 40)];
        [_changeCamalorButton setImage:[UIImage imageNamed:@"changeCamala"] forState:UIControlStateNormal];
        [_changeCamalorButton addTarget:self action:@selector(swapFrontAndBackCameras) forControlEvents:UIControlEventTouchUpInside];
    }
    return _changeCamalorButton;
}

-(ZDScrollView *)typeScroView {
    if (!_typeScroView) {
        _typeScroView = [[ZDScrollView alloc] initWithFrame:CGRectMake(ScreenSize.width/10, kScreenHeight - 70, ScreenSize.width/5*4, 50)];
        _typeScroView.margin = 10;
        _typeScroView.lineHeight = 3;
        [_typeScroView cornerRadius:0 borderColor:[UIColor whiteColor].CGColor borderWidth:1];
        _typeScroView.titles = @[@"人脸", @"购物", @"服装" ];
        @weakify(self)
        _typeScroView.callBackBlock = ^(NSInteger *t){   // 1
            @strongify(self)
            NSLog(@"t==%tu",t);
            printf("%ld ", (long)t);
            if (t == (NSInteger *)1000){
                _cameraType = Fase;
                [self.openBetiful setHidden:false];
                [self.changeCamalorButton setHidden:true];
            }
            if (t == (NSInteger *)1001){
                _cameraType = Shopping;
                [self.openBetiful setHidden:true];
                [self.changeCamalorButton setHidden:false];
            }
            if (t == (NSInteger *)1002){
                _cameraType = Clothes;
                [self.openBetiful setHidden:true];
                [self.changeCamalorButton setHidden:false];
            }
        };
    }
    return _typeScroView;
}

#pragma 设置摄像头
-(void)setCamalor {
    // 1:获取之前的镜头
    //    AVCaptureDevicePosition p = self.captureInput.device.position;
    //
    //    // 2:获取当前显示的镜头
    //    switch (self.cameraType) {
    //        case Clothes:
    //            p = AVCaptureDevicePositionBack;
    //            break;
    //        case Beautiful:
    //            p = AVCaptureDevicePositionBack;
    //            break;
    //        case Fase:
    //            p = AVCaptureDevicePositionFront;
    //            break;
    //        default:
    //            break;
    //    }
    //    [self changeCamalorInfo:p];
}

- (NSError *)p_errorWithDomain:(NSString *)domain
{
    NSLog(@"%@", domain);
    return [NSError errorWithDomain:domain code:1 userInfo:nil];
}

#pragma 切换摄像头
- (void)changeCamalor {
    // 获取所有摄像头
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    // 获取当前摄像头方向
    AVCaptureDevicePosition currentPosition = self.captureInput.device.position;
    AVCaptureDevicePosition toPosition = AVCaptureDevicePositionUnspecified;
    if (currentPosition == AVCaptureDevicePositionBack || currentPosition == AVCaptureDevicePositionUnspecified)
    {
        toPosition = AVCaptureDevicePositionFront;
    }
    else
    {
        toPosition = AVCaptureDevicePositionBack;
    }
    
    NSArray *captureDeviceArray = [cameras filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d", toPosition]];
    if (captureDeviceArray.count == 0)
    {
//        return [self p_errorWithDomain:@"MAVideoCapture::reverseCamera failed! get new Camera Faild!"];
    }
    
    NSError *error = nil;
    AVCaptureDevice *camera = captureDeviceArray.firstObject;
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
    // 修改输入设备
    [self.session beginConfiguration];
    [self.session removeInput:self.captureInput];
    if ([_session canAddInput:newInput])
    {
        [_session addInput:newInput];
        self.captureInput = newInput;
    }

    // 重新获取连接并设置方向
    self.captureConnection = [self.captureOutput connectionWithMediaType:AVMediaTypeVideo];
    self.captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    //前置摄像头一定要设置一下 要不然画面是镜像
        for (AVCaptureVideoDataOutput* output in self.session.outputs) {
            for (AVCaptureConnection * av in output.connections) {
                //判断是否是前置摄像头状态
                if (av.supportsVideoMirroring) {
                    //镜像设置
                    av.videoOrientation = AVCaptureVideoOrientationPortrait;
                    av.videoMirrored = YES;
                }
    
            }
        }
    if (self.captureInput.device.position == AVCaptureDevicePositionFront && self.captureConnection.supportsVideoMirroring)
    {
        self.captureConnection.videoMirrored = YES;
    }
    
    [self.session commitConfiguration];
    
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}

- (void)swapFrontAndBackCameras {
    // Assume the session is already running
    
    NSArray *inputs =self.session.inputs;
    for (AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera =nil;
            AVCaptureDeviceInput *newInput =nil;
            
            if (position ==AVCaptureDevicePositionFront)
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            else
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            // 重新获取连接并设置方向
            self.captureConnection = [self.captureOutput connectionWithMediaType:AVMediaTypeVideo];
            self.captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
            
            if (self.captureInput.device.position == AVCaptureDevicePositionFront && self.captureConnection.supportsVideoMirroring)
            {
                self.captureConnection.videoMirrored = YES;
            }
            
            // beginConfiguration ensures that pending changes are not applied immediately
            [self.session beginConfiguration];
            
            [self.session removeInput:input];
            [self.session addInput:newInput];
            
            
            //前置摄像头一定要设置一下 要不然画面是镜像
            for (AVCaptureVideoDataOutput* output in self.session.outputs) {
                for (AVCaptureConnection * av in output.connections) {
                    //判断是否是前置摄像头状态
                    if (av.supportsVideoMirroring) {
                        //镜像设置
                        av.videoOrientation = AVCaptureVideoOrientationPortrait;
                        av.videoMirrored = YES;
                    }
                    
                }
            }
           
            [self.session commitConfiguration];
            break;
        }
    }
}



#pragma 摄像头相关
- (BOOL) isCameraAvailable{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}
// 前面的摄像头是否可用
- (BOOL) isFrontCameraAvailable{
    
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}
// 后面的摄像头是否可用
- (BOOL) isRearCameraAvailable{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

-(BOOL) hasMultipleCameras {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    if (devices != nil && [devices count] > 1) return YES;
    return NO;
}


#pragma mark - AVCaptureSession Delegate -
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    //当检测到了人脸会走这个回调
    NSLog(@"metadataObjects===%@",metadataObjects);
    self.currentMetadata = metadataObjects;
    for (AVMetadataFaceObject *object in metadataObjects) {
        if (object.yawAngle >= 315) {//左转头
        }else if (object.yawAngle >= 45 && object.yawAngle <= 90){//右转头
            
        }
    }
    NSLog(@"检测到了人脸");
}

- (UIImage*)imageFromPixelBuffer:(CMSampleBufferRef)p {
    CVImageBufferRef buffer;
    buffer = CMSampleBufferGetImageBuffer(p);
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = (uint8_t *)CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    return image;
}

// 使用captureOut:didOutputSampleBuffer:fromConnection方法将被捕获的视频抽样帧发送给抽样缓存委托，然后每个抽样缓存（CMSampleBufferRef）被转换成imageFromSampleBuffer中的一个UIImage对象。
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSMutableArray *bounds = [NSMutableArray arrayWithCapacity:0];
    for (AVMetadataFaceObject *faceobject in self.currentMetadata) {
        AVMetadataObject *face = [output transformedMetadataObjectForMetadataObject:faceobject connection:connection];
        [bounds addObject:[NSValue valueWithCGRect:face.bounds]];
    }
    
    UIImage *image = [self imageFromPixelBuffer:sampleBuffer];
    
    // 拿到图片
    switch (self.cameraType) {
        case Fase:{
            
            if (self.currentMetadata.count < 1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.catImageView setHidden:YES];
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.catImageView setHidden:NO];
                });
            }
            cv::Mat mat;
            // 美颜
            mat = [self ImageTobilateraFilter:image];
            
            // 获取关键点，将脸部信息的数组 和 相机流 传进去
            NSArray *facesLandmarks = [face detecitonOnSampleBuffer:sampleBuffer inRects:bounds];
            // 绘制68 个关键点
            for (NSArray *landmarks in facesLandmarks) {
                //        NSLog(@"坐标的总个数=%zd",landmarks.count);
                
                //        NSValue *value0 = landmarks[36];
                NSValue *value1 = landmarks[37];
                //        NSValue *value2 = landmarks[38];
                //        NSValue *vlaue3 = landmarks[39];
                //        NSValue *value4 = landmarks[40];
                
                // 嘴唇 20个点
                NSValue *value5 = landmarks[41];
                
                NSValue *value6 = landmarks[38];
                NSValue *value7 = landmarks[40];
                //        CGPoint point0 = [value0 CGPointValue];
                //        CGPoint point1 = [value1 CGPointValue];
                CGPoint point2 = [value1 CGPointValue];
                //        CGPoint point3 = [vlaue3 CGPointValue];
                //        CGPoint point4 = [value4 CGPointValue];
                CGPoint point5 = [value5 CGPointValue];
                
                CGPoint point6 = [value6 CGPointValue];
                CGPoint point7 = [value7 CGPointValue];
                
                for (AVMetadataFaceObject *object in self.currentMetadata) {
                    
                    //            if (object.yawAngle >= 315) {//左转头
                    //
                    //            }else if (object.yawAngle >= 45 && object.yawAngle <= 90){//右转头
                    //
                    //            }
                    if (object.yawAngle == 0) {//说明正脸面对镜头
                        if (point5.y - point2.y < 5) {
                            
                            _isTwinkle = YES;
                        }else{
                            //            NSLog(@"没有眨眼睛");
                            
                        }
                        if (point5.y - point2.y > 8) {
                            if (_isTwinkle == YES) {
                                //            dispatch_async(dispatch_get_main_queue(), ^{
                                //            UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"眨眼睛了" message: nil preferredStyle:UIAlertControllerStyleAlert];
                                //                        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
                                //                                            }]];
                                //                [self presentViewController:alertController animated:YES completion:nil];
                                //                            });
                            }
                            _isTwinkle = NO;
                        }
                    }
                }
                
                for (int i = 0 ; i < landmarks.count; i++) {
                    CGPoint p = [landmarks[i] CGPointValue];
                    NSLog(@"人脸信息坐标位置=%@",NSStringFromCGPoint(p));
                    
                    // 人脸信息坐标位置绘制点
                    cv::rectangle(mat, cv::Rect(p.x,p.y,4,4), cv::Scalar(255,0,0,255),-1);
                    
                    // 嘴唇美妆
                    if ( i > 47 && i < 68) {
                    }
                    
                }
            }
            
            for (NSValue *rect in bounds) {
                CGRect r = [rect CGRectValue];
                //画框
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.catImageView.frame = CGRectMake(r.origin.x, r.origin.y - r.size.width / 566 * 404, r.size.width, r.size.width / 566 * 404);
                    self.catImageView.center = CGPointMake(r.origin.x + r.size.width / 2 - 50, r.origin.y - r.size.height / 2 );
                });
                cv::rectangle(mat, cv::Rect(r.origin.x,r.origin.y,r.size.width,r.size.height), cv::Scalar(255,0,0,255));
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.cameraView.image = [UIImage imageFromCVMat:mat];
            });
        }
            
            break;
        case Shopping:{
            cv::Mat mat;
            // 美颜
            mat = [self ImageTobilateraFilter:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.catImageView setHidden:YES];
                self.cameraView.image = [UIImage imageFromCVMat:mat];
            });
            
            break;
        }
        case Clothes:{
            cv::Mat mat;
            mat = [self ImageTobilateraFilter:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.catImageView setHidden:YES];
                self.cameraView.image = [UIImage imageFromCVMat:mat];
            });
            
            break;
        }
        case Beautiful:{
            cv::Mat mat;
            mat = [self ImageTobilateraFilter:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.catImageView setHidden:YES];
                self.cameraView.image = [UIImage imageFromCVMat:mat];
            });
            
            break;
        }
        default:
            break;
    }
    
    // 调整摄像头
    [self setCamalor];
    
}

-(void)openBetifulClickHandler {
    
    if (_isOpenBetiful == NO) {
        [self.openBetiful setTitle:@"已打开美颜" forState:UIControlStateNormal];
    }else {
        [self.openBetiful setTitle:@"已关闭美颜" forState:UIControlStateNormal];
    }
    _isOpenBetiful = !_isOpenBetiful;
}

// 双边滤波
- (cv::Mat)ImageTobilateraFilter:(UIImage *)image
{
    cv::Mat mat_image_src,gray;
    mat_image_src = [image cvMatRepresentationColor];
    if (_isOpenBetiful == YES){
        //    cv::cvtColor(mat_image_src, gray,CV_BGR2BGRA);
        cvtColor(mat_image_src, gray, CV_RGBA2RGB, 2);
        cv::Mat mat_image_out;
        int value1 = 3;//磨皮程度与细节程度的确定
        // int value2 = 1;//磨皮程度与细节程度的确定
        int dx = value1 * 5;    //双边滤波参数之一
        double fc = value1 * 12.5; //双边滤波参数之一
        cv::bilateralFilter(gray, mat_image_out, dx, fc, fc);
        return mat_image_out;
    }
    else {
        return mat_image_src;
    }
    
}

//- (void)accelerometer:(UIAccelerometer *)accelerometerdidAccelerate:(UIAcceletration *)acceleration
//{
//    if(fabsf(acceleration.x)>2.0||fabsf(acceleration.y>2.0)||fabsf(acceleration.z)>2.0)
//    {
//        //NSLog(@"检测到晃动");
//    }
//}
//- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration{
//    if (fabsf(acceleration.x) > 1.0 || fabsf(acceleration.y > 1.0 || fabsf(acceleration.z) > 1.0)) {
//        NSLog(@"检测到晃动");
//    }
//}

@end
