//
//  ViewController.m
//  speedtest
//
//  Created by n01027 on 2015/10/13.
//  Copyright (c) 2015年 gotyoooo. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "Reachability.h"
#import "SVProgressHUD.h"

@interface ViewController () <CLLocationManagerDelegate>

@end

@implementation ViewController
{
    CLLocationManager *_manager;
    NSString *_latitude;
    NSString *_longitude;
}
@synthesize checkStartBtn;
@synthesize resultTextView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    _manager = [CLLocationManager new];
    [_manager setDelegate:self];
    
    
    // iOS8未満は、このメソッドは無いので
    if ([_manager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        
        // GPSを取得する旨の認証をリクエストする
        // 「このアプリ使っていない時も取得するけどいいでしょ？」
        [_manager requestAlwaysAuthorization];
    }
    
    [_manager startUpdatingLocation];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)checkStartTouchDown:(id)sender {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD showWithStatus:@"Check Now ..."];
}

- (IBAction)checkStartBtnTouchUp:(id)sender {
    
    // テストURLリスト取得
    NSString *url = @"https://feu2r00od3.execute-api.us-west-2.amazonaws.com/prod/speedtesturls";
    NSMutableURLRequest *requestSpeedTestUrls = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [requestSpeedTestUrls setValue:@"3Wh2f7SpkH65BXgyZ7bebaPMJHTeb1Vr2swBSze9" forHTTPHeaderField:@"X-API-KEY"];
    
    NSURLResponse *resp;
    NSError *err;
    NSData *result = [NSURLConnection sendSynchronousRequest:requestSpeedTestUrls
                                           returningResponse:&resp error:&err];
    //JSONをパース
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingAllowFragments error:nil];
    
    
    //計測
    int checkCount = 10;
    NSString *outpustStr = @"";
    
    NSString *nowLatitude = _latitude;
    NSString *nowLongitude = _longitude;
    for (id object in jsonArray) {
        NSLog(@"url : %@", object);
        
        outpustStr = [NSString stringWithFormat:@"%@●Test for %@\n", outpustStr, object];
        for (int i = 0; i < checkCount; i++) {
            outpustStr = [NSString stringWithFormat:@"%@%d time -> %@sec\n",
                          outpustStr,
                          i + 1,
                          [self checkResponceTime:object latitude:nowLatitude longitude:nowLongitude]
                          ];
        }
    }
    resultTextView.text = outpustStr;
    
    [SVProgressHUD showSuccessWithStatus:@"Complet!！Thank you!!"];
}

// http通信の速度を計測し、APIで登録する関数
// 計測結果時間を返す
- (NSString*)checkResponceTime:(NSString*)url latitude:(NSString*)latitude longitude:(NSString*)longitude
{
    // インスタンス変数
    NSDate *startDate;
    NSDate *endDate;
    
    // 処理開始位置で現在時間を代入
    startDate = [NSDate date];
    
    //URL文字列の作成
    NSString *address = url;
    
    //コンビニエンスコンストラクタってやつらしい
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:address]];
    //レスポンス変数を空で宣言（必要に応じてオブジェクトが作成されるから）
    NSURLResponse *response = nil;
    //エラー変数を空で宣言（必要に応じてオブジェクトが作成されるから）
    NSError *error = nil;
    //NSURLConnectionのメソッドを呼び出して同期接続を開始
    NSData *data = [NSURLConnection sendSynchronousRequest: request returningResponse:&response error:&error];
    
    // 処理終了位置で現在時間を代入
    endDate = [NSDate date];
    
    // 開始時間と終了時間の差を表示
    NSTimeInterval interval = [endDate timeIntervalSinceDate:startDate];
    NSLog(@"処理開始時間 = %@",[self getDateString:startDate]);
    NSLog(@"処理終了時間 = %@",[self getDateString:endDate]);
    NSLog(@"処理時間 = %.3f秒",interval);
    
    // キャリア情報等取得
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    
    // 接続情報確認
    Reachability *curReach = [Reachability reachabilityForInternetConnection];
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    int useWifi;
    switch (netStatus) {
        case ReachableViaWiFi:  //WiFi
            useWifi = 1;
            break;
        default:
            useWifi = 0;
            break;
    }
    
    NSMutableDictionary *mutableDic = [NSMutableDictionary dictionary];
    [mutableDic setValue:[NSString stringWithFormat: @"%@",address] forKey:@"url"];
    [mutableDic setValue:[NSString stringWithFormat: @"%.3f",interval] forKey:@"time"];
    [mutableDic setValue:[NSString stringWithFormat: @"%@",latitude] forKey:@"latitude"];
    [mutableDic setValue:[NSString stringWithFormat: @"%@",longitude] forKey:@"longitude"];
    [mutableDic setValue:[NSString stringWithFormat: @"%@",[UIDevice currentDevice].model] forKey:@"device_model"];
    [mutableDic setValue:[NSString stringWithFormat: @"%@",[UIDevice currentDevice].systemVersion] forKey:@"system_version"];
    [mutableDic setValue:[NSString stringWithFormat: @"%@",carrier.carrierName] forKey:@"carrier_name"];
    [mutableDic setValue:[NSString stringWithFormat: @"%@",carrier.mobileCountryCode] forKey:@"mobile_country_code"];
    [mutableDic setValue:[NSString stringWithFormat: @"%@",carrier.mobileNetworkCode] forKey:@"mobile_network_code"];
    [mutableDic setValue:[NSString stringWithFormat: @"%@",carrier.isoCountryCode] forKey:@"iso_country_code"];
    [mutableDic setValue:[NSString stringWithFormat: @"%d",useWifi] forKey:@"use_wifi"];
    
    //JSONに変換
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mutableDic
                                                       options:2
                                                         error:&jsonError];
    NSString *requestJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(requestJson);
    
    // 結果登録
    NSMutableURLRequest *requestSpeedTest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://6529u3hl62.execute-api.us-west-2.amazonaws.com/prod/speedtest"]];
    [requestSpeedTest prepareForInterfaceBuilder];
    [requestSpeedTest setHTTPMethod:@"POST"];
    [requestSpeedTest setValue:@"3Wh2f7SpkH65BXgyZ7bebaPMJHTeb1Vr2swBSze9" forHTTPHeaderField:@"X-API-KEY"];
    [requestSpeedTest setHTTPBody: [(NSString*)requestJson dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLResponse *resp;
    NSError *err;
    
    NSData *result = [NSURLConnection sendSynchronousRequest:requestSpeedTest
                                           returningResponse:&resp error:&err];
    
    return [NSString stringWithFormat: @"%.3f",interval];
}

// 日付をミリ秒までの表示にして文字列で返すメソッド
- (NSString*)getDateString:(NSDate*)date
{
    // 日付フォーマットオブジェクトの生成
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    // フォーマットを指定の日付フォーマットに設定
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss.SSS"];
    // 日付の文字列を生成
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    return dateString;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation* location = [locations lastObject];
    //NSLog(@"緯度 %+.6f, 経度 %+.6f\n", location.coordinate.latitude, location.coordinate.longitude);
    _latitude = [NSString stringWithFormat:@"%+.6f", location.coordinate.latitude];
    _longitude = [NSString stringWithFormat:@"%+.6f", location.coordinate.longitude];
}

@end
