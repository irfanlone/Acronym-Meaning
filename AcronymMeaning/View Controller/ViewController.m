//
//  ViewController.m
//  Acronyms
//
//  Created by Irfan Lone on 3/8/16.
//  Copyright © 2016 Ilone Labs. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"
#import "AcronymTableViewCell.h"

static NSInteger kDefaultTableviewRowHeight = 44.0;
NSString * const URLString = @"http://www.nactem.ac.uk/software/acromine/dictionary.py";

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITextField *acronymSearchTextField;
@property (nonatomic, strong) NSMutableArray * results;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = kDefaultTableviewRowHeight;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)getMeaningForAcronym:(NSString*)acronym {
    
    self.results = [NSMutableArray array];
    
    NSDictionary *parameters = @{@"sf": acronym};
    NSURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:URLString parameters:parameters error:nil];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                
        NSArray * responseData = nil;
        if (responseObject) {
            responseData = (NSArray*)responseObject;
        } else {
            // The responseObject comes back nil, Reason:"Content-Type" = "text/plain" instead of "application/json" in the response
            // and AFNetworking treats this as an error, so that's using error.userInfo to get the the response data.
            // The issue has been discussed here https://github.com/AFNetworking/AFNetworking/issues/2410
            NSData *errorData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            responseData = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
        }
        
        if (responseData) {
            self.results = [self processResponseData:responseData];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self.tableView reloadData];
            if ([self.results count] == 0) {
                [self alertUserWithMessage:@"No Results Found"];
            }
        });
    }];
    [dataTask resume];
}

- (IBAction)searchButtonPressed:(id)sender {
    
    if (self.acronymSearchTextField.text.length == 0) {
        [self alertUserWithMessage:@"Enter a value for acronym"];
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSString * acronymValue = self.acronymSearchTextField.text;
    [self getMeaningForAcronym:acronymValue];
}

- (NSMutableArray *)processResponseData:(NSArray*)serializedData {
    
    NSMutableArray * results = [NSMutableArray array];
    NSArray * lfs = [[serializedData valueForKey:@"lfs"] firstObject];
    for (NSDictionary * dict in lfs) {
        NSString * longform = [dict valueForKey:@"lf"];
        [results addObject:longform];
    }
    return results;
}

    - (void)alertUserWithMessage:(NSString*)ALertMessage {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ALertMessage message:@"Please try again" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:ok];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.results.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString * reuseIdentifier = @"tableCell";
    AcronymTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.acronymMeaningLabel.text = self.results[indexPath.row];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

#pragma mark UITableViewDelegate

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
