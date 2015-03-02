//
//  ViewController.m
//  webserviceDemo
//
//  Created by ken on 15-2-28.
//  Copyright (c) 2015年 ken. All rights reserved.
//

#import "ViewController.h"
#import "DemoWebservice.h"

@interface ViewController ()
@property(nonatomic,strong) DemoWebservice *webservice;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSOperation *operation = [self.webservice businessZones:@"广州" complete:^(DemoResponse *response) {
        NSLog(@"%@",response.mapData);
        NSLog(@"%@",response.error);
    }];
    [operation cancel];
}

-(DemoWebservice *)webservice{
    if (!_webservice) {
        _webservice = [DemoWebservice new];
    }
    return _webservice;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
