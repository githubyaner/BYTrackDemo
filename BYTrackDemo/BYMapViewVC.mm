//
//  BYMapViewVC.m
//  BYTrackDemo
//
//  Created by SunShine.Rock on 16/9/14.
//  Copyright © 2016年 Berton. All rights reserved.
//

#import "BYMapViewVC.h"

@interface BYMapViewVC () <MAMapViewDelegate>
//地图
@property (nonatomic, strong) MAMapView *mapView;
//画线
@property (nonatomic, strong) MAPolyline *routeLine;
@end

@implementation BYMapViewVC

- (instancetype)init {
    self = [super init];
    if (self) {
        self.pointArr = [NSMutableArray array];
        [self setMapView];
    }
    return self;
}

- (void)setMapView {
    //地图初始化
    self.mapView = [[MAMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _mapView.backgroundColor = [UIColor whiteColor];
    self.mapView.delegate = self;
    //设置定位精度
    _mapView.desiredAccuracy = kCLLocationAccuracyBest;
    //设置定位距离
    _mapView.distanceFilter = 1.0f;
    //普通样式
    _mapView.mapType = MAMapTypeStandard;
    //地图跟着位置移动
    [_mapView setUserTrackingMode:MAUserTrackingModeFollow animated:YES];
    //设置成NO表示关闭指南针；YES表示显示指南针
    _mapView.showsCompass= YES;
    //设置指南针位置
    _mapView.compassOrigin= CGPointMake(_mapView.compassOrigin.x, 22);
    //设置成NO表示不显示比例尺；YES表示显示比例尺
    _mapView.showsScale= YES;
    //设置比例尺位置
    _mapView.scaleOrigin= CGPointMake(_mapView.scaleOrigin.x, 22);
    //开启定位
    _mapView.showsUserLocation = YES;
    //缩放等级
    [_mapView setZoomLevel:18 animated:YES];
    
    //防止系统自动杀掉定位 -- 后台定位
    _mapView.pausesLocationUpdatesAutomatically = NO;
    _mapView.allowsBackgroundLocationUpdates = YES;
    [self.view addSubview:self.mapView];
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //将获取的新坐标居中
    [_mapView setCenterCoordinate:self.currentUL.coordinate animated:YES];
    
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //每次进入界面的时候也可以从数据库读取之前存储的轨迹,然后接上新的数据,一并绘制
    /*
    NSArray *pointArray = [_help getLocalDataOfUserLocationWithKey:@"UserLocation"];
    //读取数据库
    if (pointArray.count != 0) {
        self.pointArr = [_help getLocalDataOfUserLocationWithKey:@"UserLocation"];
        //画线
        [self drawTrackingLine];
    }
     */
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    //屏幕消失的时候,释放地图资源
    [self clearMapView];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self addPointAndCircleView];
}

//添加一个大头针和物理围栏
- (void)addPointAndCircleView {
    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
    pointAnnotation.coordinate = CLLocationCoordinate2DMake(39.952136, 116.50095);
    pointAnnotation.title = @"点我";
    pointAnnotation.subtitle = @"详情";
    
    [_mapView addAnnotation:pointAnnotation];
    
    MACircle *circle = [MACircle circleWithCenterCoordinate:CLLocationCoordinate2DMake(39.952136, 116.50095) radius:5000];
    //在地图上添加圆
    [_mapView addOverlay: circle];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - MAMapViewDelegate
//当位置改变时候调用
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation {
    //updatingLocation 标示是否是location数据更新, YES:location数据更新 NO:heading数据更新
    if (updatingLocation == YES) {
//        self.currentUL = userLocation;//设置当前位置
//        //手机位置信息
//        [self setPointArrWithCurrentUserLocation];
        //增加距离判断
        if (self.currentUL) {
            CLLocationDistance distance = [userLocation.location distanceFromLocation:self.currentUL.location];
            //判断当前点与之前点距离相差小于10米就不计入计算.
            if (distance < 10) {
                return;
            } else {
                self.currentUL = userLocation;//设置当前位置
            }
        } else {
            self.currentUL = userLocation;//设置当前位置
        }
        //手机位置信息
        [self setPointArrWithCurrentUserLocation];
    }
}
//定位失败
- (void)mapView:(MAMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    NSString *errorString = @"";
    switch([error code]) {
        case kCLErrorDenied:
            //Access denied by user
            errorString = @"Access to Location Services denied by user";
            break;
        case kCLErrorLocationUnknown:
            //Probably temporary...
            errorString = @"Location data unavailable";
            //Do something else...
            break;
        default:
            errorString = @"An unknown error has occurred";
            break;
    }
}

//画线方法
- (MAOverlayView *)mapView:(MAMapView *)mapView viewForOverlay:(id <MAOverlay>)overlay {
    //画线
    if ([overlay isKindOfClass:[MAPolyline class]]) {
        MAPolylineView *polylineView = [[MAPolylineView alloc] initWithPolyline:overlay];
        polylineView.lineWidth = 8.f;
        polylineView.strokeColor = [UIColor colorWithRed:177 / 255.0 green:152 / 255.0 blue:198 / 255.0 alpha:0.6];
        return polylineView;
    }
    //原型覆盖物--地理围栏
    if ([overlay isKindOfClass:[MACircle class]]) {
        MACircleView *circleView = [[MACircleView alloc] initWithCircle:overlay];
        circleView.lineWidth = 2.f;
        circleView.strokeColor = [UIColor clearColor];
        circleView.fillColor = [UIColor colorWithRed:139 / 255.0 green:186 / 255.0 blue:1 alpha:0.3];
        return circleView;
    }
    return nil;
}




//添加大头针
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation {
    /*
     *  当然画轨迹的同时,也可以添加个大头针,设置一个地理围栏.
     */
    //大头针标注
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *pointReuseIndentifier = @"pointReuseIndentifier";
        MAPinAnnotationView*annotationView = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndentifier];
        if (annotationView == nil) {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndentifier];
        }
        annotationView.canShowCallout= YES;       //设置气泡可以弹出，默认为NO
        annotationView.animatesDrop = YES;        //设置标注动画显示，默认为NO
        annotationView.draggable = YES;        //设置标注可以拖动，默认为NO
        annotationView.pinColor = MAPinAnnotationColorPurple;
        return annotationView;
    }
    return nil;
}
//点击大头针或者当前坐标调用
- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view {
    //显示到屏幕最中间
    CLLocationCoordinate2D locationView = CLLocationCoordinate2DMake(view.annotation.coordinate.latitude, view.annotation.coordinate.longitude);
    [_mapView setCenterCoordinate:locationView animated:YES];
}
//点击view的泡泡时调用
- (void)mapView:(MAMapView *)mapView didAnnotationViewCalloutTapped:(MAAnnotationView *)view {
    NSLog(@"您选中是我~");
}




#pragma mark - set point and draw lines
//设置数组元素并且去执行画线操作
- (void)setPointArrWithCurrentUserLocation {
    //    NSLog(@"记录一个点");
    //检查零点
    if (_currentUL.location.coordinate.latitude == 0.0f ||
        _currentUL.location.coordinate.longitude == 0.0f)
        return;
    MAPointAnnotation *point = [[MAPointAnnotation alloc] init];
    point.coordinate = _currentUL.location.coordinate;
    [_pointArr addObject:point];
    //画线
    [self drawTrackingLine];
}

//绘制旅行路线
- (void)drawTrackingLine {
    MAMapPoint *pointArray = new MAMapPoint[_pointArr.count];//创建一个结构体数组
    for(int index = 0; index < _pointArr.count; index++) {
        MAPointAnnotation *locationUser = [[MAPointAnnotation alloc] init];
        locationUser = [_pointArr objectAtIndex:index];
        MAMapPoint point = MAMapPointForCoordinate(locationUser.coordinate);
        pointArray[index] = point;
    }
    if (self.routeLine) {
        [self.mapView removeOverlay:self.routeLine];
    }
    self.routeLine = [MAPolyline polylineWithPoints:pointArray count:_pointArr.count];
    if (nil != self.routeLine) {
        //将折线绘制在地图底图标注和兴趣点图标之下
        [self.mapView addOverlay:self.routeLine];
    }
    delete []pointArray;
}

#pragma mark - clear mapview
- (void)clearMapView {
    self.mapView.showsUserLocation = NO;
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    [self.mapView removeOverlays:self.mapView.overlays];
    
    self.mapView.delegate = nil;
}


#pragma mark - 判断当前坐标有没有在某个圆内
#pragma mark - 可将此功能与地理围栏相结合,地理围栏负责展示这片区域,此方法负责进行判断
/*
 @brief 判断一个位置是否在某一个位置某个范围内.
 @param currentCoor 当前位置或者是需要判定的位置
 @param attractionsCoor 判断的中心点位置
 @param radius 中心点位置半径,范围
 */
- (BOOL)distanceBetweenOfCurrentLocation:(CLLocationCoordinate2D)currentCoor attractionsLocation:(CLLocationCoordinate2D)attractionsCoor andRadius:(NSInteger)radius {
    BOOL ptInCircle = MACircleContainsCoordinate(currentCoor, attractionsCoor, radius);
    return ptInCircle;
}

@end
